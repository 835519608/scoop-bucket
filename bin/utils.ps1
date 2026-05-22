# scoop-bucket 公共 PowerShell 库（由 bin/import-utils.ps1 加载，manifest 请用 bin/hook.ps1）
#
# 对外 API:
#   Install-PersistDataLinks / Uninstall-PersistDataLinks / Link-FolderToPersist
#   Clear-DesktopShortcuts / Clear-StartMenuShortcuts
#   Disable-LogonStartup
#   Test-AdminElevation / Assert-AdminElevation / Require-AdminElevation / Test-AdminElevationOrWarn
#   Install-AppProcessAutostartBlocker / Uninstall-AppProcessAutostartBlocker
#
# Mapping: Label, Source, Target, EnsureTarget, TargetType；Strategy 可选（copy = 仅复制）

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

function Assert-AdminElevation {
    <#
        Scoop 在 Invoke-Command 中执行 hook，abort/exit 无法中断安装，须用 throw。
        -OnFailure SkipInstall : 中止当前应用安装（manifest pre_install）
        -OnFailure Exit         : 同上，用于 installer 等脚本
    #>
    param (
        [ValidateSet('Exit', 'SkipInstall')]
        [string]$OnFailure = 'Exit',
        [string]$Reason,
        [string]$InstallHint
    )
    if (Test-AdminElevation) { return }
    $appName = if ($app) { [string]$app } else { 'this app' }
    $hint = if ($InstallHint) { $InstallHint } else { "scoop install $appName" }
    $reasonText = if ($Reason) { $Reason } else { '需要管理员 PowerShell。' }
    $message = @"

${appName} 安装已中止：${reasonText}
请在「以管理员身份运行」的 PowerShell 中执行：
  ${hint}

"@
    Write-Warning $message
    throw "${appName}: administrator privileges required."
}

function Require-AdminElevation {
    param (
        [string]$Message = '需要管理员 PowerShell，请在提升的终端中重试。'
    )
    Assert-AdminElevation -OnFailure Exit -Reason $Message
}

function Test-AdminElevationOrWarn {
    param ([string]$Message)
    if (Test-AdminElevation) { return $true }
    Write-Warning $Message
    return $false
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

#region Scoop bucket 路径

function Resolve-ScoopBucketHookPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )
    . (Join-Path $PSScriptRoot 'scoop-path.ps1')
    Resolve-ScoopBucketScriptPath -RelativePath $RelativePath
}

function Get-ScoopBucketUtilsPath {
    if ($PSScriptRoot -and (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'utils.ps1'))) {
        return (Join-Path $PSScriptRoot 'utils.ps1')
    }
    . (Join-Path $PSScriptRoot 'scoop-path.ps1')
    Resolve-ScoopBucketScriptPath -RelativePath 'bin\utils.ps1'
}

#endregion

#region 进程启动监听 + 开机启动（通用）

function Remove-LaunchArtifacts {
    param (
        [string[]]$Names,
        [string]$AppDirectory
    )
    if (-not $AppDirectory) { $AppDirectory = $dir }
    foreach ($name in $Names) {
        Remove-Item -LiteralPath (Join-Path $AppDirectory $name) -Force -ErrorAction SilentlyContinue
    }
}

function Remove-ScheduledTaskByName {
    param ([Parameter(Mandatory = $true)][string]$TaskName)
    schtasks.exe /Delete /TN $TaskName /F 2>$null | Out-Null
}

function Remove-ProcessStartWatcher {
    param (
        [Parameter(Mandatory = $true)][string]$FilterName,
        [Parameter(Mandatory = $true)][string]$ConsumerName
    )
    $ns = 'root\subscription'
    $filter = Get-WmiObject -Namespace $ns -Class __EventFilter -Filter "Name='$FilterName'" -ErrorAction SilentlyContinue
    $consumer = Get-WmiObject -Namespace $ns -Class CommandLineEventConsumer -Filter "Name='$ConsumerName'" -ErrorAction SilentlyContinue
    if ($filter -and $consumer) {
        Get-WmiObject -Namespace $ns -Class __FilterToConsumerBinding -ErrorAction SilentlyContinue |
            Where-Object { $_.Filter -eq $filter.__RELPATH -and $_.Consumer -eq $consumer.__RELPATH } |
            ForEach-Object { $_.Delete() }
        $filter.Delete()
        $consumer.Delete()
    }
}

