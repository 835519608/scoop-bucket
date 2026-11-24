# 便携 Config/Data/History 已由 Scoop persist；右键菜单等仍写 %LOCALAPPDATA%\PixPin
$pixpinMappings = @(
    @{ Label = 'local'; Source = 'LocalAppData/PixPin'; Target = '$persist_dir/LocalAppData'; EnsureTarget = $true }
)
Install-PersistDataLinks -Mappings $pixpinMappings -Log:$true

# 对齐 sdoog：关掉崩溃上报与自动升级（写进 persist Config）
$configDir = Join-Path $persist_dir 'Config'
New-Item -ItemType Directory -Path $configDir -Force | Out-Null
$configFile = Join-Path $configDir 'PixPinConfig.json'
if (!(Test-Path $configFile) -or !(Get-Item $configFile).Length) {
    Set-Content -Path $configFile -Encoding UTF8 -Value '{"System.Crash feedback.UploadCrashInformation":{"t":1735664461,"v":false},"System.Update.UpgradeMode#s.win":{"t":1735664461,"v":0}}'
}

$localStorage = Join-Path $dir 'LocalStorage.data'
if (!(Test-Path $localStorage) -or !(Get-Item $localStorage).Length) {
    Set-Content -Path $localStorage -Encoding ASCII -Value "[General]`r`nIsFirstRun=false`r`ndevID=$((New-Guid).Guid)"
}

Clear-DesktopShortcuts -Filter 'PixPin*.lnk'
Clear-StartMenuShortcuts -Filter 'PixPin*.lnk'
