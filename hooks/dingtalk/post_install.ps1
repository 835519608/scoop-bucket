# Redirect default C: user-data folders into Scoop persist
$dingtalkMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/DingTalk'; Target = '$persist_dir/AppData'; EnsureTarget = $true }
    @{ Label = 'dinglive'; Source = 'AppData/dinglive'; Target = '$persist_dir/dinglive'; EnsureTarget = $true }
    @{ Label = 'local91'; Source = 'LocalAppData/DingTalk_91'; Target = '$persist_dir/DingTalk_91'; EnsureTarget = $true }
    @{ Label = 'local108'; Source = 'LocalAppData/DingTalk_108'; Target = '$persist_dir/DingTalk_108'; EnsureTarget = $true }
    @{ Label = 'local133'; Source = 'LocalAppData/DingTalk_133'; Target = '$persist_dir/DingTalk_133'; EnsureTarget = $true }
)
Install-PersistDataLinks -Mappings $dingtalkMappings -Log:$true

# URL Protocol / App Paths for dingtalk://
$registryScope = if ($global) { 'HKEY_LOCAL_MACHINE' } else { 'HKEY_CURRENT_USER' }
$schemeReg = (Join-Path $dir 'DingtalkScheme.exe').Replace('\', '\\')
$launcherReg = (Join-Path $dir 'DingTalkLauncher.exe').Replace('\', '\\')
$dirReg = $dir.Replace('\', '\\')
$regFile = Join-Path $dir 'install-dingtalk.reg'
@"
Windows Registry Editor Version 5.00
[$registryScope\SOFTWARE\Classes\dingtalk]
"URL Protocol"=""
[$registryScope\SOFTWARE\Classes\dingtalk\Shell\Open\Command]
@="\"$schemeReg\" %1"
[$registryScope\SOFTWARE\Classes\dingtalkscheme]
"URL Protocol"=""
[$registryScope\SOFTWARE\Classes\dingtalkscheme\Shell\Open\Command]
@="\"$schemeReg\" %1"
[$registryScope\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\DingTalk.exe]
@="$launcherReg"
"path"="$dirReg"
[HKEY_CURRENT_USER\SOFTWARE\DingTalk\Package]
"auto_start"=dword:00000000
[HKEY_CURRENT_USER\SOFTWARE\DingTalk\Scheme]
"DingTalk"="$schemeReg"
"@ | Set-Content -Path $regFile -Encoding Unicode
reg.exe import $regFile 2>$null | Out-Null

# Keep only Scoop Start Menu shortcut; strip installer/desktop duplicates
Clear-DesktopShortcuts -Filter 'DingTalk*.lnk'
Clear-DesktopShortcuts -Filter '*DingDing*.lnk'
Clear-StartMenuShortcuts -Filter 'DingTalk*.lnk'
Get-ChildItem -Path @(
    (Join-Path $env:USERPROFILE 'Desktop')
    (Join-Path $env:PUBLIC 'Desktop')
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs')
    (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs')
) -Filter '*.lnk' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.BaseName -match '钉钉|DingTalk|DingDing' -and $_.DirectoryName -notmatch '\\Scoop Apps$' } |
    Remove-Item -Force -ErrorAction SilentlyContinue
