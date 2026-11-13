$workbuddyCnMappings = @(
    @{ Label = 'profile'; Source = 'UserProfile/.workbuddy'; Target = '$persist_dir/.workbuddy' }
)
Uninstall-PersistDataLinks -Mappings $workbuddyCnMappings
