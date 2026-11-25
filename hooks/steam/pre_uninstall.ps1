Get-Process -Name 'steam', 'steamwebhelper', 'steamservice' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

. (Join-Path $PSScriptRoot 'persist.ps1')
Uninstall-PersistDataLinks -Mappings $persistMappings -Log:$true
