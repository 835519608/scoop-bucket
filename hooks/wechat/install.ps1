# WeChat 4.x (Weixin): unpack + redirect C: user data into Scoop persist
Expand-7zipArchive "$dir\install.7z" "$dir" -Removal
Remove-NsisExtractCrumbs -Path $dir

. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true

# FileSavePath / ini = 父目录；微信自行拼 xwechat_files。无硬编码盘符。
# 优先保留已有合法非 C 路径；否则用 Scoop persist 根目录。
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
foreach ($candidate in @($existingIni, $existingSave)) {
    $root = Get-WeChatFileSaveRoot $candidate
    if (Test-WeChatFileSaveRoot $root) {
        $savePath = $root
        info "[wechat] Keeping FileSavePath root: $savePath (files → $(Join-Path $savePath $filesLeaf))"
        break
    }
}
if ($savePath -eq $filesPersistRoot) {
    info "[wechat] FileSavePath root → persist: $savePath"
}
New-ItemProperty -Path $regPath -Name 'FileSavePath' -Value $savePath -Force | Out-Null
New-ItemProperty -Path $regPath -Name 'InstallPath' -Value $dir -Force | Out-Null

$configPath = Join-Path $env:APPDATA 'Tencent\xwechat\config'
Ensure-FolderExists -Path $configPath
Set-Content -NoNewline -Path $iniPath -Value $savePath -Encoding Ascii
