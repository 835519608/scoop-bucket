# Optional migrate from previous D:\Program\WeGame install into Scoop persist
$legacy = 'D:\Program\WeGame'
if (Test-Path -LiteralPath $legacy) {
    foreach ($name in @('downloads', 'games', 'data', 'config', 'client_config')) {
        $src = Join-Path $legacy $name
        $dst = Join-Path $persist_dir $name
        if (-not (Test-Path -LiteralPath $src)) { continue }
        $empty = -not (Test-Path -LiteralPath $dst) -or -not (Get-ChildItem -LiteralPath $dst -Force -ErrorAction SilentlyContinue | Select-Object -First 1)
        if ($empty) {
            info "[wegame] Migrating $name from $legacy"
            New-Item -ItemType Directory -Path $dst -Force | Out-Null
            robocopy $src $dst /E /XO /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
        }
    }
}

. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true
