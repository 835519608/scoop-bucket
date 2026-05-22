# manifest 首行：加载 bin/utils.ps1（勿在 manifest 中重复写 glob 路径）
. (Get-ChildItem -Path (Join-Path $scoopdir 'buckets\*\bin\utils.ps1') -ErrorAction SilentlyContinue |
    Select-Object -First 1).FullName
