. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true

. (Join-Path $PSScriptRoot 'registry.ps1')
Assert-AdminElevation -Reason 'Steam 需写入 HKLM Valve\Steam（InstallPath / Users ACL / SteamService），否则启动会报 registry path not writable。' -InstallHint 'scoop install scoop-bucket/steam'
[void](Set-SteamMachineRegistry -InstallDir $dir)

# Steam 窗口 AUMID=Valve.Steam.Client；Scoop 默认 .lnk 不带此 ID → 任务栏空白图标。
# post_install 在 create_startmenu_shortcuts 之后，可覆盖写入。
$steamExe = Join-Path $dir 'Steam.exe'
$scoopApps = if ($global) {
    Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\Scoop Apps'
} else {
    Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Scoop Apps'
}
Set-ShortcutAppUserModelId `
    -Path (Join-Path $scoopApps 'Steam.lnk') `
    -AppUserModelId 'Valve.Steam.Client' `
    -TargetPath $steamExe `
    -WorkingDirectory $dir `
    -IconLocation $steamExe `
    -Description 'Steam'
