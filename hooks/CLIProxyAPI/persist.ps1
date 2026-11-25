$persistMappings = @(
    @{ Label = 'auth'; Source = 'UserProfile/.cli-proxy-api'; Target = '$persist_dir/auth'; EnsureTarget = $true }
)
