Stop-ScoopAppProcesses -ProcessNames @('wegame', 'WeGame', 'rail_proxy', 'rail_service')

. (Join-Path $PSScriptRoot 'persist.ps1')
Uninstall-PersistDataLinks -Mappings $persistMappings -Log:$true
