# Inner NSIS payload: WeGameSetup.exe is 7z-compatible (same as extras-cn / aki)
$setup = Join-Path $dir 'WeGameSetup.exe'
if (Test-Path -LiteralPath $setup) {
    Expand-7zipArchive -Path $setup -DestinationPath $dir
    Remove-Item -LiteralPath $setup -Force -ErrorAction SilentlyContinue
}
Remove-Item "$dir\`$PLUGINSDIR", "$dir\`$SYSDIR" -Force -Recurse -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath (Join-Path $dir 'wegame.exe'))) {
    throw 'wegame: wegame.exe missing after extract'
}
