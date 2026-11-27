# NSIS (#/dl.7z) 只解出插件目录；真正程序在 $PLUGINSDIR\app-64.7z
$pluginDir = Join-Path $dir '$PLUGINSDIR'
$app64 = Join-Path $pluginDir 'app-64.7z'
if (-not (Test-Path -LiteralPath $app64)) {
    throw 'deepseek-harness: $PLUGINSDIR\app-64.7z missing after NSIS extract'
}

Expand-7zipArchive -Path $app64 -DestinationPath $dir
Remove-Item -LiteralPath $pluginDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $dir 'Uninstall DeepSeek Harness.exe') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $dir '7zip-installer-LICENSE.txt') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $dir '7zip-installer-COPYING.txt') -Force -ErrorAction SilentlyContinue

$exe = Join-Path $dir 'DeepSeek Harness.exe'
if (-not (Test-Path -LiteralPath $exe)) {
    throw 'deepseek-harness: DeepSeek Harness.exe missing after app-64.7z extract'
}

. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true

Remove-VendorShortcuts -Names @('DeepSeek Harness', 'DeepSeekHarness') -TargetPathContains @('\apps\deepseek-harness\') -Log
