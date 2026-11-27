# Cursor / cursor327：共用 VS Code portable 初始化 + C 盘目录联接
Initialize-VscodePortableData `
    -ProfileDir (Join-Path $env:USERPROFILE '.cursor') `
    -RoamingAppData (Join-Path $env:APPDATA 'Cursor') `
    -ExtensionsPathPattern '(?<=cursor(/|\\)).*?(?=(/|\\)data(/|\\)extensions)'

. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true

# 应用/安装器有时会在开始菜单根目录再建 Cursor.lnk；只保留 Scoop Apps 里的入口
Remove-VendorShortcuts -Names @('Cursor') -TargetPathContains @('\apps\cursor\', '\apps\cursor327\') -Log

