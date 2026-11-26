# Merge previous D:\Program\WeGame into Scoop persist (Scoop may already seed dirs from package)
$legacy = 'D:\Program\WeGame'
if (Test-Path -LiteralPath $legacy) {
    foreach ($name in @('downloads', 'games', 'data', 'config', 'client_config')) {
        $src = Join-Path $legacy $name
        $dst = Join-Path $persist_dir $name
        if (-not (Test-Path -LiteralPath $src)) { continue }
        info "[wegame] Merging $name from $legacy"
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
        & robocopy $src $dst /E /XO /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    }
}

. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true
