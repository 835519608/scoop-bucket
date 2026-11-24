# 去掉自带更新器，改由 scoop update 管理（对齐 sdoog/soup）
Remove-Item "$dir\Updater.exe" -Force -ErrorAction SilentlyContinue

$hbuilderxMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/HBuilder X'; Target = '$persist_dir/roaming'; EnsureTarget = $true }
    @{ Label = 'local'; Source = 'LocalAppData/HBuilder X'; Target = '$persist_dir/local'; EnsureTarget = $true }
)
Install-PersistDataLinks -Mappings $hbuilderxMappings -Log:$true

Clear-DesktopShortcuts -Filter 'HBuilder*.lnk'
Clear-StartMenuShortcuts -Filter 'HBuilder*.lnk'
