# MetaQuotes /auto is NOT fully silent (still shows EULA). Prefer local seed; never launch setup when seed exists.
$terminal = Join-Path $dir 'terminal64.exe'
$legacy = 'D:\Program\MetaTrader\MetaTrader 5'

if (-not (Test-Path -LiteralPath $terminal)) {
    if (Test-Path -LiteralPath (Join-Path $legacy 'terminal64.exe')) {
        info '[metatrader5] Seeding program tree from D:\Program\MetaTrader\MetaTrader 5 (skip GUI setup)'
        robocopy $legacy $dir /E /XD Bases Config logs MQL5 Profiles Tester llm-agent /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    }
}

# Only if no seed: try /auto (may still show license UI — last resort)
if (-not (Test-Path -LiteralPath $terminal)) {
    $setup = Get-ChildItem $dir -Filter 'mt5setup.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $setup) {
        $setup = Get-ChildItem $dir -Filter '*setup*.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    if ($setup) {
        warn '[metatrader5] No local seed; launching mt5setup /auto (EULA UI may appear — click through once)'
        Start-Process -FilePath $setup.FullName -ArgumentList @('/auto', "/path:`"$dir`"") -Wait -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path -LiteralPath $terminal)) {
    throw 'metatrader5: terminal64.exe missing after seed/install'
}

Get-ChildItem $dir -Filter '*setup*.exe' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

# Migrate AppData hash folder whose origin points at legacy install
$metaRoot = Join-Path $env:APPDATA 'MetaQuotes\Terminal'
if (Test-Path -LiteralPath $metaRoot) {
    Get-ChildItem $metaRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $origin = Join-Path $_.FullName 'origin.txt'
        if (-not (Test-Path -LiteralPath $origin)) { return }
        $text = (Get-Content -LiteralPath $origin -Raw -ErrorAction SilentlyContinue)
        if ($text -notmatch 'MetaTrader\\MetaTrader 5|MetaTrader 5') { return }
        info "[metatrader5] Migrating AppData terminal data from $($_.FullName)"
        foreach ($name in @('Bases', 'Config', 'MQL5', 'Profiles', 'Tester', 'logs', 'Logs')) {
            $src = Join-Path $_.FullName $name
            $dst = Join-Path $persist_dir $name
            if (Test-Path -LiteralPath $src) {
                New-Item -ItemType Directory -Path $dst -Force -ErrorAction SilentlyContinue | Out-Null
                robocopy $src $dst /E /XO /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
            }
        }
    }
}

foreach ($name in @('Bases', 'Config', 'logs', 'MQL5', 'Profiles', 'Tester', 'llm-agent')) {
    $dst = Join-Path $persist_dir $name
    $src = Join-Path $legacy $name
    $empty = -not (Test-Path -LiteralPath $dst) -or -not (Get-ChildItem -LiteralPath $dst -Force -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($empty -and (Test-Path -LiteralPath $src)) {
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
        robocopy $src $dst /E /XO /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    }
}

if ((Test-Path -LiteralPath (Join-Path $legacy 'llm-agent')) -and -not (Test-Path -LiteralPath (Join-Path $dir 'llm-agent'))) {
    New-Item -ItemType Directory -Path (Join-Path $persist_dir 'llm-agent') -Force -ErrorAction SilentlyContinue | Out-Null
}
