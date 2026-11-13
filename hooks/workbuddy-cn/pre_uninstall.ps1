$workbuddyCnMappings = @(
    @{ Label = 'profile'; Source = 'UserProfile/.workbuddy'; Target = '$persist_dir/.workbuddy' }
    @{ Label = 'codebuddy'; Source = 'UserProfile/.codebuddy'; Target = '$persist_dir/.codebuddy' }
    @{ Label = 'extension'; Source = 'LocalAppData/CodeBuddyExtension'; Target = '$persist_dir/CodeBuddyExtension' }
)
Uninstall-PersistDataLinks -Mappings $workbuddyCnMappings
