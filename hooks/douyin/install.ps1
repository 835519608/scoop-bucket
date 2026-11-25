# Douyin PC: unpack app.7z + redirect Electron user-data folders into persist
$douyinMappings = @(
    @{ Label = 'douyin'; Source = 'AppData/douyin'; Target = '$persist_dir/AppData'; EnsureTarget = $true }
    @{ Label = 'lynx'; Source = 'AppData/douyin_lynx'; Target = '$persist_dir/douyin_lynx'; EnsureTarget = $true }
    @{ Label = 'widget'; Source = 'AppData/douyin_widget'; Target = '$persist_dir/douyin_widget'; EnsureTarget = $true }
)
Install-PersistDataLinks -Mappings $douyinMappings -Log:$true

# Outer NSIS crumbs from #/dl.7z land in $dir; app payload is app.7z
Remove-Item "$dir\`$*", "$dir\uninst*" -Force -Recurse -ErrorAction SilentlyContinue

$verDir = Join-Path $dir $version
Expand-7zipArchive "$dir\app.7z" $verDir -Removal
Remove-Item "$verDir\app.7z", "$verDir\`$*", "$verDir\uninst*", "$verDir\resources\app-update.yml",
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

Clear-DesktopShortcuts -Filter '*抖音*.lnk'
Clear-DesktopShortcuts -Filter 'douyin*.lnk'
Clear-StartMenuShortcuts -Filter '*抖音*.lnk'
Clear-StartMenuShortcuts -Filter 'douyin*.lnk'
