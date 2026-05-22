# 在 WSL 中通过 win-pwsh 调用，或于 Windows PowerShell 直接运行。
# 从 Windows 宿主机 Scoop 导出「非 scoop.sh 官方库」的社区 bucket 源与本机已安装应用。
param(
    [string]$ScoopRoot = "D:\Program\Scoop",
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ScoopRoot)) {
    throw "Scoop 根目录不存在: $ScoopRoot"
}

function Normalize-RepoUrl {
    param([string]$Url)
    if (-not $Url) { return "" }
    $u = $Url.Trim().TrimEnd('/').ToLower()
    $u = $u -replace '\.git$', ''
    $u = $u -replace '^https://scoop\.201704\.xyz/', 'https://'
    return $u
}

$officialFile = Join-Path $PSScriptRoot "official-buckets.json"
$officialMap = Get-Content $officialFile -Raw | ConvertFrom-Json
$officialUrls = @{}
foreach ($prop in $officialMap.buckets.PSObject.Properties) {
    $officialUrls[(Normalize-RepoUrl $prop.Value)] = $true
}

function Test-IsOfficialBucketUrl {
    param([string]$Url)
    return $officialUrls.ContainsKey((Normalize-RepoUrl $Url))
}

$bucketsDir = Join-Path $ScoopRoot "buckets"
$appsDir = Join-Path $ScoopRoot "apps"

# 本仓库自身、已弃用的 symm 独立 bucket 不写入 buckets.json
$skipBucketNames = @("scoop-bucket", "symm")
$buckets = @{}
$bucketUrlByName = @{}

Get-ChildItem $bucketsDir -Directory | ForEach-Object {
    $name = $_.Name
    if ($name -in $skipBucketNames) { return }
    $url = ""
    if (Test-Path (Join-Path $_.FullName ".git")) {
        $url = git -C $_.FullName remote get-url origin 2>$null
    }
    if (-not $url) { return }
    $bucketUrlByName[$name] = $url
    if (Test-IsOfficialBucketUrl $url) { return }
    $buckets[$name] = $url
}

$bucketsPath = Join-Path $RepoRoot "buckets.json"
$sorted = [ordered]@{}
$buckets.GetEnumerator() | Sort-Object Name | ForEach-Object { $sorted[$_.Key] = $_.Value }
$sorted | ConvertTo-Json | Set-Content -Path $bucketsPath -Encoding utf8

# 已安装且来自社区 bucket 的应用
$apps = @()
if (Test-Path $appsDir) {
    Get-ChildItem $appsDir -Directory | ForEach-Object {
        $installJson = Join-Path $_.FullName "current\install.json"
        if (-not (Test-Path $installJson)) { return }
        $j = Get-Content $installJson -Raw | ConvertFrom-Json
        $bucket = $j.bucket
        if (-not $bucket) { return }
        $bucketUrl = $bucketUrlByName[$bucket]
        # symm 独立 bucket 已弃用，仍记录到 catalog 便于迁移
        if ($_.Name -eq "symm" -and $bucket -eq "symm") {
            $apps += [ordered]@{ app = "symm"; bucket = "symm"; migrate = "scoop-bucket/symm" }
            return
        }
        if (-not $bucketUrl -or (Test-IsOfficialBucketUrl $bucketUrl)) { return }
        $apps += [ordered]@{ app = $_.Name; bucket = $bucket }
    }
}

$catalog = [ordered]@{
    generated  = (Get-Date -Format "yyyy-MM-dd")
    scoop_root = $ScoopRoot
    note       = "本机已安装且来自社区 bucket（非 Scoop 官方库，需 scoop bucket add）的应用"
    apps       = @($apps | Sort-Object { $_.bucket }, { $_.app })
}

$catalogDir = Join-Path $RepoRoot "catalog"
if (-not (Test-Path $catalogDir)) { New-Item -ItemType Directory -Path $catalogDir | Out-Null }
$catalogPath = Join-Path $catalogDir "installed-community.json"
$catalog | ConvertTo-Json -Depth 5 | Set-Content -Path $catalogPath -Encoding utf8

# 移除旧文件名
$legacyCatalog = Join-Path $catalogDir "installed-non-main.json"
if (Test-Path $legacyCatalog) { Remove-Item $legacyCatalog -Force }

Write-Host "Wrote $($buckets.Count) community buckets -> buckets.json"
Write-Host "Wrote $($apps.Count) apps -> catalog/installed-community.json"
