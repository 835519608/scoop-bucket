Assert-AdminElevation -OnFailure Exit -Reason 'uuyc 安装需要管理员 PowerShell。'
$uuycMappings = @(
    @{ Label = 'local'; Source = 'LocalAppData/GameViewer'; Target = '$persist_dir/AppData'; EnsureTarget = $true }
    @{ Label = 'programdata'; Source = 'ProgramData/Netease/GameViewer'; Target = '$persist_dir/ProgramData'; EnsureTarget = $true }
)
Install-PersistDataLinks -Mappings $uuycMappings
$installer = Get-ChildItem "$dir\*.exe" | Select-Object -First 1
Start-Process -FilePath $installer.FullName -ArgumentList "/S /D=$dir" -Wait
Remove-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GameViewer' -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'GameViewer' -ErrorAction SilentlyContinue
Clear-DesktopShortcuts -Filter '*UU*.lnk'
Clear-StartMenuShortcuts -Filter '*UU*.lnk'
