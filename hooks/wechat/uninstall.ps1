Get-Process -Name 'Weixin', 'WeChat', 'WeChatAppEx', 'WeChatOCR' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

. (Join-Path $PSScriptRoot 'persist.ps1')
Uninstall-PersistDataLinks -Mappings $persistMappings -Log:$true

Remove-Item -Path (Join-Path $env:APPDATA 'Tencent\xwechat\config\51a1fffea11325a1e4104c6b3de47af7.ini') -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKCU:\Software\Tencent\Weixin' -Name 'FileSavePath' -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKCU:\Software\Tencent\Weixin' -Name 'InstallPath' -Force -ErrorAction SilentlyContinue
