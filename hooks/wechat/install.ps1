# WeChat 4.x (Weixin): unpack + redirect C: user data into Scoop persist
Expand-7zipArchive "$dir\install.7z" "$dir" -Removal
Remove-NsisExtractCrumbs -Path $dir

. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true

# FileSavePath / ini 存的是「用户选的父目录」；微信会自己拼上 xwechat_files
# 例：选 D:\File → 实际聊天文件在 D:\File\xwechat_files
$filesLeaf = 'xwechat_files'
$filesPersistRoot = $persist_dir
Ensure-FolderExists -Path (Join-Path $filesPersistRoot $filesLeaf)

$regPath = 'HKCU:\Software\Tencent\Weixin'
if (!(Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

function Get-WeChatFileSaveRoot {
    param ([string]$Path)
    if (-not $Path) { return $null }
    $trim = $Path.TrimEnd('\')
    if ($trim -match '[\\/]xwechat_files$') {
        return [System.IO.Path]::GetDirectoryName($trim)
    }
    return $trim
}

function Test-WeChatFileSaveRoot {
    param ([string]$Root)
    if (-not $Root) { return $false }
    $root = Get-WeChatFileSaveRoot $Root
    if (-not $root) { return $false }
    $driveRoot = [System.IO.Path]::GetPathRoot($root)
    $sysRoot = [System.IO.Path]::GetPathRoot($env:SystemRoot)
    if (-not $driveRoot -or -not $sysRoot) { return $false }
    if ($driveRoot.TrimEnd('\') -eq $sysRoot.TrimEnd('\')) { return $false }
    $leaf = Join-Path $root $filesLeaf
    return (Test-Path -LiteralPath $root) -or (Test-Path -LiteralPath $leaf)
}

$existingSave = $null
try { $existingSave = (Get-ItemProperty -Path $regPath -Name 'FileSavePath' -ErrorAction SilentlyContinue).FileSavePath } catch {}

$iniPath = Join-Path $env:APPDATA 'Tencent\xwechat\config\51a1fffea11325a1e4104c6b3de47af7.ini'
$existingIni = $null
if (Test-Path -LiteralPath $iniPath) {
    $existingIni = (Get-Content -LiteralPath $iniPath -Raw -ErrorAction SilentlyContinue).Trim()
}

$savePath = $filesPersistRoot
$kept = $null
foreach ($candidate in @($existingIni, $existingSave)) {
    $root = Get-WeChatFileSaveRoot $candidate
    if (Test-WeChatFileSaveRoot $root) {
        $kept = $root
        break
    }
}

if ($kept) {
    $savePath = $kept
    info "[wechat] Keeping FileSavePath root: $savePath (files → $(Join-Path $savePath $filesLeaf))"
}
else {
    foreach ($candidate in @(
            'D:\File'
            [Environment]::GetFolderPath('MyDocuments')
        )) {
        $root = Get-WeChatFileSaveRoot $candidate
        if (Test-WeChatFileSaveRoot $root) {
            $savePath = $root
            info "[wechat] Reusing FileSavePath root: $savePath"
            break
        }
    }
}

New-ItemProperty -Path $regPath -Name 'FileSavePath' -Value $savePath -Force | Out-Null
New-ItemProperty -Path $regPath -Name 'InstallPath' -Value $dir -Force | Out-Null

$configPath = Join-Path $env:APPDATA 'Tencent\xwechat\config'
Ensure-FolderExists -Path $configPath
Set-Content -NoNewline -Path $iniPath -Value $savePath -Encoding Ascii
