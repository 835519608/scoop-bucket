$persistMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/HBuilder X'; Target = '$persist_dir/roaming'; EnsureTarget = $true }
    @{ Label = 'local'; Source = 'LocalAppData/HBuilder X'; Target = '$persist_dir/local'; EnsureTarget = $true }
)
