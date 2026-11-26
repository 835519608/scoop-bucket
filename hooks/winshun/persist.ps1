# Kept only so uninstall can tear down the old LocalAppData junction from earlier bucket versions.
# Official / current install uses Scoop persist `data` only (portable beside the exe).
$persistMappings = @(
    @{ Label = 'local'; Source = 'LocalAppData/WinShun'; Target = '$persist_dir/LocalAppData'; EnsureTarget = $true }
)
