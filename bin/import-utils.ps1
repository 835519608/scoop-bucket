# 由 manifest dot-source；卸载时 $bucket 可能为空，故不依赖 $bucketsdir\$bucket
$binDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path $binDir 'utils.ps1'
if (-not (Test-Path -LiteralPath $utilsPath)) {
    $found = Get-ChildItem -Path (Join-Path $scoopdir 'buckets\*\bin\utils.ps1') -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $found) {
        throw "scoop-bucket utils.ps1 not found under $(Join-Path $scoopdir 'buckets')"
    }
    $utilsPath = $found.FullName
}
. $utilsPath
