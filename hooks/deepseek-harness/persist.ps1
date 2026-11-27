$persistMappings = @(
    @{ Label = 'dsh-home'; Source = 'UserProfile/.dsh'; Target = '$persist_dir/dsh-home'; EnsureTarget = $true }
)
