#Requires -Version 5.1
<#
.SYNOPSIS
  对易变 CDN 包跑 Scoop checkhashes -Update，版本不变但二进制被替换时自动纠 hash。
.NOTES
  Excavator / checkver 只在版本号变化时重算 hash；本脚本补上同版本换包的缺口。
#>
$ErrorActionPreference = 'Stop'

$bucketDir = Join-Path $PSScriptRoot '..\..\bucket' | Resolve-Path

# 官网 CDN / latest 固定 URL：同版本常被重新投放（ToDesk / 微信 / UU 等）
$volatileApps = @(
    'todesk'
    'wechat'
    'uu'
    'uuyc'
    'wegame'
    'dingtalk'
    'douyin'
    'pixpin'
    'codebuddy-cn'
    'workbuddy-cn'
    'hbuilderx'
    'deepseek-harness'
    'cursor'
    'cursor327'
)

if (-not $env:SCOOP_HOME) {
    $env:SCOOP_HOME = Convert-Path (scoop prefix scoop)
}
$checkhashes = Join-Path $env:SCOOP_HOME 'bin\checkhashes.ps1'
if (-not (Test-Path -LiteralPath $checkhashes)) {
    throw "Scoop checkhashes not found: $checkhashes"
}

$updated = @()
foreach ($app in $volatileApps) {
    $manifest = Join-Path $bucketDir "$app.json"
    if (-not (Test-Path -LiteralPath $manifest)) {
        Write-Host "skip missing $app"
        continue
    }

    Write-Host "=== checkhashes $app ==="
    $before = Get-FileHash -LiteralPath $manifest -Algorithm SHA256
    & $checkhashes -App $app -Dir $bucketDir -Update -SkipCorrect
    $after = Get-FileHash -LiteralPath $manifest -Algorithm SHA256
    if ($before.Hash -ne $after.Hash) {
        $updated += $app
        Write-Host "updated $app"
    }
}

if ($updated.Count -eq 0) {
    Write-Host 'No hash changes.'
} else {
    Write-Host ("Updated: " + ($updated -join ', '))
}

# 给 workflow 用：有变更则写标记文件
$marker = Join-Path $env:RUNNER_TEMP 'hash-refresh-updated.txt'
if ($env:RUNNER_TEMP -and $updated.Count -gt 0) {
    $updated -join "`n" | Set-Content -LiteralPath $marker -Encoding utf8
}
