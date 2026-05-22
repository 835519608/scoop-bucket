# manifest 统一入口：加载 utils 并执行 hooks/<app>/<phase>.ps1
# 用法（manifest 中一行，勿再写 import-utils 的 glob）:
#   & ((Get-ChildItem (Join-Path $scoopdir 'buckets\*\bin\hook.ps1') -EA SilentlyContinue | Select-Object -First 1).FullName) 'hooks/mcp-router/pre_install.ps1'

param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$HookRelPath
)

. (Join-Path $PSScriptRoot 'scoop-path.ps1')
$importUtils = Resolve-ScoopBucketScriptPath -RelativePath 'bin\import-utils.ps1'
& $importUtils -Hook $HookRelPath
