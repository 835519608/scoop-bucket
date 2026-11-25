# CodeBuddy CN：VS Code portable 初始化 + C 盘目录联接（与 cursor 同一套 utils 逻辑）
Initialize-VscodePortableData `
    -ProfileDir (Join-Path $env:USERPROFILE '.codebuddycn') `
    -RoamingAppData (Join-Path $env:APPDATA 'CodeBuddy CN') `
    -ExtensionsPathPattern '(?<=codebuddycn(/|\\)).*?(?=(/|\\)data(/|\\)extensions)'

# CLI 写 .codebuddy；IDE 默认还会碰 AppData/Local（portable 之外兜底联接）
. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true
