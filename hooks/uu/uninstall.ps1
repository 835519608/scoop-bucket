if (-not (Test-AdminElevationOrWarn 'uu 卸载清理需要管理员权限，已跳过特权清理。')) { return }

Get-Process -Name 'uu', 'uu_launcher', 'uu_ball', 'uu_download', 'uu_cloudsyn', 'uu_agent', 'uu_translate' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

$uninstaller = Join-Path $dir 'uninstall.exe'
if (Test-Path -LiteralPath $uninstaller) {
    Start-Process -FilePath $uninstaller -ArgumentList '/silent' -Wait -ErrorAction SilentlyContinue
}

$uuMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/Netease/UU'; Target = '$persist_dir/AppData' }
    @{ Label = 'local'; Source = 'LocalAppData/Netease/UU'; Target = '$persist_dir/LocalAppData' }
    @{ Label = 'programdata'; Source = 'ProgramData/Netease/UU'; Target = '$persist_dir/ProgramData' }
)
Uninstall-PersistDataLinks -Mappings $uuMappings -Log:$true

Remove-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\NeteaseGacc' -Recurse -Force -ErrorAction SilentlyContinue
Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'NeteaseGacc' -Force -ErrorAction SilentlyContinue
