# Scoop extracts portable zip from GitHub Releases. Optional: migrate data from old local install.
$terminal = Join-Path $dir 'terminal64.exe'
if (-not (Test-Path -LiteralPath $terminal)) {
    throw 'metatrader5: terminal64.exe missing — portable zip extract failed'
}

Get-ChildItem $dir -Filter '*setup*.exe' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

$legacy = 'D:\Program\MetaTrader\MetaTrader 5'

# Optional one-time migration from previous non-Scoop install / AppData hash
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

if (Test-Path -LiteralPath $legacy) {
    foreach ($name in @('Bases', 'Config', 'logs', 'MQL5', 'Profiles', 'Tester', 'llm-agent')) {
        $dst = Join-Path $persist_dir $name
        $src = Join-Path $legacy $name
        $empty = -not (Test-Path -LiteralPath $dst) -or -not (Get-ChildItem -LiteralPath $dst -Force -ErrorAction SilentlyContinue | Select-Object -First 1)
        if ($empty -and (Test-Path -LiteralPath $src)) {
            info "[metatrader5] Migrating $name from legacy $legacy"
            New-Item -ItemType Directory -Path $dst -Force | Out-Null
            robocopy $src $dst /E /XO /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
        }
    }
}
