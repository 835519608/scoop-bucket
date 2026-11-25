$setup = Get-ChildItem $dir -Filter 'mt4setup.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $setup) {
    $setup = Get-ChildItem $dir -Filter '*setup*.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
}

$terminal = Join-Path $dir 'terminal.exe'
if (-not (Test-Path -LiteralPath $terminal) -and $setup) {
    Start-Process -FilePath $setup.FullName -ArgumentList @('/auto', "/path:`"$dir`"") -Wait -ErrorAction SilentlyContinue
}

if (-not (Test-Path -LiteralPath $terminal)) {
    $legacy = 'D:\Program\MetaTrader\MetaTrader 4'
    if (Test-Path -LiteralPath (Join-Path $legacy 'terminal.exe')) {
        info '[metatrader4] Seeding program tree from D:\Program\MetaTrader\MetaTrader 4'
        robocopy $legacy $dir /E /XD config history logs MQL4 profiles templates tester /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    }
}

if (-not (Test-Path -LiteralPath $terminal)) {
    throw 'metatrader4: terminal.exe missing after install/seed'
}

Get-ChildItem $dir -Filter '*setup*.exe' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

$legacy = 'D:\Program\MetaTrader\MetaTrader 4'
foreach ($name in @('config', 'history', 'logs', 'MQL4', 'profiles', 'templates', 'tester')) {
    $dst = Join-Path $persist_dir $name
    $src = Join-Path $legacy $name
    $empty = -not (Test-Path -LiteralPath $dst) -or -not (Get-ChildItem -LiteralPath $dst -Force -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($empty -and (Test-Path -LiteralPath $src)) {
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
        robocopy $src $dst /E /XO /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    }
}
