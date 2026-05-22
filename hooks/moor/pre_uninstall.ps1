$moorMappings = @(
    @{ Label = 'data'; Source = 'AppData/com.snowautumn.moor'; Target = '$persist_dir/data' }
    @{ Label = 'local'; Source = 'LocalAppData/com.snowautumn.moor'; Target = '$persist_dir/local' }
)
Uninstall-PersistDataLinks -Mappings $moorMappings -Log:$true
