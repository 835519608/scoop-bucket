# scoop-bucket 公共 PowerShell 库（由 bin/hook.ps1 加载）
#
# 对外 API:
#   Install-PersistDataLinks / Uninstall-PersistDataLinks
#   Test-RealPath / Test-RealDirectory / Initialize-VscodePortableData
#   Remove-NsisExtractCrumbs
#   Test-AdminElevation / Assert-AdminElevation / Test-AdminElevationOrWarn
#
# Mapping: Label, Source, Target, EnsureTarget（可选）
# 联接规则统一：源若已是 Junction 则跳过迁移，只重建联接；实目录则先迁入 persist 再联接。
# 各 app 的映射写在 hooks/<app>/persist.ps1（$persistMappings），install/uninstall 共用。

#region 路径判定（跳过已有联接，避免把 persist 再拷回 portable）

function Test-RealPath {
    param ([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    return [bool]($item -and -not $item.LinkType)
}

function Test-RealDirectory {
    param ([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-RealPath -Path $Path)) { return $false }
    return [bool]((Get-Item -LiteralPath $Path -Force).PSIsContainer)
}

#endregion

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
        [string]$TargetPath
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
            Remove-Item -Path $LinkPath -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
    New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath -Force -ErrorAction Stop | Out-Null
}

#endregion

#region NSIS / 7z 解压残渣

function Remove-NsisExtractCrumbs {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return }
    Remove-Item "$Path\`$*", "$Path\Uninst*", "$Path\uninst*" -Force -Recurse -ErrorAction SilentlyContinue
}

#endregion

#region 管理员检查

function Test-AdminElevation {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Assert-AdminElevation {
    param (
        [string]$Reason,
        [string]$InstallHint
    )
    if (Test-AdminElevation) { return }
    $appName = if ($app) { [string]$app } else { 'this app' }
    $hint = if ($InstallHint) { $InstallHint } else { "scoop install $appName" }
    $reasonText = if ($Reason) { $Reason } else { '需要管理员 PowerShell。' }
    Write-Warning @"

${appName} 安装已中止：${reasonText}
请在「以管理员身份运行」的 PowerShell 中执行：
  ${hint}

"@
    throw "${appName}: administrator privileges required."
}

function Test-AdminElevationOrWarn {
    param ([string]$Message)
    if (Test-AdminElevation) { return $true }
    Write-Warning $Message
    return $false
}

#endregion

#region VS Code 系 portable（cursor / codebuddy 等共用）

function Initialize-VscodePortableData {
    param (
        [string]$AppDir,
        [string]$Version,
        [Parameter(Mandatory = $true)]
        [string]$ProfileDir,
        [Parameter(Mandatory = $true)]
        [string]$RoamingAppData,
        [Parameter(Mandatory = $true)]
        [string]$ExtensionsPathPattern
    )
    if (-not $AppDir) { $AppDir = $dir }
    if (-not $Version) { $Version = $version }

    Remove-NsisExtractCrumbs -Path $AppDir

    $dataDir = Join-Path $AppDir 'data'
    $extSrc = Join-Path $ProfileDir 'extensions'
    $extDst = Join-Path $dataDir 'extensions'
    $userDataDst = Join-Path $dataDir 'user-data'
    $argvSrc = Join-Path $ProfileDir 'argv.json'
    $argvDst = Join-Path $dataDir 'argv.json'

    if (!(Test-Path $extDst) -and (Test-RealDirectory -Path $extSrc)) {
        info '[Portable Mode] Copying extensions ...'
        Ensure-FolderExists -Path $dataDir
        Copy-Item $extSrc $dataDir -Recurse -Force
    }
    if (!(Test-Path $userDataDst) -and (Test-RealDirectory -Path $RoamingAppData)) {
        info '[Portable Mode] Copying user data ...'
        Ensure-FolderExists -Path $dataDir
        Copy-Item $RoamingAppData $userDataDst -Recurse -Force
    }

    $extensionsFile = Join-Path $extDst 'extensions.json'
    if (Test-Path $extensionsFile) {
        info 'Adjusting path in extensions.json ...'
        (Get-Content $extensionsFile -Raw) -replace $ExtensionsPathPattern, $Version |
            Set-Content -Path $extensionsFile -NoNewline
    }

    $productPath = Join-Path $AppDir 'resources\app\product.json'
    if (Test-Path $productPath) {
        $productText = [System.IO.File]::ReadAllText($productPath)
        $productPatched = [regex]::Replace($productText, ',\s*\r?\n\s*"target"\s*:\s*"user"(?=\s*\r?\n\})', '')
        if ($productPatched -ne $productText) {
            info '[Portable Mode] Removing "target":"user" from product.json ...'
            [System.IO.File]::WriteAllText($productPath, $productPatched, (New-Object System.Text.UTF8Encoding($false)))
        }
        elseif (($productText | ConvertFrom-Json).PSObject.Properties.Name -contains 'target') {
            warn 'Portable mode may be incomplete: unexpected product.json layout.'
        }
    }

    if (!(Test-Path $argvDst) -and (Test-RealPath -Path $argvSrc) -and (Test-RealDirectory -Path $ProfileDir)) {
        info '[Portable Mode] Copying argv.json ...'
        Ensure-FolderExists -Path $dataDir
        Copy-Item $argvSrc $argvDst -Force
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
    if ($Path -match '^\$persist_dir(?<rest>[/\\].*)?$') {
        $suffix = $matches['rest']
        if ($suffix) {
            $suffix = ($suffix -replace '^[/\\]+', '') -replace '/', '\'
        }
        return (Join-Path $PersistDir $suffix)
    }
    if ($Path -match '^\$dir(?<rest>[/\\].*)?$') {
        $suffix = $matches['rest']
        if ($suffix) {
            $suffix = ($suffix -replace '^[/\\]+', '') -replace '/', '\'
        }
        return (Join-Path $AppDir $suffix)
    }
    return ($ExecutionContext.InvokeCommand.ExpandString($Path))
}

function Ensure-FolderExists {
    param ([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Move-FolderContentsToPersist {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )
    # 已是联接：内容已在 persist，勿再拷
    if (-not (Test-RealDirectory -Path $Source)) { return }
    Ensure-FolderExists -Path $Destination
    Copy-Item -Path "$Source\*" -Destination $Destination -Force -Recurse -ErrorAction SilentlyContinue
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

        if ($Mode -eq 'Uninstall') {
            Remove-DirectoryLink -LinkPath $sourcePath -Log:$Log
            continue
        }

        if ($mapping.EnsureTarget) {
            Ensure-FolderExists -Path $targetPath
        }

        Move-FolderContentsToPersist -Source $sourcePath -Destination $targetPath
        New-DirectoryLink -LinkPath $sourcePath -TargetPath $targetPath
        if ($Log) {
            info "[Persist] $($mapping.Label): $sourcePath -> $targetPath (Junction)"
        }
    }
}

#endregion

#region 数据目录映射（对外）

function Install-PersistDataLinks {
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
