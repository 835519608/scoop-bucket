# 路径依据 src-tauri/src/lib.rs：app.path().app_data_dir()、app.path().data_dir()
# identifier：src-tauri/tauri.conf.json → com.snowautumn.moor
$moorMappings = @(
    @{ Label = 'data'; Source = 'AppData/com.snowautumn.moor'; Target = '$persist_dir/data'; EnsureTarget = $true }
    @{ Label = 'local'; Source = 'LocalAppData/com.snowautumn.moor'; Target = '$persist_dir/local'; EnsureTarget = $true }
)
Install-PersistDataLinks -Mappings $moorMappings -Log:$true
Clear-DesktopShortcuts -Filter '*Moor*.lnk'
