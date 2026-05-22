# scoop-bucket 公共 PowerShell 库
#
# 对外 API（manifest 中直接调用）:
#   Install-PersistDataLinks    - 将应用数据目录联接到 persist（安装 / 升级后）
#   Uninstall-PersistDataLinks  - 拆除数据目录联接（卸载前，保留 persist 数据）
#   Link-FolderToPersist        - 单目录联接到 persist（-Migrate 可迁移已有文件）
#   Clear-DesktopShortcuts      - 按通配符删除桌面快捷方式
#   Clear-StartMenuShortcuts    - 按通配符删除开始菜单快捷方式
#   Disable-LogonStartup        - 禁用/删除当前用户开机启动项（Run + StartupApproved）
#   Test-AdminElevation         - 当前是否以管理员运行
#   Require-AdminElevation      - 非管理员则警告并 exit 1
#   Install-McpRouterLaunchArtifacts / Disable-McpRouterLogonStartup / Get-McpRouterPersistMappings
#
# Mapping 字段: Label, Source, Target, EnsureTarget, TargetType；Strategy 可选（copy = 仅复制）
#
# manifest 加载本库（一行）:
#   . (Get-ChildItem (Join-Path $scoopdir 'buckets\*\bin\utils.ps1') -EA SilentlyContinue | Select-Object -First 1).FullName

#region 底层：目录联接

function Remove-DirectoryLink {
    param (
        [Parameter(Mandatory = $true)]
        [string]$LinkPath,
        [switch]$Log
    )
    if (-not (Test-Path $LinkPath)) { return }
    $item = Get-Item -Path $LinkPath -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType) {
        Remove-Item -LiteralPath $LinkPath -Force -ErrorAction SilentlyContinue
        if ($Log) { info "[scoop-bucket] Removed $($item.LinkType): $LinkPath" }
        return
    }
    Remove-Item -Path $LinkPath -Force -Recurse -ErrorAction SilentlyContinue
}

function New-DirectoryLink {
    param (
        [Parameter(Mandatory = $true)]
        [string]$LinkPath,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [switch]$Migrate
    )
    New-Item -Path $TargetPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    if (Test-Path $LinkPath) {
        $existing = Get-Item -Path $LinkPath -Force -ErrorAction SilentlyContinue
        if ($existing.LinkType) {
            try { $existing.Delete() } catch {
                Remove-DirectoryLink -LinkPath $LinkPath
            }
        }
        else {
            if ($Migrate) {
                Get-ChildItem -Path $LinkPath -Force -ErrorAction SilentlyContinue | ForEach-Object {
                    Move-Item -LiteralPath $_.FullName -Destination $TargetPath -Force -ErrorAction SilentlyContinue | Out-Null
                }
            }
            Remove-Item -Path $LinkPath -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
    New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath -Force -ErrorAction Stop | Out-Null
}

#endregion

#region 单目录联接（简写）

function Link-FolderToPersist {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$DataPath,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$PersistPath,
        [switch]$Migrate
    )
    New-DirectoryLink -LinkPath $DataPath -TargetPath $PersistPath -Migrate:$Migrate
}

#endregion

#region 快捷方式清理

function Clear-ShortcutsInFolders {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$SearchPaths,
        [Parameter(Mandatory = $true)]
        [string]$Filter
    )
    foreach ($searchPath in $SearchPaths) {
        Get-ChildItem -Path $searchPath -Filter $Filter -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

function Clear-DesktopShortcuts {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Filter
    )
    Clear-ShortcutsInFolders -SearchPaths @(
        (Join-Path $env:USERPROFILE 'Desktop')
        (Join-Path $env:PUBLIC 'Desktop')
    ) -Filter $Filter
}

function Clear-StartMenuShortcuts {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Filter
    )
    Clear-ShortcutsInFolders -SearchPaths @(
        (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs')
        (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs')
    ) -Filter $Filter
}

#endregion

#region 开机启动（HKCU Run）

function Disable-LogonStartup {
    <#
        禁用匹配的开机启动项（等同任务管理器里关掉「启动」）：
        - 在 StartupApproved\Run 标记为禁用
        - 并删除 HKCU\...\Run 中对应项
        Electron 应用下次运行可能再次写入，需在启动后再次调用或走启动器脚本。
    #>
    param (
        [string[]]$CommandFilter = @(),
        [string[]]$NameFilter = @()
    )
    if ($CommandFilter.Count -eq 0 -and $NameFilter.Count -eq 0) { return @() }
    $runPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    $approvedPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
    $disabledFlag = [byte[]](0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    $matched = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path $runPath)) { return @() }
    if (-not (Test-Path $approvedPath)) {
        New-Item -Path $approvedPath -Force | Out-Null
    }
    $props = Get-ItemProperty -Path $runPath
    foreach ($prop in $props.PSObject.Properties) {
        if ($prop.Name -match '^PS') { continue }
        $hit = $false
        foreach ($nf in $NameFilter) {
            if ($prop.Name -like $nf) { $hit = $true; break }
        }
        if (-not $hit) {
            $command = [string]$prop.Value
            foreach ($cf in $CommandFilter) {
                if ($command -like $cf) { $hit = $true; break }
            }
        }
        if ($hit) {
            Set-ItemProperty -Path $approvedPath -Name $prop.Name -Value $disabledFlag -Type Binary -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $runPath -Name $prop.Name -ErrorAction SilentlyContinue
            $matched.Add($prop.Name)
        }
    }
    return $matched.ToArray()
}

#endregion

#region 管理员检查

function Test-AdminElevation {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Require-AdminElevation {
    param (
        [string]$Message = "`nThis operation requires administrator privileges.`nPlease rerun Scoop in an elevated PowerShell.`n"
    )
    if (-not (Test-AdminElevation)) {
        Write-Warning $Message
        exit 1
    }
}

#endregion

#region 数据目录映射（内部）

function Expand-MappingPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$AppDir,
        [Parameter(Mandatory = $true)]
        [string]$PersistDir
    )
    if ($Path -match '^AppData/(.+)$') {
        return (Join-Path $env:AppData $matches[1])
    }
    if ($Path -match '^LocalAppData/(.+)$') {
        return (Join-Path $env:LocalAppData $matches[1])
    }
    if ($Path -match '^ProgramData/(.+)$') {
        return (Join-Path $env:ProgramData $matches[1])
    }
    if ($Path -match '^UserProfile/(.+)$') {
        return (Join-Path $env:USERPROFILE $matches[1])
    }
    if ($Path -match '^\$dir(?<rest>[/\\].*)?$') {
        $suffix = $matches['rest']
        if ($suffix) {
            $suffix = ($suffix -replace '^[/\\]+', '') -replace '/', '\'
        }
        return (Join-Path $AppDir $suffix)
    }
    if ($Path -match '^\$persist_dir(?<rest>[/\\].*)?$') {
        $suffix = $matches['rest']
        if ($suffix) {
            $suffix = ($suffix -replace '^[/\\]+', '') -replace '/', '\'
        }
        return (Join-Path $PersistDir $suffix)
    }
    return ($ExecutionContext.InvokeCommand.ExpandString($Path))
}

