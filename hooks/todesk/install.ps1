Assert-AdminElevation -Reason 'ToDesk 安装需要管理员 PowerShell（服务）。' -InstallHint 'scoop install scoop-bucket/todesk'

$app64 = Join-Path $dir 'app64.7z'
if (Test-Path -LiteralPath $app64) {
    Expand-7zipArchive -Path $app64 -DestinationPath $dir
    Remove-Item -LiteralPath $app64 -Force -ErrorAction SilentlyContinue
}
Get-ChildItem $dir -Filter 'ToDesk_*.exe' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem $dir -Filter 'setup.7z' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

$configPersist = Join-Path $persist_dir 'config.ini'
$legacyConfig = 'D:\Program\ToDesk\config.ini'
if (-not (Test-Path -LiteralPath $configPersist) -or -not (Get-Item -LiteralPath $configPersist).Length) {
    New-Item -ItemType Directory -Path $persist_dir -Force -ErrorAction SilentlyContinue | Out-Null
    if (Test-Path -LiteralPath $legacyConfig) {
        Copy-Item -LiteralPath $legacyConfig -Destination $configPersist -Force
        info '[todesk] Migrated config.ini from D:\Program\ToDesk'
    }
    else {
        @"
[ConfigInfo]
passUpdate=0
PrivateScreenLockScreen=0
autoLockScreen=0
language=936
isOpenTempPass=1
isAdmissionControl=1
WeakPasswordTip=0
isUpdate=0
PresetDialogShowCount=0
AuthMode=0
autoupdate=0
isexpand=0
UpdateTempPassDefault=1
Version=$version
"@ | Set-Content -Path $configPersist -Encoding UTF8
    }
}

. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true
