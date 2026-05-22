# Vendored from cmontage/scoopbucket-soup (New-PersistDirectory only, for uuyc)
function New-PersistDirectory {
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string]
        $dataPath,

        [parameter(Mandatory = $true, Position = 1)]
        [string]
        $persistPath,

        [switch]
        $Migrate
    )
    New-Item $persistPath -Type Directory -Force -ErrorAction SilentlyContinue | Out-Null
    if (Test-Path $dataPath) {
        $dataPathItem = Get-Item -Path $dataPath
        if ($dataPathItem.LinkType -eq 'Junction') {
            try { $dataPathItem.Delete() } catch {}
        }
        else {
            if ($Migrate) {
                Get-ChildItem $dataPath | ForEach-Object { Move-Item $_.FullName $persistPath -Force -ErrorAction SilentlyContinue | Out-Null }
            }
            Remove-Item $dataPath -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
        }
    }
    New-Item -ItemType Junction -Path $dataPath -Target $persistPath | Out-Null
}
