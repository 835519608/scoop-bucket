# CodeBuddy CN：VS Code portable 初始化 + C 盘目录联接（与 cursor 同一套 utils 逻辑）
Initialize-VscodePortableData `
    -ProfileDir (Join-Path $env:USERPROFILE '.codebuddycn') `
    -RoamingAppData (Join-Path $env:APPDATA 'CodeBuddy CN') `
    -ExtensionsPathPattern '(?<=codebuddycn(/|\\)).*?(?=(/|\\)data(/|\\)extensions)'

# CLI 写 .codebuddy；IDE 默认还会碰 AppData/Local（portable 之外兜底联接）
$codebuddyExtraMappings = @(
    @{ Label = 'profile-cli'; Source = 'UserProfile/.codebuddy'; Target = '$persist_dir/.codebuddy'; EnsureTarget = $true }
    @{ Label = 'roaming'; Source = 'AppData/CodeBuddy CN'; Target = '$persist_dir/roaming'; EnsureTarget = $true }
    @{ Label = 'local'; Source = 'LocalAppData/CodeBuddy CN'; Target = '$persist_dir/local'; EnsureTarget = $true }
)
Install-PersistDataLinks -Mappings $codebuddyExtraMappings -Log:$true

Clear-DesktopShortcuts -Filter 'CodeBuddy*.lnk'
Clear-StartMenuShortcuts -Filter 'CodeBuddy*.lnk'
