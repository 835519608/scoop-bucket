$persistMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/Cursor'; Target = '$persist_dir/roaming'; EnsureTarget = $true }
    @{ Label = 'profile'; Source = 'UserProfile/.cursor'; Target = '$persist_dir/.cursor'; EnsureTarget = $true }
)
