# Scoop also runs pre_uninstall on `scoop update`; only real uninstall cleans registrations.
if ($cmd -eq 'uninstall') {
    $exe = Join-Path $dir 'WinShun.exe'
    if ((Test-Path -LiteralPath $exe) -and
        ([version](Get-Item $exe).VersionInfo.FileVersion -gt [version]'0.18.0.0')) {
        $report = Join-Path $env:TEMP 'winshun-cleanup.txt'
        Start-Process $exe -ArgumentList '--uninstall-cleanup' -Wait -WindowStyle Hidden -RedirectStandardOutput $report
        if (Test-Path $report) {
            Get-Content $report -Encoding UTF8 | ForEach-Object { Write-Host $_ }
            Remove-Item $report -Force -ErrorAction SilentlyContinue
        }
    }
}

Get-Process -Name 'WinShun', 'WinShunSearch', 'WinShunUpdate', 'WinShunService', 'WinShunPluginHost', 'WinShunExtract', 'WinShunMcp' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

. (Join-Path $PSScriptRoot 'persist.ps1')
Uninstall-PersistDataLinks -Mappings $persistMappings -Log:$true
