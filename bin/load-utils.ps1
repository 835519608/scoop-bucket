# manifest 统一入口：解析 bucket 后加载 utils.ps1
# 优先级: $bucket（安装时）> install.json（卸载时 v0.5.3 等）> 搜索 buckets\*\bin\utils.ps1
#
# manifest 中一行加载:
#   . (Get-ChildItem (Join-Path $scoopdir 'buckets\*\bin\load-utils.ps1') -EA SilentlyContinue | Select-Object -First 1).FullName

function Resolve-ScoopBucketName {
    if ($bucket) {
        return [string]$bucket
    }
    if ($app -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
        $appPrefix = scoop prefix $app 2>$null
        if ($appPrefix) {
            $installJson = Join-Path $appPrefix 'install.json'
            if (Test-Path -LiteralPath $installJson) {
                $name = (Get-Content -LiteralPath $installJson -Raw | ConvertFrom-Json).bucket
                if ($name) { return [string]$name }
            }
        }
    }
    $hit = Get-ChildItem -Path (Join-Path $scoopdir 'buckets\*\bin\utils.ps1') -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($hit) {
        return $hit.Directory.Parent.Name
    }
    throw "Cannot resolve scoop bucket name. Check install.json or `$bucket."
}

$bucketName = Resolve-ScoopBucketName
$utilsPath = Join-Path $bucketsdir "$bucketName\bin\utils.ps1"
if (-not (Test-Path -LiteralPath $utilsPath)) {
    throw "utils.ps1 not found: $utilsPath"
}
. $utilsPath
