# 从旧版 AppData 联接方案迁回官方便携 persist（motty-data）。
# v0.3.2+ 已修复 Scoop current 联接启动失败，不再需要删旁路目录。

$legacyMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/motty'; Target = '$persist_dir/roaming' }
)
Uninstall-PersistDataLinks -Mappings $legacyMappings

$roaming = Join-Path $persist_dir 'roaming'
$portable = Join-Path $persist_dir 'motty-data'
if (Test-Path -LiteralPath $roaming) {
    New-Item -ItemType Directory -Force -Path $portable | Out-Null
    Get-ChildItem -LiteralPath $roaming -Force -ErrorAction SilentlyContinue | ForEach-Object {
        Move-Item -LiteralPath $_.FullName -Destination (Join-Path $portable $_.Name) -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $roaming -Recurse -Force -ErrorAction SilentlyContinue
}

if ([Environment]::GetEnvironmentVariable('MOTTY_DATA_DIR', 'User')) {
    [Environment]::SetEnvironmentVariable('MOTTY_DATA_DIR', $null, 'User')
}
Remove-Item Env:MOTTY_DATA_DIR -ErrorAction SilentlyContinue
