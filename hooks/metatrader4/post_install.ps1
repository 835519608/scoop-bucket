$terminal = Join-Path $dir 'terminal.exe'
if (-not (Test-Path -LiteralPath $terminal)) {
    throw 'metatrader4: terminal.exe missing — portable zip extract failed'
}

Get-ChildItem $dir -Filter '*setup*.exe' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $dir 'uninstall.exe') -Force -ErrorAction SilentlyContinue

foreach ($name in @('MetaTrader 4', 'MetaTrader 5')) {
    $menu = Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\$name"
    if (Test-Path -LiteralPath $menu) {
        info "[metatrader4] Removing duplicate Start Menu folder: $menu"
        Remove-Item -LiteralPath $menu -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Install-MetaTraderLaunchers -AppDir $dir -App metatrader4 -Log:$true
