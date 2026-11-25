Assert-AdminElevation -Reason 'ToDesk 卸载需要管理员 PowerShell（服务）。' -InstallHint 'scoop uninstall todesk'

Get-Process -Name 'ToDesk', 'todesk-mcp', 'zagent', 'updater', 'CoreToolsMgrHelper', 'CrashReport' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

$svc = Get-Service -Name 'ToDesk_Service' -ErrorAction SilentlyContinue
if ($svc) {
    if ($svc.Status -ne 'Stopped') {
        Stop-Service -Name 'ToDesk_Service' -Force -ErrorAction SilentlyContinue
    }
    & sc.exe delete ToDesk_Service 2>$null | Out-Null
    info '[todesk] Removed service ToDesk_Service (if present)'
}

. (Join-Path $PSScriptRoot 'persist.ps1')
Uninstall-PersistDataLinks -Mappings $persistMappings -Log:$true
