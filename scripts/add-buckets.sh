#!/usr/bin/env bash
# WSL 下通过 Windows 宿主 pwsh 添加 buckets.json 中的社区 bucket 源
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec win-pwsh -NoProfile -ExecutionPolicy Bypass -File "$ROOT/scripts/add-buckets.ps1" -SkipExisting "$@"
