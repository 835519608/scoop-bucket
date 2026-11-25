$steamMappings = @(
    @{ Label = 'local'; Source = 'LocalAppData/Steam'; Target = '$persist_dir/LocalAppData'; EnsureTarget = $true }
)
Install-PersistDataLinks -Mappings $steamMappings -Log:$true

Clear-DesktopShortcuts -Filter 'Steam*.lnk'
Clear-StartMenuShortcuts -Filter 'Steam*.lnk'
Get-ChildItem -Path @(
    (Join-Path $env:USERPROFILE 'Desktop')
    (Join-Path $env:PUBLIC 'Desktop')
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs')
    (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs')
) -Filter '*.lnk' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.BaseName -match '^Steam' -and $_.DirectoryName -notmatch '\\Scoop Apps$' } |
    Remove-Item -Force -ErrorAction SilentlyContinue