function Ensure-FolderExists {
    param ([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Ensure-FileExists {
    param ([Parameter(Mandatory = $true)][string]$Path)
    $parent = Split-Path -Parent $Path
    if ($parent) { Ensure-FolderExists -Path $parent }
    if (-not (Test-Path $Path)) {
        New-Item -ItemType File -Path $Path -Force | Out-Null
    }
}

function Copy-FolderContents {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )
    if (-not (Test-Path $Source)) { return }
    Ensure-FolderExists -Path $Destination
    Copy-Item -Path "$Source\*" -Destination $Destination -Force -Recurse -ErrorAction SilentlyContinue
}

function Move-FolderContentsToPersist {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )
    if (-not (Test-Path $Source)) { return }
    $item = Get-Item -Path $Source -Force -ErrorAction SilentlyContinue
    if ($item.LinkType) { return }
    Copy-FolderContents -Source $Source -Destination $Destination
    Remove-Item -Path $Source -Force -Recurse -ErrorAction SilentlyContinue
}

function Set-PersistDataLinks {
    param (
        [ValidateSet('Install', 'Uninstall')]
        [Parameter(Mandatory = $true)]
        [string]$Mode,
        [Parameter(Mandatory = $true)]
        [array]$Mappings,
        [Parameter(Mandatory = $true)]
        [string]$AppDir,
        [Parameter(Mandatory = $true)]
        [string]$PersistDir,
        [switch]$Log
    )
    foreach ($mapping in $Mappings) {
        $sourcePath = Expand-MappingPath -Path $mapping.Source -AppDir $AppDir -PersistDir $PersistDir
        $targetPath = Expand-MappingPath -Path $mapping.Target -AppDir $AppDir -PersistDir $PersistDir
        $targetType = if ($mapping.TargetType) { $mapping.TargetType } else { 'directory' }
        $strategy = if ($mapping.Strategy) { $mapping.Strategy.ToLowerInvariant() } else { 'link' }

        if ($Mode -eq 'Uninstall') {
            Remove-DirectoryLink -LinkPath $sourcePath -Log:$Log
            continue
        }

        if ($mapping.EnsureTarget) {
            if ($targetType -eq 'file') { Ensure-FileExists -Path $targetPath }
            else { Ensure-FolderExists -Path $targetPath }
        }

        if ($targetType -ne 'file') {
            Move-FolderContentsToPersist -Source $sourcePath -Destination $targetPath
        }
        elseif ((Test-Path $sourcePath) -and -not (Get-Item $sourcePath -ErrorAction SilentlyContinue).LinkType) {
            Remove-Item -Path $sourcePath -Force -Recurse -ErrorAction SilentlyContinue
        }

        if ($strategy -eq 'copy') {
            Copy-FolderContents -Source $sourcePath -Destination $targetPath
            if ($Log) {
                info "[Persist] $($mapping.Label): $sourcePath -> $targetPath (copy)"
            }
        }
        else {
            New-DirectoryLink -LinkPath $sourcePath -TargetPath $targetPath
            if ($Log) {
                info "[Persist] $($mapping.Label): $sourcePath -> $targetPath (Junction)"
            }
        }
    }
}

#endregion

#region 数据目录映射（对外）

function Install-PersistDataLinks {
    <#
        将 Mapping 中的 Source（如 AppData/foo）目录联接到 persist 下的 Target。
        未传 -AppDir / -PersistDir 时使用 Scoop 脚本变量 $dir、$persist_dir。
    #>
    param (
        [Parameter(Mandatory = $true)]
        [array]$Mappings,
        [string]$AppDir,
        [string]$PersistDir,
        [switch]$Log
    )
    if (-not $AppDir) { $AppDir = $dir }
    if (-not $PersistDir) { $PersistDir = $persist_dir }
    Set-PersistDataLinks -Mode Install -Mappings $Mappings -AppDir $AppDir -PersistDir $PersistDir -Log:$Log
}

function Uninstall-PersistDataLinks {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Mappings,
        [string]$AppDir,
        [string]$PersistDir,
        [switch]$Log
    )
    if (-not $AppDir) { $AppDir = $dir }
    if (-not $PersistDir) { $PersistDir = $persist_dir }
    Set-PersistDataLinks -Mode Uninstall -Mappings $Mappings -AppDir $AppDir -PersistDir $PersistDir -Log:$Log
}

