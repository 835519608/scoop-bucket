# 在 WSL 中通过 win-pwsh 调用，或于 Windows PowerShell 直接运行。
# 从 Windows 宿主机 Scoop 导出非 main bucket 源与本机已安装的非 main 应用列表。
param(
    [string]$ScoopRoot = "D:\Program\Scoop",
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ScoopRoot)) {
    throw "Scoop 根目录不存在: $ScoopRoot"
}

$bucketsDir = Join-Path $ScoopRoot "buckets"
$appsDir = Join-Path $ScoopRoot "apps"

# 收集 bucket 源（排除 main、本仓库自身、已弃用的 symm 独立 bucket）
$skipBuckets = @("main", "scoop-bucket", "symm")
$buckets = @{}
Get-ChildItem $bucketsDir -Directory | ForEach-Object {
    $name = $_.Name
    if ($name -in $skipBuckets) { return }
    $url = ""
    if (Test-Path (Join-Path $_.FullName ".git")) {
        $url = git -C $_.FullName remote get-url origin 2>$null
    }
    if ($url) { $buckets[$name] = $url }
}

$bucketsPath = Join-Path $RepoRoot "buckets.json"
$buckets | ConvertTo-Json | Set-Content -Path $bucketsPath -Encoding utf8

# 已安装且 bucket != main
$apps = @()
if (Test-Path $appsDir) {
    Get-ChildItem $appsDir -Directory | ForEach-Object {
        $installJson = Join-Path $_.FullName "current\install.json"
        if (-not (Test-Path $installJson)) { return }
        $j = Get-Content $installJson -Raw | ConvertFrom-Json
        $bucket = $j.bucket
        if (-not $bucket -or $bucket -eq "main") { return }
        $entry = [ordered]@{ app = $_.Name; bucket = $bucket }
        if ($_.Name -eq "symm" -and $bucket -eq "symm") {
            $entry["migrate"] = "scoop-bucket/symm"
        }
        $apps += $entry
    }
}

$catalog = [ordered]@{
    generated   = (Get-Date -Format "yyyy-MM-dd")
    scoop_root  = $ScoopRoot
    note        = "本机已安装且 bucket 非 main 的应用；由 scripts/export-from-windows.ps1 生成"
    apps        = @($apps | Sort-Object { $_.bucket }, { $_.app })
}

$catalogDir = Join-Path $RepoRoot "catalog"
if (-not (Test-Path $catalogDir)) { New-Item -ItemType Directory -Path $catalogDir | Out-Null }
$catalog | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $catalogDir "installed-non-main.json") -Encoding utf8

Write-Host "Wrote $($buckets.Count) buckets -> buckets.json"
Write-Host "Wrote $($apps.Count) apps -> catalog/installed-non-main.json"
