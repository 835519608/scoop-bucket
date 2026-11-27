Stop-ScoopAppProcesses -ProcessNames @('DeepSeek Harness', 'DeepSeekHarness')

. (Join-Path $PSScriptRoot 'persist.ps1')
Uninstall-PersistDataLinks -Mappings $persistMappings -Log:$true

Remove-VendorShortcuts -Names @('DeepSeek Harness', 'DeepSeekHarness') -TargetPathContains @('\apps\deepseek-harness\') -Log
