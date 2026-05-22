# 由 bin/hook.ps1 调用：加载 utils.ps1（使用 $PSScriptRoot，不再 glob）
param ([string]$Hook)

. (Join-Path $PSScriptRoot 'utils.ps1')

if ($Hook) {
    $hookPath = Resolve-ScoopBucketHookPath -RelativePath $Hook
    . $hookPath
}
