# MetaQuotes /auto is NOT fully silent. Prefer local seed; never launch setup when seed exists.
$terminal = Join-Path $dir 'terminal.exe'
$legacy = 'D:\Program\MetaTrader\MetaTrader 4'

if (-not (Test-Path -LiteralPath $terminal)) {
    if (Test-Path -LiteralPath (Join-Path $legacy 'terminal.exe')) {
        info '[metatrader4] Seeding program tree from D:\Program\MetaTrader\MetaTrader 4 (skip GUI setup)'
        robocopy $legacy $dir /E /XD config history logs MQL4 profiles templates tester /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    }
}

if (-not (Test-Path -LiteralPath $terminal)) {
    $setup = Get-ChildItem $dir -Filter 'mt4setup.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $setup) {
        $setup = Get-ChildItem $dir -Filter '*setup*.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    if ($setup) {
        warn '[metatrader4] No local seed; launching mt4setup /auto (EULA UI may appear — click through once)'
        Start-Process -FilePath $setup.FullName -ArgumentList @('/auto', "/path:`"$dir`"") -Wait -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path -LiteralPath $terminal)) {
    throw 'metatrader4: terminal.exe missing after seed/install'
}

Get-ChildItem $dir -Filter '*setup*.exe' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

foreach ($name in @('config', 'history', 'logs', 'MQL4', 'profiles', 'templates', 'tester')) {
    $dst = Join-Path $persist_dir $name
    $src = Join-Path $legacy $name
    $empty = -not (Test-Path -LiteralPath $dst) -or -not (Get-ChildItem -LiteralPath $dst -Force -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($empty -and (Test-Path -LiteralPath $src)) {
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
        robocopy $src $dst /E /XO /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    }
}
