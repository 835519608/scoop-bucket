# 由 pre_install 写入应用目录（须在 create_shims 之前）；启动 MCP Router 并延迟禁用开机启动
$AppDir = $PSScriptRoot
$ExePath = Join-Path $AppDir 'MCP Router.exe'
if (-not (Test-Path -LiteralPath $ExePath)) {
    Write-Error "MCP Router.exe not found: $ExePath"
    exit 1
}
Start-Process -FilePath $ExePath -WorkingDirectory $AppDir
$blocker = '{{BLOCKER_SCRIPT}}'
if (Test-Path -LiteralPath $blocker) {
    Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @(
        '-NoProfile', '-WindowStyle', 'Hidden', '-ExecutionPolicy', 'Bypass',
        '-File', $blocker
    ) | Out-Null
}
