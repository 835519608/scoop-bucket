# WeChat 4.x (Weixin): unpack + redirect C: user data into Scoop persist
Expand-7zipArchive "$dir\install.7z" "$dir" -Removal
Remove-NsisExtractCrumbs -Path $dir

. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true

# File save path: keep existing non-C location; otherwise use persist/xwechat_files
$filesPersist = Join-Path $persist_dir 'xwechat_files'
Ensure-FolderExists -Path $filesPersist

$regPath = 'HKCU:\Software\Tencent\Weixin'
if (!(Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

$existingSave = $null
try { $existingSave = (Get-ItemProperty -Path $regPath -Name 'FileSavePath' -ErrorAction SilentlyContinue).FileSavePath } catch {}

function Test-NonSystemDrivePath {
    param ([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return $false }
    $root = [System.IO.Path]::GetPathRoot($Path)
    $sysRoot = [System.IO.Path]::GetPathRoot($env:SystemRoot)
    return [bool]($root -and $sysRoot -and ($root.TrimEnd('\') -ne $sysRoot.TrimEnd('\')))
}

$savePath = $filesPersist
if (Test-NonSystemDrivePath $existingSave) {
    $savePath = $existingSave
    info "[wechat] Keeping existing FileSavePath: $savePath"
}
else {
    foreach ($candidate in @(
            'D:\File\xwechat_files'
            (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'xwechat_files')
        )) {
        if (Test-NonSystemDrivePath $candidate) {
            $savePath = $candidate
            info "[wechat] Reusing existing chat files dir: $savePath"
            break
        }
    }
}

New-ItemProperty -Path $regPath -Name 'FileSavePath' -Value $savePath -Force | Out-Null
New-ItemProperty -Path $regPath -Name 'InstallPath' -Value $dir -Force | Out-Null

$configPath = Join-Path $env:APPDATA 'Tencent\xwechat\config'
Ensure-FolderExists -Path $configPath
Set-Content -NoNewline -Path (Join-Path $configPath '51a1fffea11325a1e4104c6b3de47af7.ini') -Value $savePath -Encoding Ascii
