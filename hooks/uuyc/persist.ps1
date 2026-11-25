$persistMappings = @(
    @{ Label = 'local'; Source = 'LocalAppData/GameViewer'; Target = '$persist_dir/AppData'; EnsureTarget = $true }
    @{ Label = 'programdata'; Source = 'ProgramData/Netease/GameViewer'; Target = '$persist_dir/ProgramData'; EnsureTarget = $true }
)
