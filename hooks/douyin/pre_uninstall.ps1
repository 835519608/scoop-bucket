Get-Process -Name 'douyin', 'douyin_guard' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

$douyinMappings = @(
    @{ Label = 'douyin'; Source = 'AppData/douyin'; Target = '$persist_dir/AppData' }
    @{ Label = 'lynx'; Source = 'AppData/douyin_lynx'; Target = '$persist_dir/douyin_lynx' }
    @{ Label = 'widget'; Source = 'AppData/douyin_widget'; Target = '$persist_dir/douyin_widget' }
)
Uninstall-PersistDataLinks -Mappings $douyinMappings -Log:$true
