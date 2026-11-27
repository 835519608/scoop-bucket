. (Join-Path $PSScriptRoot 'persist.ps1')
Uninstall-PersistDataLinks -Mappings $persistMappings

if (-not (Test-AdminElevationOrWarn 'uuyc 卸载后清理需要管理员权限，已跳过特权清理。')) { return }

Remove-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GameViewer' -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-Item 'HKCU:\Software\Netease\GameViewer' -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'GameViewer' -ErrorAction SilentlyContinue

# 联接已卸；若仍残留实目录再删（勿动 persist 目标）
foreach ($p in @(
        (Join-Path $env:LOCALAPPDATA 'GameViewer')
        (Join-Path $env:PROGRAMDATA 'Netease\GameViewer')
        (Join-Path $env:WINDIR 'system32\config\systemprofile\AppData\Local\GameViewer')
    )) {
    if (Test-RealDirectory -Path $p) {
        Remove-Item -LiteralPath $p -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
    }
}