function Write-ProcessStartBlockerScript {
    param (
        [string]$PersistDirectory,
        [string]$ScriptFileName = 'process-autostart-blocker.ps1',
        [int]$DelaySeconds = 3,
        [Parameter(Mandatory = $true)][string]$AfterLoadCommand
    )
    if (-not $PersistDirectory) { $PersistDirectory = $persist_dir }
    $utilsPath = Get-ScoopBucketUtilsPath
    if (-not $utilsPath) { throw 'utils.ps1 not found in scoop buckets.' }
    New-Item -ItemType Directory -Path $PersistDirectory -Force -ErrorAction SilentlyContinue | Out-Null
    $blockerScript = Join-Path $PersistDirectory $ScriptFileName
    @(
        "Start-Sleep -Seconds $DelaySeconds"
        ". `"$utilsPath`""
        $AfterLoadCommand
    ) | Set-Content -Path $blockerScript -Encoding UTF8
    return $blockerScript
}

function Install-ProcessStartWatcher {
    param (
        [Parameter(Mandatory = $true)][string]$ProcessName,
        [Parameter(Mandatory = $true)][string]$FilterName,
        [Parameter(Mandatory = $true)][string]$ConsumerName,
        [Parameter(Mandatory = $true)][string]$BlockerScriptPath,
        [int]$WithinSeconds = 5
    )
    Remove-ProcessStartWatcher -FilterName $FilterName -ConsumerName $ConsumerName
    $ns = 'root\subscription'
    $escapedProcess = $ProcessName.Replace("'", "''")
    $query = @"
SELECT * FROM __InstanceCreationEvent WITHIN $WithinSeconds
WHERE TargetInstance ISA 'Win32_Process' AND TargetInstance.Name = '$escapedProcess'
"@
    $filter = Set-WmiInstance -Namespace $ns -Class __EventFilter -Arguments @{
        Name           = $FilterName
        EventNameSpace = 'root\cimv2'
        QueryLanguage  = 'WQL'
        Query          = $query
    }
    $consumer = Set-WmiInstance -Namespace $ns -Class CommandLineEventConsumer -Arguments @{
        Name                = $ConsumerName
        CommandLineTemplate = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$BlockerScriptPath`""
    }
    Set-WmiInstance -Namespace $ns -Class __FilterToConsumerBinding -Arguments @{
        Filter   = $filter
        Consumer = $consumer
    } | Out-Null
}

function Install-AppProcessAutostartBlocker {
    param (
        [Parameter(Mandatory = $true)][string]$ProcessName,
        [Parameter(Mandatory = $true)][string]$WatcherFilterName,
        [Parameter(Mandatory = $true)][string]$WatcherConsumerName,
        [string[]]$LogonStartupCommandFilter = @(),
        [string[]]$LogonStartupNameFilter = @(),
        [string]$PersistDirectory,
        [string]$BlockerScriptFileName = 'process-autostart-blocker.ps1',
        [int]$BlockerDelaySeconds = 3,
        [string[]]$RemoveLaunchArtifactNames = @(),
        [string]$LegacyScheduledTaskName,
        [string]$AppDirectory,
        [string]$SuccessMessage
    )
    if (-not $AppDirectory) { $AppDirectory = $dir }
    if (-not (Test-AdminElevation)) {
        throw 'Install-AppProcessAutostartBlocker requires administrator PowerShell.'
    }
    try {
        $cf = ($LogonStartupCommandFilter | ForEach-Object { "'$_'" }) -join ', '
        $nf = ($LogonStartupNameFilter | ForEach-Object { "'$_'" }) -join ', '
        $afterLoad = "Disable-LogonStartup -CommandFilter @($cf) -NameFilter @($nf)"
        $blockerScript = Write-ProcessStartBlockerScript -PersistDirectory $PersistDirectory `
            -ScriptFileName $BlockerScriptFileName -DelaySeconds $BlockerDelaySeconds -AfterLoadCommand $afterLoad
        Install-ProcessStartWatcher -ProcessName $ProcessName -FilterName $WatcherFilterName `
            -ConsumerName $WatcherConsumerName -BlockerScriptPath $blockerScript
        Disable-LogonStartup -CommandFilter $LogonStartupCommandFilter -NameFilter $LogonStartupNameFilter | Out-Null
        if ($LegacyScheduledTaskName) { Remove-ScheduledTaskByName -TaskName $LegacyScheduledTaskName }
        if ($RemoveLaunchArtifactNames.Count -gt 0) {
            Remove-LaunchArtifacts -Names $RemoveLaunchArtifactNames -AppDirectory $AppDirectory
        }
        if ($SuccessMessage) {
            Write-Host $SuccessMessage -ForegroundColor Green
        }
    } catch {
        Write-Warning "注册进程监听失败: $_"
        throw
    }
}

function Uninstall-AppProcessAutostartBlocker {
    param (
        [Parameter(Mandatory = $true)][string]$WatcherFilterName,
        [Parameter(Mandatory = $true)][string]$WatcherConsumerName,
        [string[]]$LogonStartupCommandFilter = @(),
        [string[]]$LogonStartupNameFilter = @(),
        [string[]]$RemoveLaunchArtifactNames = @(),
        [string]$LegacyScheduledTaskName,
        [string]$AppDirectory
    )
    if (-not $AppDirectory) { $AppDirectory = $dir }
    Remove-ProcessStartWatcher -FilterName $WatcherFilterName -ConsumerName $WatcherConsumerName
    if ($LegacyScheduledTaskName) { Remove-ScheduledTaskByName -TaskName $LegacyScheduledTaskName }
    if ($RemoveLaunchArtifactNames.Count -gt 0) {
        Remove-LaunchArtifacts -Names $RemoveLaunchArtifactNames -AppDirectory $AppDirectory
    }
    Disable-LogonStartup -CommandFilter $LogonStartupCommandFilter -NameFilter $LogonStartupNameFilter | Out-Null
}

#endregion
