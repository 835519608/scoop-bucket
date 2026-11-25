$persistMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/Netease/UU'; Target = '$persist_dir/AppData'; EnsureTarget = $true }
    @{ Label = 'local'; Source = 'LocalAppData/Netease/UU'; Target = '$persist_dir/LocalAppData'; EnsureTarget = $true }
    @{ Label = 'programdata'; Source = 'ProgramData/Netease/UU'; Target = '$persist_dir/ProgramData'; EnsureTarget = $true }
)
