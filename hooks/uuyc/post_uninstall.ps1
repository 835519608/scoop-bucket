$uuycMappings = @(
    @{ Label = 'local'; Source = 'LocalAppData/GameViewer'; Target = '$persist_dir/AppData' }
    @{ Label = 'programdata'; Source = 'ProgramData/Netease/GameViewer'; Target = '$persist_dir/ProgramData' }
)
Uninstall-PersistDataLinks -Mappings $uuycMappings
if (-not (Test-AdminElevationOrWarn 'uuyc 卸载后清理需要管理员权限，已跳过特权清理。')) { return }
$sidRoots = Get-ChildItem Registry::HKEY_USERS | Where-Object { $_.PSChildName -match '^S-1-5-21-(\d+-){3}\d+$' } | ForEach-Object { $_.PSPath }
foreach ($sid in $sidRoots) {
    Remove-Item "$sid\SOFTWARE\Netease" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
    Remove-Item "$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GameViewer" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
    Remove-ItemProperty "$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name 'GameViewer' -ErrorAction SilentlyContinue
    Remove-ItemProperty "$sid\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store" -Name "$dir\GameViewer\GameViewer.exe" -ErrorAction SilentlyContinue
    Remove-ItemProperty "$sid\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store" -Name 'D:\Apps\Software-NP\Netease\Gameviewer\GameViewer.exe' -ErrorAction SilentlyContinue
    $ua = "$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\UserAssist\{CEBFF5CD-ACE2-4F4F-9178-9926F41749EA}\Count"
    Remove-ItemProperty $ua -Name 'Q:\Nccf\Fbsgjner-AC\Argrnfr\Tnzrivrjre\ova\TnzrIvrjre.rkr' -ErrorAction SilentlyContinue
    Remove-ItemProperty $ua -Name 'Q:\Nccf\Fbsgjner-AC\Argrnfr\Tnzrivrjre\TnzrIvrjre.rkr' -ErrorAction SilentlyContinue
}
Remove-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GameViewer' -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-Item 'HKCU:\Software\Netease\GameViewer' -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'GameViewer' -ErrorAction SilentlyContinue
Write-Host ("`nDeleting $env:LOCALAPPDATA\GameViewer ... ") -f DarkGray -NoNewline
Write-Host ("`nDeleting $env:PROGRAMDATA\Netease\GameViewer ... ") -f DarkGray -NoNewline
Remove-Item "$env:WINDIR\system32\config\systemprofile\AppData\Local\GameViewer" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$env:LOCALAPPDATA\GameViewer" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$env:PROGRAMDATA\Netease\GameViewer" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
