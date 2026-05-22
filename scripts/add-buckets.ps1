# 根据仓库根目录 buckets.json 添加全部社区 bucket（非 scoop.sh 官方库）。
# WSL: win-pwsh -File scripts/add-buckets.ps1
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [switch]$SkipExisting
)

$ErrorActionPreference = "Stop"
$bucketsFile = Join-Path $RepoRoot "buckets.json"
if (-not (Test-Path $bucketsFile)) {
    throw "缺少 buckets.json，请先运行 scripts/export-from-windows.ps1"
}

$map = Get-Content $bucketsFile -Raw | ConvertFrom-Json
$existing = @{}
scoop bucket list | Select-Object -Skip 2 | ForEach-Object {
    if ($_ -match "^\s*(\S+)\s+") { $existing[$matches[1]] = $true }
}

foreach ($prop in $map.PSObject.Properties) {
    $name = $prop.Name
    $url = [string]$prop.Value
    # buckets.json 仅含社区源，不含 main / extras 等官方库
    if ($SkipExisting -and $existing.ContainsKey($name)) {
        Write-Host "skip (exists): $name"
        continue
    }
    if ($existing.ContainsKey($name)) {
        Write-Host "update: $name"
        scoop bucket update $name
    } else {
        Write-Host "add: $name -> $url"
        scoop bucket add $name $url
    }
}

Write-Host "Done. Current buckets:"
scoop bucket list
