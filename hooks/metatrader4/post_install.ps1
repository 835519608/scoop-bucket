# Scoop extracts portable zip from GitHub Releases. Optional: migrate data from old local install.
$terminal = Join-Path $dir 'terminal.exe'
if (-not (Test-Path -LiteralPath $terminal)) {
    throw 'metatrader4: terminal.exe missing — portable zip extract failed'
}

Get-ChildItem $dir -Filter '*setup*.exe' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

$legacy = 'D:\Program\MetaTrader\MetaTrader 4'
if (Test-Path -LiteralPath $legacy) {
    foreach ($name in @('config', 'history', 'logs', 'MQL4', 'profiles', 'templates', 'tester')) {
        $dst = Join-Path $persist_dir $name
        $src = Join-Path $legacy $name
        $empty = -not (Test-Path -LiteralPath $dst) -or -not (Get-ChildItem -LiteralPath $dst -Force -ErrorAction SilentlyContinue | Select-Object -First 1)
        if ($empty -and (Test-Path -LiteralPath $src)) {
            info "[metatrader4] Migrating $name from legacy $legacy"
            New-Item -ItemType Directory -Path $dst -Force | Out-Null
            robocopy $src $dst /E /XO /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
        }
    }
}
