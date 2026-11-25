# 去掉自带更新器，改由 scoop update 管理（对齐 sdoog/soup）
Remove-Item "$dir\Updater.exe" -Force -ErrorAction SilentlyContinue

. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true
