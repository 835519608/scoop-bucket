# 解析 bucket 内脚本路径：$bucket > install.json > glob（兼容 Scoop v0.5.3 卸载无 $bucket）

function Resolve-ScoopBucketScriptPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )
    $relativePath = $RelativePath -replace '/', '\'
    if ($bucket) {
        $candidate = Join-Path $bucketsdir (Join-Path $bucket $relativePath)
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    if ($app -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
        $appPrefix = scoop prefix $app 2>$null
        if ($appPrefix) {
            $installJson = Join-Path $appPrefix 'install.json'
            if (Test-Path -LiteralPath $installJson) {
                $bucketName = (Get-Content -LiteralPath $installJson -Raw | ConvertFrom-Json).bucket
                if ($bucketName) {
                    $candidate = Join-Path $bucketsdir (Join-Path $bucketName $relativePath)
                    if (Test-Path -LiteralPath $candidate) { return $candidate }
                }
            }
        }
    }
    $hit = Get-ChildItem -Path (Join-Path $scoopdir "buckets\*\$relativePath") -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($hit) { return $hit.FullName }
    throw "scoop-bucket script not found: $RelativePath"
}
