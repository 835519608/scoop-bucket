Get-Process -Name 'steam', 'steamwebhelper', 'steamservice' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

$steamMappings = @(
    @{ Label = 'local'; Source = 'LocalAppData/Steam'; Target = '$persist_dir/LocalAppData' }
)
Uninstall-PersistDataLinks -Mappings $steamMappings -Log:$true
