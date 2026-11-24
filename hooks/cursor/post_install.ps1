# Cursor / cursor327：共用 VS Code portable 初始化 + C 盘目录联接
Initialize-VscodePortableData `
    -ProfileDir (Join-Path $env:USERPROFILE '.cursor') `
    -RoamingAppData (Join-Path $env:APPDATA 'Cursor') `
    -ExtensionsPathPattern '(?<=cursor(/|\\)).*?(?=(/|\\)data(/|\\)extensions)'

$cursorExtraMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/Cursor'; Target = '$persist_dir/roaming'; EnsureTarget = $true }
    @{ Label = 'profile'; Source = 'UserProfile/.cursor'; Target = '$persist_dir/.cursor'; EnsureTarget = $true }
)
Install-PersistDataLinks -Mappings $cursorExtraMappings -Log:$true

Clear-DesktopShortcuts -Filter 'Cursor*.lnk'
Clear-StartMenuShortcuts -Filter 'Cursor*.lnk'
