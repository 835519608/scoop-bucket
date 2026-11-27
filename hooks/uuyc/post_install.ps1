# NSIS 把服务注册到版本目录；link_current 之后改绑到 current Junction（本机已实测可启动）。
$svcExe = Join-Path $dir 'GameViewer\GameViewerService.exe'
[void](Set-ScoopServiceBinPath -ServiceName 'GameViewerService' -ExecutablePath $svcExe -Arguments '--service' -Start -Log)
