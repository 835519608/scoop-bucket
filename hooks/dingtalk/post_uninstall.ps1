# 仅清理协议/App Paths；persist 数据默认保留（scoop uninstall -p 才会删 persist）
$registryScope = if ($global) { 'HKLM' } else { 'HKCU' }
reg.exe delete "$registryScope\SOFTWARE\Classes\dingtalk" /f 2>$null | Out-Null
reg.exe delete "$registryScope\SOFTWARE\Classes\dingtalkscheme" /f 2>$null | Out-Null
reg.exe delete "$registryScope\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\DingTalk.exe" /f 2>$null | Out-Null
if ($cmd -eq 'uninstall') {
    reg.exe delete 'HKCU\SOFTWARE\DingTalk' /f 2>$null | Out-Null
}
