if (-not (Test-AdminElevationOrWarn 'uuyc 卸载清理需要管理员权限，已跳过特权清理。')) { return }

$nativeUninstaller = Get-ChildItem "$dir" -Filter 'unins*.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
if ($nativeUninstaller) {
    Start-Process -FilePath $nativeUninstaller.FullName -ArgumentList '/S' -Wait -ErrorAction SilentlyContinue
}

[void](Remove-ScoopService -ServiceName 'GameViewerService' -ProcessNames @('GameViewer', 'UURemote', 'GameViewerService') -Log)

# 只清 GameViewer，勿删整个 HKLM:\SOFTWARE\Netease（会误伤 UU 加速器）
Remove-Item 'HKLM:\SOFTWARE\Netease\GameViewer' -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Get-ScheduledTask -TaskName '*GameViewer*' -ErrorAction SilentlyContinue |
    Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
