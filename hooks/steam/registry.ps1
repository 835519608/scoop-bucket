# Steam 官方安装会在 HKLM 写 InstallPath，并给 Users FullControl（客户端/服务用）。
# Scoop #/dl.7z 不解压安装器，需在此补齐，否则启动报 “registry path is currently not writable”。

function Set-SteamMachineRegistry {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InstallDir
    )

    $installDir = $InstallDir.TrimEnd('\')
    $hkcu = 'HKCU:\Software\Valve\Steam'
    if (-not (Test-Path 'HKCU:\Software\Valve')) {
        New-Item -Path 'HKCU:\Software\Valve' -Force | Out-Null
    }
    if (-not (Test-Path $hkcu)) {
        New-Item -Path $hkcu -Force | Out-Null
    }
    New-ItemProperty -Path $hkcu -Name 'SteamPath' -Value ($installDir -replace '\\', '/') -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $hkcu -Name 'SteamExe' -Value (($installDir -replace '\\', '/') + '/steam.exe') -PropertyType String -Force | Out-Null

    if (-not (Test-AdminElevation)) {
        Write-Warning @'
Steam 需要写入 HKLM\SOFTWARE\WOW6432Node\Valve\Steam（InstallPath + Users 可写 ACL）。
当前非管理员，无法完成注册表修复。请在「以管理员身份运行」的 PowerShell 中执行：
  scoop uninstall steam
  scoop install scoop-bucket/steam
或关闭 Steam 后，以管理员运行下方修复脚本。
'@
        return $false
    }

    $users = New-Object System.Security.Principal.NTAccount('BUILTIN', 'Users')
    $fullRule = New-Object System.Security.AccessControl.RegistryAccessRule(
        $users,
        [System.Security.AccessControl.RegistryRights]::FullControl,
        [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit,
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AccessControlType]::Allow
    )

    foreach ($parent in @(
            'HKLM:\SOFTWARE\WOW6432Node\Valve'
            'HKLM:\SOFTWARE\Valve'
        )) {
        if (-not (Test-Path $parent)) {
            New-Item -Path $parent -Force | Out-Null
        }
        $parentAcl = Get-Acl -Path $parent
        $parentAcl.SetAccessRule($fullRule)
        Set-Acl -Path $parent -AclObject $parentAcl
    }

    $hklmPaths = @(
        'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam'
        'HKLM:\SOFTWARE\Valve\Steam'
    )
    foreach ($regPath in $hklmPaths) {
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        New-ItemProperty -Path $regPath -Name 'InstallPath' -Value $installDir -PropertyType String -Force | Out-Null

        $acl = Get-Acl -Path $regPath
        $acl.SetAccessRule($fullRule)
        Set-Acl -Path $regPath -AclObject $acl
        info "[steam] Registry $regPath InstallPath=$installDir (Users FullControl)"
    }

    $svc = Join-Path $installDir 'bin\SteamService.exe'
    if (Test-Path -LiteralPath $svc) {
        Start-Process -FilePath $svc -ArgumentList '/Install' -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
    }
    return $true
}
