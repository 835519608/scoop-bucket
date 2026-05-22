Clear-DesktopShortcuts -Filter '*DBX*.lnk'
$dbxMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/com.dbx.app'; Target = '$persist_dir/roaming'; EnsureTarget = $true }
    @{ Label = 'local'; Source = 'LocalAppData/com.dbx.app'; Target = '$persist_dir/local'; EnsureTarget = $true }
    @{ Label = 'profile'; Source = 'UserProfile/.dbx'; Target = '$persist_dir/.dbx'; EnsureTarget = $true }
)
Install-PersistDataLinks -Mappings $dbxMappings