#endregion

#region MCP Router

function Get-McpRouterLogonStartupFilters {
    return @{
        CommandFilter = @('*MCP Router*', '*mcp-router*')
        NameFilter    = @('*MCP Router*', '*mcp-router*')
    }
}

function Disable-McpRouterLogonStartup {
    $filters = Get-McpRouterLogonStartupFilters
    Disable-LogonStartup -CommandFilter $filters.CommandFilter -NameFilter $filters.NameFilter
}

function Get-McpRouterPersistMappings {
    param ([switch]$EnsureTarget)
    $mapping = @{
        Label  = 'roaming'
        Source = 'AppData/MCP Router'
        Target = '$persist_dir/roaming'
    }
    if ($EnsureTarget) { $mapping.EnsureTarget = $true }
    return @($mapping)
}

function Remove-McpRouterLegacyScheduledTask {
    schtasks.exe /Delete /TN scoop-mcp-router-no-autostart /F 2>$null | Out-Null
}

function Install-McpRouterLaunchArtifacts {
    param (
        [string]$AppDirectory,
        [string]$PersistDirectory
    )
    if (-not $AppDirectory) { $AppDirectory = $dir }
    if (-not $PersistDirectory) { $PersistDirectory = $persist_dir }
    $utilsPath = (Get-ChildItem -Path (Join-Path $scoopdir 'buckets\*\bin\utils.ps1') -ErrorAction SilentlyContinue |
        Select-Object -First 1).FullName
    $launchTemplate = (Get-ChildItem -Path (Join-Path $scoopdir 'buckets\*\scripts\mcp-router-launch.ps1') -ErrorAction SilentlyContinue |
        Select-Object -First 1).FullName
    if (-not $utilsPath -or -not $launchTemplate) {
        throw 'MCP Router bucket scripts not found (utils.ps1 / mcp-router-launch.ps1).'
    }
    New-Item -ItemType Directory -Path $PersistDirectory -Force -ErrorAction SilentlyContinue | Out-Null
    $blockerScript = Join-Path $PersistDirectory 'block-autostart.ps1'
    @(
        'Start-Sleep -Seconds 12'
        ". `"$utilsPath`""
        'Disable-McpRouterLogonStartup'
    ) | Set-Content -Path $blockerScript -Encoding UTF8
    $launcherPath = Join-Path $AppDirectory 'mcp-router-launch.ps1'
    (Get-Content -LiteralPath $launchTemplate -Raw).Replace('{{BLOCKER_SCRIPT}}', $blockerScript) |
        Set-Content -LiteralPath $launcherPath -Encoding UTF8
}

#endregion
