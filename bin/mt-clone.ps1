# Clone MetaTrader Scoop template into a self-contained multi-account instance.
# Usage:
#   & "$env:SCOOP\buckets\scoop-bucket\bin\mt-clone.ps1" -App metatrader5 -Name acc2
#   & "$env:SCOOP\buckets\scoop-bucket\bin\mt-clone.ps1" -App metatrader5 -SyncBinaries

param (
    [Parameter(Mandatory = $true)]
    [ValidateSet('metatrader4', 'metatrader5')]
    [string]$App,

    [string]$Name,

    [switch]$SyncBinaries,

    [switch]$EmptyData
)

$ErrorActionPreference = 'Stop'

if (-not $env:SCOOP) { throw 'SCOOP env not set' }
if ($SyncBinaries -and $Name) { throw 'Use either -Name or -SyncBinaries, not both' }
if (-not $SyncBinaries -and -not $Name) { throw 'Specify -Name <instance> or -SyncBinaries' }

$isMt5 = ($App -eq 'metatrader5')
$exeName = if ($isMt5) { 'terminal64.exe' } else { 'terminal.exe' }
$dataDirs = if ($isMt5) {
    @('Bases', 'Config', 'logs', 'Logs', 'MQL5', 'Profiles', 'Tester', 'llm-agent')
} else {
    @('config', 'history', 'logs', 'MQL4', 'profiles', 'templates', 'tester')
}

$appDir = Join-Path $env:SCOOP "apps\$App\current"
$persist = Join-Path $env:SCOOP "persist\$App"
$instRoot = Join-Path $env:SCOOP "persist\$App-instances"

if (-not (Test-Path -LiteralPath (Join-Path $appDir $exeName))) {
    throw "Template missing $exeName under $appDir — install scoop-bucket/$App first"
}

function Stop-MtProcesses {
    $names = @('terminal64', 'metaeditor64', 'metatester64', 'terminal', 'metaeditor')
    Get-Process -Name $names -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

function Sync-BinariesTo {
    param ([Parameter(Mandatory = $true)][string]$Dest)

    New-Item -ItemType Directory -Path $Dest -Force | Out-Null
    # Copy program files; /XJ skips junctions (Scoop persist links under $appDir)
    $rcArgs = @($appDir, $Dest, '/E', '/XJ', '/XF', 'uninstall.exe', '/XD') + $dataDirs + @(
        '/NFL', '/NDL', '/NJH', '/NJS', '/nc', '/ns', '/np'
    )
    & robocopy @rcArgs | Out-Null
    $code = $LASTEXITCODE
    if ($code -ge 8) { throw "robocopy binaries failed with code $code" }

    # Drop any persist-named junctions/dirs that slipped through
    foreach ($name in $dataDirs) {
        $p = Join-Path $Dest $name
        if (-not (Test-Path -LiteralPath $p)) { continue }
        $item = Get-Item -LiteralPath $p -Force
        if ($item.LinkType) {
            $item.Delete()
        }
    }
}

function Copy-TemplateData {
    param ([Parameter(Mandatory = $true)][string]$Dest)

    if ($EmptyData) { return }
    if (-not (Test-Path -LiteralPath $persist)) { return }

    foreach ($name in $dataDirs) {
        $src = Join-Path $persist $name
        if (-not (Test-Path -LiteralPath $src)) { continue }
        $dst = Join-Path $Dest $name
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
        & robocopy $src $dst /E /XO /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    }
}

function Write-InstanceShortcut {
    param (
        [Parameter(Mandatory = $true)][string]$Dest,
        [Parameter(Mandatory = $true)][string]$InstanceName
    )

    $programs = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
    New-Item -ItemType Directory -Path $programs -Force | Out-Null
    $label = if ($isMt5) { "MetaTrader 5 ($InstanceName)" } else { "MetaTrader 4 ($InstanceName)" }
    $lnkPath = Join-Path $programs "$label.lnk"
    $exe = Join-Path $Dest $exeName
    $w = New-Object -ComObject WScript.Shell
    $lnk = $w.CreateShortcut($lnkPath)
    $lnk.TargetPath = $exe
    $lnk.Arguments = '/portable'
    $lnk.WorkingDirectory = $Dest
    $lnk.IconLocation = "$exe,0"
    $lnk.Description = $label
    $lnk.Save()
    Write-Host "Shortcut: $lnkPath"
}

if ($SyncBinaries) {
    if (-not (Test-Path -LiteralPath $instRoot)) {
        Write-Host "No instances under $instRoot"
        return
    }
    Stop-MtProcesses
    Get-ChildItem $instRoot -Directory | ForEach-Object {
        Write-Host "SyncBinaries → $($_.FullName)"
        Sync-BinariesTo -Dest $_.FullName
    }
    Write-Host 'Done. Instance data dirs were not modified.'
    return
}

# Sanitize instance name
if ($Name -notmatch '^[A-Za-z0-9_-]+$') {
    throw 'Instance -Name must be alphanumeric / _ / - only'
}

$dest = Join-Path $instRoot $Name
if (Test-Path -LiteralPath $dest) {
    throw "Instance already exists: $dest"
}

Stop-MtProcesses
New-Item -ItemType Directory -Path $instRoot -Force | Out-Null
Write-Host "Cloning $App → $dest"
Sync-BinariesTo -Dest $dest
Copy-TemplateData -Dest $dest
Write-InstanceShortcut -Dest $dest -InstanceName $Name
Write-Host "Launch via the new Start Menu shortcut (/portable)."