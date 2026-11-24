$pixpinMappings = @(
    @{ Label = 'local'; Source = 'LocalAppData/PixPin'; Target = '$persist_dir/LocalAppData' }
)
Uninstall-PersistDataLinks -Mappings $pixpinMappings -Log:$true
