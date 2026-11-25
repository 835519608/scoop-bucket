. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true

. (Join-Path $PSScriptRoot 'registry.ps1')
Assert-AdminElevation -Reason 'Steam 需写入 HKLM Valve\Steam（InstallPath / Users ACL / SteamService），否则启动会报 registry path not writable。' -InstallHint 'scoop install scoop-bucket/steam'
[void](Set-SteamMachineRegistry -InstallDir $dir)
