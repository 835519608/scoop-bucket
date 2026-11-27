# NSIS /NS 对网易安装器不可靠，仍会写开始菜单「UU远程.lnk」；装完后清掉非 Scoop Apps 入口。
Remove-VendorShortcuts -Names @('UU远程', 'UU Remote', 'GameViewer') -TargetPathContains @('\apps\uuyc\') -Log

# NSIS 把服务注册到版本目录；link_current 之后改绑到 current Junction（本机已实测可启动）。
$svcExe = Join-Path $dir 'GameViewer\GameViewerService.exe'
[void](Set-ScoopServiceBinPath -ServiceName 'GameViewerService' -ExecutablePath $svcExe -Arguments '--service' -Start -Log)
