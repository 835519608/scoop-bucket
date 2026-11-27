Stop-ScoopAppProcesses -ProcessNames @('steam', 'steamwebhelper', 'steamservice')

. (Join-Path $PSScriptRoot 'persist.ps1')
Uninstall-PersistDataLinks -Mappings $persistMappings -Log:$true
