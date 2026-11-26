# scoop-bucket 公共 PowerShell 库（由 bin/hook.ps1 加载）
#
# 对外 API:
#   Install-PersistDataLinks / Uninstall-PersistDataLinks
#   Test-RealPath / Test-RealDirectory / Initialize-VscodePortableData
#   Remove-NsisExtractCrumbs / Set-ShortcutAppUserModelId
#   Install-MetaTraderPortableWrapper
#   Test-AdminElevation / Assert-AdminElevation / Test-AdminElevationOrWarn
#
# Mapping: Label, Source, Target, EnsureTarget（可选）
# 联接规则统一：源若已是 Junction 则跳过迁移，只重建联接；实目录则先迁入 persist 再联接。
# 各 app 的映射写在 hooks/<app>/persist.ps1（$persistMappings），install/uninstall 共用。

#region 路径判定（跳过已有联接，避免把 persist 再拷回 portable）

function Test-RealPath {
    param ([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    return [bool]($item -and -not $item.LinkType)
}

function Test-RealDirectory {
    param ([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-RealPath -Path $Path)) { return $false }
    return [bool]((Get-Item -LiteralPath $Path -Force).PSIsContainer)
}

#endregion

#region 底层：目录联接

function Remove-DirectoryLink {
    param (
        [Parameter(Mandatory = $true)]
        [string]$LinkPath,
        [switch]$Log
    )
    if (-not (Test-Path $LinkPath)) { return }
    $item = Get-Item -Path $LinkPath -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType) {
        Remove-Item -LiteralPath $LinkPath -Force -ErrorAction SilentlyContinue
        if ($Log) { info "[scoop-bucket] Removed $($item.LinkType): $LinkPath" }
        return
    }
    Remove-Item -Path $LinkPath -Force -Recurse -ErrorAction SilentlyContinue
}

function New-DirectoryLink {
    param (
        [Parameter(Mandatory = $true)]
        [string]$LinkPath,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )
    New-Item -Path $TargetPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    if (Test-Path $LinkPath) {
        $existing = Get-Item -Path $LinkPath -Force -ErrorAction SilentlyContinue
        if ($existing.LinkType) {
            try { $existing.Delete() } catch {
                Remove-DirectoryLink -LinkPath $LinkPath
            }
        }
        else {
            Remove-Item -Path $LinkPath -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
    New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath -Force -ErrorAction Stop | Out-Null
}

#endregion

#region NSIS / 7z 解压残渣

function Remove-NsisExtractCrumbs {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return }
    Remove-Item "$Path\`$*", "$Path\Uninst*", "$Path\uninst*" -Force -Recurse -ErrorAction SilentlyContinue
}

#endregion

#region 快捷方式 AppUserModelID（任务栏图标）

# WScript.Shell 无法写 System.AppUserModel.ID；Steam 等声明显式 AUMID 的应用
# 若开始菜单 .lnk 没有同名 AUMID，任务栏会落到空白占位图标。
function Set-ShortcutAppUserModelId {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$AppUserModelId,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [string]$Arguments = '',
        [string]$WorkingDirectory = '',
        [string]$IconLocation = '',
        [int]$IconIndex = 0,
        [string]$Description = ''
    )

    if (-not ([System.Management.Automation.PSTypeName]'ScoopBucketShell.Lnk').Type) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

namespace ScoopBucketShell {
    [ComImport, Guid("00021401-0000-0000-C000-000000000046")]
    public class CShellLink {}

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown),
     Guid("000214F9-0000-0000-C000-000000000046")]
    public interface IShellLinkW {
        void GetPath([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder f, int cch, IntPtr fd, int flags);
        void GetIDList(out IntPtr ppidl);
        void SetIDList(IntPtr pidl);
        void GetDescription([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder n, int cch);
        void SetDescription([MarshalAs(UnmanagedType.LPWStr)] string n);
        void GetWorkingDirectory([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder d, int cch);
        void SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string d);
        void GetArguments([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder a, int cch);
        void SetArguments([MarshalAs(UnmanagedType.LPWStr)] string a);
        void GetHotkey(out short w);
        void SetHotkey(short w);
        void GetShowCmd(out int c);
        void SetShowCmd(int c);
        void GetIconLocation([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder p, int cch, out int i);
        void SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string p, int i);
        void SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string rel, int reserved);
        void Resolve(IntPtr hwnd, int flags);
        void SetPath([MarshalAs(UnmanagedType.LPWStr)] string f);
    }

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown),
     Guid("0000010b-0000-0000-C000-000000000046")]
    public interface IPersistFile {
        void GetClassID(out Guid id);
        [PreserveSig] int IsDirty();
        void Load([MarshalAs(UnmanagedType.LPWStr)] string f, int mode);
        void Save([MarshalAs(UnmanagedType.LPWStr)] string f, [MarshalAs(UnmanagedType.Bool)] bool remember);
        void SaveCompleted([MarshalAs(UnmanagedType.LPWStr)] string f);
        void GetCurFile([MarshalAs(UnmanagedType.LPWStr)] out string f);
    }

    [StructLayout(LayoutKind.Sequential, Pack = 4)]
    public struct PROPERTYKEY { public Guid fmtid; public uint pid; }

    [StructLayout(LayoutKind.Explicit)]
    public struct PROPVARIANT {
        [FieldOffset(0)] public ushort vt;
        [FieldOffset(8)] public IntPtr p;
        [FieldOffset(8)] public long forceSize;
    }

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown),
     Guid("886d8eeb-8cf2-4446-8d02-cdba1dbdcf99")]
    public interface IPropertyStore {
        void GetCount(out uint n);
        void GetAt(uint i, out PROPERTYKEY key);
        void GetValue(ref PROPERTYKEY key, out PROPVARIANT pv);
        void SetValue(ref PROPERTYKEY key, ref PROPVARIANT pv);
        void Commit();
    }

    public static class Lnk {
        [DllImport("ole32.dll")]
        static extern int PropVariantClear(ref PROPVARIANT pv);

        const ushort VT_LPWSTR = 31;

        static PROPERTYKEY AppUserModelIdKey() {
            return new PROPERTYKEY {
                fmtid = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"),
                pid = 5
            };
        }

        public static void Write(
            string lnk, string target, string args, string workdir,
            string icon, int iconIndex, string desc, string appId
        ) {
            var link = (IShellLinkW)new CShellLink();
            link.SetPath(target);
            if (!string.IsNullOrEmpty(args)) { link.SetArguments(args); }
            if (!string.IsNullOrEmpty(workdir)) { link.SetWorkingDirectory(workdir); }
            if (!string.IsNullOrEmpty(icon)) { link.SetIconLocation(icon, iconIndex); }
            if (!string.IsNullOrEmpty(desc)) { link.SetDescription(desc); }
            link.SetShowCmd(1);

            if (!string.IsNullOrEmpty(appId)) {
                var store = (IPropertyStore)link;
                var key = AppUserModelIdKey();
                PROPVARIANT pv = new PROPVARIANT();
                pv.vt = VT_LPWSTR;
                pv.p = Marshal.StringToCoTaskMemUni(appId);
                try {
                    store.SetValue(ref key, ref pv);
                    store.Commit();
                }
                finally {
                    PropVariantClear(ref pv);
                }
            }

            var dir = System.IO.Path.GetDirectoryName(lnk);
            if (!string.IsNullOrEmpty(dir) && !System.IO.Directory.Exists(dir)) {
                System.IO.Directory.CreateDirectory(dir);
            }
            ((IPersistFile)link).Save(lnk, true);
        }
    }
}
'@
    }

    if (-not $WorkingDirectory) {
        $WorkingDirectory = [System.IO.Path]::GetDirectoryName($TargetPath)
    }
    if (-not $IconLocation) {
        $IconLocation = $TargetPath
    }

    [ScoopBucketShell.Lnk]::Write(
        $Path, $TargetPath, $Arguments, $WorkingDirectory,
        $IconLocation, $IconIndex, $Description, $AppUserModelId
    )
}

