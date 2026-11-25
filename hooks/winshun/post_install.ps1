$winshunMappings = @(
    @{ Label = 'local'; Source = 'LocalAppData/WinShun'; Target = '$persist_dir/LocalAppData'; EnsureTarget = $true }
)
Install-PersistDataLinks -Mappings $winshunMappings -Log:$true

Clear-DesktopShortcuts -Filter 'WinShun*.lnk'
Clear-StartMenuShortcuts -Filter 'WinShun*.lnk'
Get-ChildItem -Path @(
    (Join-Path $env:USERPROFILE 'Desktop')
    (Join-Path $env:PUBLIC 'Desktop')
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs')
    (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs')
) -Filter '*.lnk' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.BaseName -match 'WinShun|Win顺' -and $_.DirectoryName -notmatch '\\Scoop Apps$' } |
    Remove-Item -Force -ErrorAction SilentlyContinue
