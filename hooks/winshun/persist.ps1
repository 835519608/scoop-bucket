$persistMappings = @(
    @{ Label = 'local'; Source = 'LocalAppData/WinShun'; Target = '$persist_dir/LocalAppData'; EnsureTarget = $true }
)
