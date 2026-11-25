Assert-AdminElevation -Reason 'uu（UU加速器）安装需要管理员 PowerShell（驱动 / WFP）。' -InstallHint 'scoop install scoop-bucket/uu'

. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true

$installer = Get-ChildItem "$dir\*.exe" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^UU-|^uu' -or $_.Name -eq 'dl.exe' -or $_.Length -gt 1MB } |
    Select-Object -First 1
if (-not $installer) {
    $installer = Get-ChildItem "$dir\*" -File | Sort-Object Length -Descending | Select-Object -First 1
}
if (-not $installer) { throw 'uu: installer not found in $dir' }

# DuiLib 静默参数：install_createshortcut/install_autorun 取 0，避免先建后删；图标只走 Scoop shortcuts
Start-Process -FilePath $installer.FullName -ArgumentList @(
    '/silent'
    "/install_path `"$dir`""
    '/install_createshortcut'
    '0'
    '/install_autorun'
    '0'
    '/no_launch_uu'
) -Wait

# Drop leftover setup payload if installer left a copy beside the app tree
Get-ChildItem "$dir\UU-*.exe" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'NeteaseGacc' -Force -ErrorAction SilentlyContinue
