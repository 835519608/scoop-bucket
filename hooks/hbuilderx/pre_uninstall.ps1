$hbuilderxMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/HBuilder X'; Target = '$persist_dir/roaming' }
    @{ Label = 'local'; Source = 'LocalAppData/HBuilder X'; Target = '$persist_dir/local' }
)
Uninstall-PersistDataLinks -Mappings $hbuilderxMappings -Log:$true
