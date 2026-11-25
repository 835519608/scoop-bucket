$persistMappings = @(
    @{ Label = 'local'; Source = 'LocalAppData/Steam'; Target = '$persist_dir/LocalAppData'; EnsureTarget = $true }
)
