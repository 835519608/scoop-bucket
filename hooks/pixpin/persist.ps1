$persistMappings = @(
    @{ Label = 'local'; Source = 'LocalAppData/PixPin'; Target = '$persist_dir/LocalAppData'; EnsureTarget = $true }
)
