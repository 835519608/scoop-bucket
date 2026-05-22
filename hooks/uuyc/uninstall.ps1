if (-not (Test-AdminElevationOrWarn 'uuyc 卸载清理需要管理员权限，已跳过特权清理。')) { return }
$nativeUninstaller = Get-ChildItem "$dir" -Filter 'unins*.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
if ($nativeUninstaller) {
    Start-Process -FilePath $nativeUninstaller.FullName -ArgumentList '/S' -Wait -ErrorAction SilentlyContinue
}
Remove-Item 'HKLM:\SYSTEM\CurrentControlSet\Services\GameViewerService' -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-Item 'HKLM:\SOFTWARE\Netease' -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Get-ScheduledTask -TaskName '*GameViewer*' -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
Get-ScheduledTask -TaskName '*UU*' -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
