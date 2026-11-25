# Cursor / cursor327：共用 VS Code portable 初始化 + C 盘目录联接
Initialize-VscodePortableData `
    -ProfileDir (Join-Path $env:USERPROFILE '.cursor') `
    -RoamingAppData (Join-Path $env:APPDATA 'Cursor') `
    -ExtensionsPathPattern '(?<=cursor(/|\\)).*?(?=(/|\\)data(/|\\)extensions)'

. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true
