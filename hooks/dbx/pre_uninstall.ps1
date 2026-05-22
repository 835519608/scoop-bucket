$dbxMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/com.dbx.app'; Target = '$persist_dir/roaming' }
    @{ Label = 'local'; Source = 'LocalAppData/com.dbx.app'; Target = '$persist_dir/local' }
    @{ Label = 'profile'; Source = 'UserProfile/.dbx'; Target = '$persist_dir/.dbx' }
)
Uninstall-PersistDataLinks -Mappings $dbxMappings
