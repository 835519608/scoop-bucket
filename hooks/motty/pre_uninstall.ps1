$mottyMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/motty'; Target = '$persist_dir/roaming' }
)
Uninstall-PersistDataLinks -Mappings $mottyMappings
