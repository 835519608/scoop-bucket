$persistMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/GHelper'; Target = '$persist_dir/data'; EnsureTarget = $true }
)
