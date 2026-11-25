Get-Process -Name 'DingTalk*', 'DingTalkLauncher', 'DingtalkScheme', 'DingTalkApp' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

. (Join-Path $PSScriptRoot 'persist.ps1')
Uninstall-PersistDataLinks -Mappings $persistMappings -Log:$true
