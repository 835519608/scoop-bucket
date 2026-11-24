$cursorExtraMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/Cursor'; Target = '$persist_dir/roaming' }
    @{ Label = 'profile'; Source = 'UserProfile/.cursor'; Target = '$persist_dir/.cursor' }
)
Uninstall-PersistDataLinks -Mappings $cursorExtraMappings -Log:$true
