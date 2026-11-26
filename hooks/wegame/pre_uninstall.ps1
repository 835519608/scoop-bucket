Get-Process -Name 'wegame', 'WeGame', 'rail_proxy', 'rail_service' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

. (Join-Path $PSScriptRoot 'persist.ps1')
Uninstall-PersistDataLinks -Mappings $persistMappings -Log:$true
