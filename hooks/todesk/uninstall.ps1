# Scoop 不主动装 ToDesk_Service；若用户自行装过，尝试清理。
[void](Remove-ScoopService -ServiceName 'ToDesk_Service' -ProcessNames @(
        'ToDesk', 'todesk-mcp', 'zagent', 'updater', 'CoreToolsMgrHelper', 'CrashReport'
    ) -Log)

. (Join-Path $PSScriptRoot 'persist.ps1')
Uninstall-PersistDataLinks -Mappings $persistMappings -Log:$true
