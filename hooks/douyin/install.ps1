# Douyin PC: unpack app.7z + redirect Electron user-data folders into persist
. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true

# Outer NSIS crumbs from #/dl.7z land in $dir; app payload is app.7z
Remove-NsisExtractCrumbs -Path $dir

$verDir = Join-Path $dir $version
Expand-7zipArchive "$dir\app.7z" $verDir -Removal
Remove-NsisExtractCrumbs -Path $verDir
Remove-Item "$verDir\app.7z", "$verDir\resources\app-update.yml",
    "$verDir\installer_downloader*", "$verDir\app_shell_updater*", "$verDir\tray" -Force -Recurse -ErrorAction SilentlyContinue

# Drop previous version folders left by older Scoop installs (e.g. 8.7.0 after → 8.8.0)
Get-ChildItem -Path $dir -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^\d+(\.\d+)+$' -and $_.Name -ne $version } |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

$backup = Join-Path $verDir 'douyin.backup'
if (Test-Path -LiteralPath $backup) {
    Copy-Item $backup (Join-Path $dir 'douyin.exe') -Force
}
elseif (Test-Path (Join-Path $verDir 'douyin.exe')) {
    Copy-Item (Join-Path $verDir 'douyin.exe') (Join-Path $dir 'douyin.exe') -Force
}
