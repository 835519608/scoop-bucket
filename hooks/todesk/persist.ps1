$persistMappings = @(
    @{ Label = 'local'; Source = 'LocalAppData/ToDesk'; Target = '$persist_dir/LocalAppData'; EnsureTarget = $true }
)
