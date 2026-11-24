$workbuddyCnMappings = @(
    @{ Label = 'profile'; Source = 'UserProfile/.workbuddy'; Target = '$persist_dir/.workbuddy' }
    @{ Label = 'roaming'; Source = 'AppData/WorkBuddy'; Target = '$persist_dir/AppData' }
)
Uninstall-PersistDataLinks -Mappings $workbuddyCnMappings