#endregion

#region MetaTrader：强制 /portable（WinShun 等直接点 exe 也走便携）

function Get-ScoopShimExePath {
    $roots = @()
    if ($scoopdir) { $roots += $scoopdir }
    if ($env:SCOOP) { $roots += $env:SCOOP }
    foreach ($root in ($roots | Select-Object -Unique)) {
        $hit = Get-ChildItem (Join-Path $root 'apps\scoop\current\supporting\shims') -Recurse -Filter 'shim.exe' -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    throw 'scoop shim.exe not found (is Scoop installed?)'
}

function Install-MetaTraderPortableWrapper {
    <#
    .SYNOPSIS
      Replace MetaTrader GUI exe with a Scoop shim that always passes /portable.
      Real binary kept as <name>-bin.exe beside it. Safe for WinShun / Explorer double-click.
    #>
    param (
        [Parameter(Mandatory = $true)][string]$AppDir,
        [Parameter(Mandatory = $true)][string]$ExeName,
        [string]$BinName,
        [string]$ShortcutName,
        [switch]$Log
    )
    if (-not $BinName) {
        $BinName = ($ExeName -replace '\.exe$', '') + '-bin.exe'
    }
    $exe = Join-Path $AppDir $ExeName
    $bin = Join-Path $AppDir $BinName
    $shimSide = Join-Path $AppDir (($ExeName -replace '\.exe$', '') + '.shim')
    $shimExe = Get-ScoopShimExePath

    if (-not (Test-Path -LiteralPath $exe) -and -not (Test-Path -LiteralPath $bin)) { return }

    if (Test-Path -LiteralPath $exe) {
        $len = (Get-Item -LiteralPath $exe).Length
        if ($len -gt 1MB) {
            if (Test-Path -LiteralPath $bin) { Remove-Item -LiteralPath $bin -Force }
            Move-Item -LiteralPath $exe -Destination $bin -Force
            Copy-Item -LiteralPath $shimExe -Destination $exe -Force
        } elseif (Test-Path -LiteralPath $bin) {
            Copy-Item -LiteralPath $shimExe -Destination $exe -Force
        } else {
            return
        }
    } elseif (Test-Path -LiteralPath $bin) {
        Copy-Item -LiteralPath $shimExe -Destination $exe -Force
    }

    $binFull = (Resolve-Path -LiteralPath $bin).Path
    Set-Content -Path $shimSide -Value "path = `"$binFull`"`r`nargs = /portable`r`n" -Encoding Ascii -NoNewline
    if ($Log) { info "[mt-portable] $ExeName -> $BinName (/portable)" }

    if ($ShortcutName) {
        $lnkPath = Join-Path $AppDir "$ShortcutName.lnk"
        $w = New-Object -ComObject WScript.Shell
        $lnk = $w.CreateShortcut($lnkPath)
        $lnk.TargetPath = $exe
        $lnk.Arguments = ''
        $lnk.WorkingDirectory = $AppDir
        $lnk.IconLocation = "$binFull,0"
        $lnk.Description = "$ShortcutName (Scoop portable)"
        $lnk.Save()
    }
}

function Install-MetaTraderPortableWrappers {
    param (
        [Parameter(Mandatory = $true)][string]$AppDir,
        [Parameter(Mandatory = $true)][ValidateSet('metatrader4', 'metatrader5')][string]$App,
        [switch]$Log
    )
    if ($App -eq 'metatrader5') {
        Install-MetaTraderPortableWrapper -AppDir $AppDir -ExeName 'terminal64.exe' -ShortcutName 'MetaTrader 5' -Log:$Log
        Install-MetaTraderPortableWrapper -AppDir $AppDir -ExeName 'MetaEditor64.exe' -Log:$Log
    } else {
        Install-MetaTraderPortableWrapper -AppDir $AppDir -ExeName 'terminal.exe' -ShortcutName 'MetaTrader 4' -Log:$Log
        Install-MetaTraderPortableWrapper -AppDir $AppDir -ExeName 'metaeditor.exe' -Log:$Log
    }
}

#endregion

#region 管理员检查

function Test-AdminElevation {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Assert-AdminElevation {
    param (
        [string]$Reason,
        [string]$InstallHint
    )
    if (Test-AdminElevation) { return }
    $appName = if ($app) { [string]$app } else { 'this app' }
    $hint = if ($InstallHint) { $InstallHint } else { "scoop install $appName" }
    $reasonText = if ($Reason) { $Reason } else { '需要管理员 PowerShell。' }
    Write-Warning @"

${appName} 安装已中止：${reasonText}
请在「以管理员身份运行」的 PowerShell 中执行：
  ${hint}

"@
    throw "${appName}: administrator privileges required."
}

function Test-AdminElevationOrWarn {
    param ([string]$Message)
    if (Test-AdminElevation) { return $true }
    Write-Warning $Message
    return $false
}

#endregion

#region VS Code 系 portable（cursor / codebuddy 等共用）

function Initialize-VscodePortableData {
    param (
        [string]$AppDir,
        [string]$Version,
        [Parameter(Mandatory = $true)]
        [string]$ProfileDir,
        [Parameter(Mandatory = $true)]
        [string]$RoamingAppData,
        [Parameter(Mandatory = $true)]
        [string]$ExtensionsPathPattern
    )
    if (-not $AppDir) { $AppDir = $dir }
    if (-not $Version) { $Version = $version }

    Remove-NsisExtractCrumbs -Path $AppDir

    $dataDir = Join-Path $AppDir 'data'
    $extSrc = Join-Path $ProfileDir 'extensions'
    $extDst = Join-Path $dataDir 'extensions'
    $userDataDst = Join-Path $dataDir 'user-data'
    $argvSrc = Join-Path $ProfileDir 'argv.json'
    $argvDst = Join-Path $dataDir 'argv.json'

    if (!(Test-Path $extDst) -and (Test-RealDirectory -Path $extSrc)) {
        info '[Portable Mode] Copying extensions ...'
        Ensure-FolderExists -Path $dataDir
        Copy-Item $extSrc $dataDir -Recurse -Force
    }
    if (!(Test-Path $userDataDst) -and (Test-RealDirectory -Path $RoamingAppData)) {
        info '[Portable Mode] Copying user data ...'
        Ensure-FolderExists -Path $dataDir
        Copy-Item $RoamingAppData $userDataDst -Recurse -Force
    }

    $extensionsFile = Join-Path $extDst 'extensions.json'
    if (Test-Path $extensionsFile) {
        info 'Adjusting path in extensions.json ...'
        (Get-Content $extensionsFile -Raw) -replace $ExtensionsPathPattern, $Version |
            Set-Content -Path $extensionsFile -NoNewline
    }

    $productPath = Join-Path $AppDir 'resources\app\product.json'
    if (Test-Path $productPath) {
        $productText = [System.IO.File]::ReadAllText($productPath)
        $productPatched = [regex]::Replace($productText, ',\s*\r?\n\s*"target"\s*:\s*"user"(?=\s*\r?\n\})', '')
        if ($productPatched -ne $productText) {
            info '[Portable Mode] Removing "target":"user" from product.json ...'
            [System.IO.File]::WriteAllText($productPath, $productPatched, (New-Object System.Text.UTF8Encoding($false)))
        }
        elseif (($productText | ConvertFrom-Json).PSObject.Properties.Name -contains 'target') {
            warn 'Portable mode may be incomplete: unexpected product.json layout.'
        }
    }

    if (!(Test-Path $argvDst) -and (Test-RealPath -Path $argvSrc) -and (Test-RealDirectory -Path $ProfileDir)) {
        info '[Portable Mode] Copying argv.json ...'
        Ensure-FolderExists -Path $dataDir
        Copy-Item $argvSrc $argvDst -Force
    }
}

#endregion

#region 数据目录映射（内部）

function Expand-MappingPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$AppDir,
        [Parameter(Mandatory = $true)]
        [string]$PersistDir
    )
    if ($Path -match '^AppData/(.+)$') {
        return (Join-Path $env:AppData $matches[1])
    }
    if ($Path -match '^LocalAppData/(.+)$') {
        return (Join-Path $env:LocalAppData $matches[1])
    }
    if ($Path -match '^ProgramData/(.+)$') {
        return (Join-Path $env:ProgramData $matches[1])
    }
    if ($Path -match '^UserProfile/(.+)$') {
        return (Join-Path $env:USERPROFILE $matches[1])
    }
    if ($Path -match '^\$persist_dir(?<rest>[/\\].*)?$') {
        $suffix = $matches['rest']
        if ($suffix) {
            $suffix = ($suffix -replace '^[/\\]+', '') -replace '/', '\'
        }
        return (Join-Path $PersistDir $suffix)
    }
    if ($Path -match '^\$dir(?<rest>[/\\].*)?$') {
        $suffix = $matches['rest']
        if ($suffix) {
            $suffix = ($suffix -replace '^[/\\]+', '') -replace '/', '\'
        }
        return (Join-Path $AppDir $suffix)
    }
    return ($ExecutionContext.InvokeCommand.ExpandString($Path))
}

function Ensure-FolderExists {
    param ([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Move-FolderContentsToPersist {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )
    # 已是联接：内容已在 persist，勿再拷
    if (-not (Test-RealDirectory -Path $Source)) { return }
    Ensure-FolderExists -Path $Destination
    Copy-Item -Path "$Source\*" -Destination $Destination -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path $Source -Force -Recurse -ErrorAction SilentlyContinue
}

function Set-PersistDataLinks {
    param (
        [ValidateSet('Install', 'Uninstall')]
        [Parameter(Mandatory = $true)]
        [string]$Mode,
        [Parameter(Mandatory = $true)]
        [array]$Mappings,
        [Parameter(Mandatory = $true)]
        [string]$AppDir,
        [Parameter(Mandatory = $true)]
        [string]$PersistDir,
        [switch]$Log
    )
    foreach ($mapping in $Mappings) {
        $sourcePath = Expand-MappingPath -Path $mapping.Source -AppDir $AppDir -PersistDir $PersistDir
        $targetPath = Expand-MappingPath -Path $mapping.Target -AppDir $AppDir -PersistDir $PersistDir

        if ($Mode -eq 'Uninstall') {
            Remove-DirectoryLink -LinkPath $sourcePath -Log:$Log
            continue
        }

        if ($mapping.EnsureTarget) {
            Ensure-FolderExists -Path $targetPath
        }

        Move-FolderContentsToPersist -Source $sourcePath -Destination $targetPath
        New-DirectoryLink -LinkPath $sourcePath -TargetPath $targetPath
        if ($Log) {
            info "[Persist] $($mapping.Label): $sourcePath -> $targetPath (Junction)"
        }
    }
}

#endregion

#region 数据目录映射（对外）

function Install-PersistDataLinks {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Mappings,
        [string]$AppDir,
        [string]$PersistDir,
        [switch]$Log
    )
    if (-not $AppDir) { $AppDir = $dir }
    if (-not $PersistDir) { $PersistDir = $persist_dir }
    Set-PersistDataLinks -Mode Install -Mappings $Mappings -AppDir $AppDir -PersistDir $PersistDir -Log:$Log
}

function Uninstall-PersistDataLinks {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Mappings,
        [string]$AppDir,
        [string]$PersistDir,
        [switch]$Log
    )
    if (-not $AppDir) { $AppDir = $dir }
    if (-not $PersistDir) { $PersistDir = $persist_dir }
    Set-PersistDataLinks -Mode Uninstall -Mappings $Mappings -AppDir $AppDir -PersistDir $PersistDir -Log:$Log
}

#endregion
