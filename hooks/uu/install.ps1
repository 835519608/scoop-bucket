Assert-AdminElevation -Reason 'uu（UU加速器）安装需要管理员 PowerShell（驱动 / WFP）。' -InstallHint 'scoop install scoop-bucket/uu'

$uuMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/Netease/UU'; Target = '$persist_dir/AppData'; EnsureTarget = $true }
    @{ Label = 'local'; Source = 'LocalAppData/Netease/UU'; Target = '$persist_dir/LocalAppData'; EnsureTarget = $true }
    @{ Label = 'programdata'; Source = 'ProgramData/Netease/UU'; Target = '$persist_dir/ProgramData'; EnsureTarget = $true }
)
Install-PersistDataLinks -Mappings $uuMappings -Log:$true

$installer = Get-ChildItem "$dir\*.exe" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^UU-|^uu' -or $_.Name -eq 'dl.exe' -or $_.Length -gt 1MB } |
    Select-Object -First 1
if (-not $installer) {
    $installer = Get-ChildItem "$dir\*" -File | Sort-Object Length -Descending | Select-Object -First 1
}
if (-not $installer) { throw 'uu: installer not found in $dir' }

Start-Process -FilePath $installer.FullName -ArgumentList "/silent /install_path `"$dir`"" -Wait

# Drop leftover setup payload if installer left a copy beside the app tree
Get-ChildItem "$dir\UU-*.exe" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'NeteaseGacc' -Force -ErrorAction SilentlyContinue

# Avoid matching「UU远程」(uuyc)
Clear-DesktopShortcuts -Filter 'UU加速器*.lnk'
Clear-DesktopShortcuts -Filter '网易UU加速器*.lnk'
Clear-StartMenuShortcuts -Filter 'UU加速器*.lnk'
Clear-StartMenuShortcuts -Filter '网易UU加速器*.lnk'
Get-ChildItem -Path @(
    (Join-Path $env:USERPROFILE 'Desktop')
    (Join-Path $env:PUBLIC 'Desktop')
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs')
    (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs')
) -Filter '*.lnk' -Recurse -ErrorAction SilentlyContinue |
    Where-Object {
        $_.BaseName -match 'UU加速器|网易UU加速器' -and
        $_.BaseName -notmatch '远程' -and
        $_.DirectoryName -notmatch '\\Scoop Apps$'
    } |
    Remove-Item -Force -ErrorAction SilentlyContinue
