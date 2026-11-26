$persistMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/Tencent/WeGame'; Target = '$persist_dir/AppData'; EnsureTarget = $true }
)
