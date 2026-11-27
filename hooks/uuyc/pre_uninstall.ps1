# update 只停不删；删服务在 uninstall.ps1。
[void](Stop-ScoopService -ServiceName 'GameViewerService' -ProcessNames @('GameViewer', 'UURemote', 'GameViewerService'))
