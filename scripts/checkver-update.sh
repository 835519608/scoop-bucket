#!/usr/bin/env bash
# 在 Windows 宿主上更新本 bucket 全部 manifest 的 version/hash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec win-pwsh -NoProfile -ExecutionPolicy Bypass -Command @"
Set-Location '$ROOT'
scoop bucket update scoop-bucket 2>\$null
scoop checkver * -u
Write-Host 'Done. Review git diff in scoop-bucket before commit.'
"@
