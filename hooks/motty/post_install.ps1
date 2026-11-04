# 便携 zip 自带 motty-data；留在 exe 旁会走便携模式，数据路径经过 Scoop current 联接会触发
# 「cannot determine on-disk case」。删掉旁路目录，改用 %APPDATA%\motty（与官方安装版一致）。
$portableMarker = Join-Path $dir 'motty-data'
if (Test-Path -LiteralPath $portableMarker) {
    Remove-DirectoryLink -LinkPath $portableMarker
    if (Test-Path -LiteralPath $portableMarker) {
        Remove-Item -LiteralPath $portableMarker -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 旧版 persist\motty-data → persist\roaming
$legacy = Join-Path $persist_dir 'motty-data'
$roaming = Join-Path $persist_dir 'roaming'
if ((Test-Path -LiteralPath $legacy) -and -not (Test-Path -LiteralPath $roaming)) {
    Rename-Item -LiteralPath $legacy -NewName 'roaming'
}

$mottyMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/motty'; Target = '$persist_dir/roaming'; EnsureTarget = $true }
)
Install-PersistDataLinks -Mappings $mottyMappings

# 清掉上一版 env_set 留下的 MOTTY_DATA_DIR，避免与 AppData 方案冲突
if ([Environment]::GetEnvironmentVariable('MOTTY_DATA_DIR', 'User')) {
    [Environment]::SetEnvironmentVariable('MOTTY_DATA_DIR', $null, 'User')
}
Remove-Item Env:MOTTY_DATA_DIR -ErrorAction SilentlyContinue
