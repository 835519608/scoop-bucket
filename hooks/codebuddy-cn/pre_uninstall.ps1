$codebuddyExtraMappings = @(
    @{ Label = 'profile-cli'; Source = 'UserProfile/.codebuddy'; Target = '$persist_dir/.codebuddy' }
    @{ Label = 'roaming'; Source = 'AppData/CodeBuddy CN'; Target = '$persist_dir/roaming' }
    @{ Label = 'local'; Source = 'LocalAppData/CodeBuddy CN'; Target = '$persist_dir/local' }
)
Uninstall-PersistDataLinks -Mappings $codebuddyExtraMappings -Log:$true
Clear-DesktopShortcuts -Filter 'CodeBuddy*.lnk'
Clear-StartMenuShortcuts -Filter 'CodeBuddy*.lnk'
