# manifest hook 入口：加载 utils.ps1 并执行 hooks/<app>/<phase>.ps1
# manifest 中一行（仅改末尾路径）:
#   & ((Get-ChildItem (Join-Path $scoopdir 'buckets\*\bin\hook.ps1') -EA SilentlyContinue | Select-Object -First 1).FullName) 'hooks/<app>/post_install.ps1'

param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$HookRelPath
)

. (Join-Path $PSScriptRoot 'utils.ps1')

$hookPath = Join-Path (Split-Path $PSScriptRoot -Parent) ($HookRelPath -replace '/', '\')
if (-not (Test-Path -LiteralPath $hookPath)) {
    # 已安装的旧 manifest 仍可能引用已删除的 hook；升级/卸载时跳过，避免整次操作失败。
    Write-Warning "Hook script not found (skipped): $hookPath"
    return
}
. $hookPath
