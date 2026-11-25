Assert-AdminElevation -Reason 'uuyc 安装需要管理员 PowerShell。'
. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings
$installer = Get-ChildItem "$dir\*.exe" | Select-Object -First 1
# NSIS：/NS 安装时不写桌面/开始菜单快捷方式，图标只走 Scoop shortcuts
Start-Process -FilePath $installer.FullName -ArgumentList "/S /NS /D=$dir" -Wait
Remove-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GameViewer' -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'GameViewer' -ErrorAction SilentlyContinue
