# Cursor：Inno 解包后启用 VS Code 系 portable（data/ 由 Scoop persist）
Remove-Item "$dir\`$*", "$dir\Uninst*" -Recurse -Force -ErrorAction SilentlyContinue

if (!(Test-Path "$dir\data\extensions") -and (Test-Path "$env:USERPROFILE\.cursor\extensions")) {
    info '[Portable Mode] Copying extensions from %USERPROFILE%\.cursor ...'
    New-Item -ItemType Directory -Path "$dir\data" -Force | Out-Null
    Copy-Item "$env:USERPROFILE\.cursor\extensions" "$dir\data" -Recurse -Force
}
if (!(Test-Path "$dir\data\user-data") -and (Test-Path "$env:APPDATA\Cursor")) {
    info '[Portable Mode] Copying user data from %APPDATA%\Cursor ...'
    New-Item -ItemType Directory -Path "$dir\data" -Force | Out-Null
    Copy-Item "$env:APPDATA\Cursor" "$dir\data\user-data" -Recurse -Force
}

$extensions_file = "$dir\data\extensions\extensions.json"
if (Test-Path $extensions_file) {
    info 'Adjusting path in extensions.json ...'
    (Get-Content $extensions_file -Raw) -replace '(?<=cursor(/|\\)).*?(?=(/|\\)data(/|\\)extensions)', $version |
        Set-Content -Path $extensions_file -NoNewline
}

# 去掉 product.json 的 "target":"user"，否则不会走旁边的 data/ portable
$product_path = "$dir\resources\app\product.json"
if (Test-Path $product_path) {
    $product_text = [System.IO.File]::ReadAllText($product_path)
    $product_patched = [regex]::Replace($product_text, ',\s*\r?\n\s*"target"\s*:\s*"user"(?=\s*\r?\n\})', '')
    if ($product_patched -ne $product_text) {
        info '[Portable Mode] Removing "target":"user" from product.json ...'
        [System.IO.File]::WriteAllText($product_path, $product_patched, (New-Object System.Text.UTF8Encoding($false)))
    } elseif (($product_text | ConvertFrom-Json).PSObject.Properties.Name -contains 'target') {
        warn 'Portable mode may be incomplete: unexpected product.json layout.'
    }
}

$argv_src = "$env:USERPROFILE\.cursor\argv.json"
$argv_dst = "$dir\data\argv.json"
if (!(Test-Path $argv_dst) -and (Test-Path $argv_src)) {
    info '[Portable Mode] Copying argv.json ...'
    New-Item -ItemType Directory -Path "$dir\data" -Force | Out-Null
    Copy-Item $argv_src $argv_dst -Force
}
