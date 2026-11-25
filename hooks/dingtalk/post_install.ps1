# Redirect default C: user-data folders into Scoop persist
. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true

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
