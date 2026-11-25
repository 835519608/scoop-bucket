$persistMappings = @(
    @{ Label = 'douyin'; Source = 'AppData/douyin'; Target = '$persist_dir/AppData'; EnsureTarget = $true }
    @{ Label = 'lynx'; Source = 'AppData/douyin_lynx'; Target = '$persist_dir/douyin_lynx'; EnsureTarget = $true }
    @{ Label = 'widget'; Source = 'AppData/douyin_widget'; Target = '$persist_dir/douyin_widget'; EnsureTarget = $true }
)
