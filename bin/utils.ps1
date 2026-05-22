# Shared helpers for scoop-bucket manifests (dot-source: . "$bucketsdir\$bucket\bin\utils.ps1")

#region persist (junction)

function New-PersistDirectory {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$DataPath,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$PersistPath,
        [switch]$Migrate
    )
    New-Item $PersistPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    if (Test-Path $DataPath) {
        $dataPathItem = Get-Item -Path $DataPath
        if ($dataPathItem.LinkType -eq 'Junction') {
            try { $dataPathItem.Delete() } catch {}
        }
        else {
            if ($Migrate) {
                Get-ChildItem $DataPath | ForEach-Object {
                    Move-Item $_.FullName $PersistPath -Force -ErrorAction SilentlyContinue | Out-Null
                }
            }
            Remove-Item $DataPath -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
        }
    }
    New-Item -ItemType Junction -Path $DataPath -Target $PersistPath | Out-Null
}

#endregion

#region shortcuts

function Remove-DesktopShortcuts {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Filter
    )
    @(
        (Join-Path $env:USERPROFILE 'Desktop')
        (Join-Path $env:PUBLIC 'Desktop')
    ) | ForEach-Object {
        Get-ChildItem $_ -Filter $Filter -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

function Remove-StartMenuShortcuts {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Filter
    )
    @(
        (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs')
        (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs')
    ) | ForEach-Object {
        Get-ChildItem $_ -Filter $Filter -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

#endregion

#region scoop admin

function Test-IsAdministrator {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Assert-Administrator {
    param (
        [string]$Message = "`nThis operation requires administrator privileges.`nPlease rerun Scoop in an elevated PowerShell.`n"
    )
    if (-not (Test-IsAdministrator)) {
        Write-Warning $Message
        exit 1
    }
}

#endregion

#region portable profile (AppData / symlink mappings)

function Resolve-PortablePath {
    param (
        [string]$Path,
        [hashtable]$Context
    )
    if ($Path -match '^AppData/(.+)$') {
        return (Join-Path $env:AppData $matches[1])
    }
    elseif ($Path -match '^LocalAppData/(.+)$') {
        return (Join-Path $env:LocalAppData $matches[1])
    }
    elseif ($Path -match '^ProgramData/(.+)$') {
        return (Join-Path $env:ProgramData $matches[1])
    }
    elseif ($Path -match '^UserProfile/(.+)$') {
        return (Join-Path $env:USERPROFILE $matches[1])
    }
    elseif ($Path -match '^\$dir(?<rest>[/\\].*)?$') {
        $suffix = $matches['rest']
        if ($suffix) {
            $suffix = ($suffix -replace '^[/\\]+', '')
            $suffix = $suffix.Replace('/', '\')
        }
        return (Join-Path $Context.Dir $suffix)
    }
    elseif ($Path -match '^\$persist_dir(?<rest>[/\\].*)?$') {
        $suffix = $matches['rest']
        if ($suffix) {
            $suffix = ($suffix -replace '^[/\\]+', '')
            $suffix = $suffix.Replace('/', '\')
        }
        return (Join-Path $Context.PersistDir $suffix)
    }
    else {
        return ($ExecutionContext.InvokeCommand.ExpandString($Path))
    }
}

function Ensure-PortableDirectory {
    param ([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Ensure-PortableFile {
    param ([string]$Path)
    $parent = Split-Path -Parent $Path
    if ($parent) { Ensure-PortableDirectory $parent }
    if (-not (Test-Path $Path)) {
        New-Item -ItemType File -Path $Path -Force | Out-Null
    }
}

function Copy-PortableData {
    param (
        [string]$Source,
        [string]$Destination
    )
    if (Test-Path $Source) {
        Ensure-PortableDirectory $Destination
        Copy-Item "$Source\*" $Destination -Force -Recurse -ErrorAction SilentlyContinue
    }
}

function New-PortableSymlink {
    param (
        [string]$Link,
        [string]$Target
    )
    if (Test-Path $Link) {
        $item = Get-Item $Link -ErrorAction SilentlyContinue
        if ($item -and $item.LinkType -and $item.Target -eq $Target) {
            return
        }
        Remove-Item $Link -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType SymbolicLink -Path $Link -Target $Target -Force | Out-Null
}

function Remove-PortableLink {
    param (
        [string]$Link,
        [switch]$Log
    )
    if (Test-Path $Link) {
        $item = Get-Item $Link -ErrorAction SilentlyContinue
        if ($item -and $item.LinkType) {
            Remove-Item $Link -Force -ErrorAction SilentlyContinue
            if ($Log) {
                info "[Portable Mode] Removed symbolic link: $Link"
            }
        }
    }
}

function Invoke-PortableMappings {
    param (
        [ValidateSet('Install', 'Uninstall')]
        [string]$Action,
        [hashtable]$Context,
        [array]$Mappings,
        [switch]$Log
    )
    foreach ($mapping in $Mappings) {
        $sourcePath = Resolve-PortablePath -Path $mapping.Source -Context $Context
        $targetPath = Resolve-PortablePath -Path $mapping.Target -Context $Context
        $targetType = if ($mapping.TargetType) { $mapping.TargetType } else { 'directory' }
        if ($Action -eq 'Install') {
            if ($mapping.EnsureTarget) {
                if ($targetType -eq 'file') {
                    Ensure-PortableFile $targetPath
                }
                else {
                    Ensure-PortableDirectory $targetPath
                }
            }
            if ($targetType -ne 'file') {
                if ((Test-Path $sourcePath) -and -not (Get-Item $sourcePath -ErrorAction SilentlyContinue).LinkType) {
                    Copy-PortableData -Source $sourcePath -Destination $targetPath
                    Remove-Item $sourcePath -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
            elseif ((Test-Path $sourcePath) -and -not (Get-Item $sourcePath -ErrorAction SilentlyContinue).LinkType) {
                Remove-Item $sourcePath -Recurse -Force -ErrorAction SilentlyContinue
            }
            switch ($mapping.Strategy) {
                'symlink' { New-PortableSymlink -Link $sourcePath -Target $targetPath }
                Default { Copy-PortableData -Source $sourcePath -Destination $targetPath }
            }
            if ($Log) {
                info "[Portable Mode] Linked $($mapping.Label) -> $targetPath"
            }
        }
        else {
            Remove-PortableLink -Link $sourcePath -Log:$Log
        }
    }
}

#endregion
