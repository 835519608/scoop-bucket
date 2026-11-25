$persistMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/DingTalk'; Target = '$persist_dir/AppData'; EnsureTarget = $true }
    @{ Label = 'dinglive'; Source = 'AppData/dinglive'; Target = '$persist_dir/dinglive'; EnsureTarget = $true }
    @{ Label = 'local91'; Source = 'LocalAppData/DingTalk_91'; Target = '$persist_dir/DingTalk_91'; EnsureTarget = $true }
    @{ Label = 'local108'; Source = 'LocalAppData/DingTalk_108'; Target = '$persist_dir/DingTalk_108'; EnsureTarget = $true }
    @{ Label = 'local133'; Source = 'LocalAppData/DingTalk_133'; Target = '$persist_dir/DingTalk_133'; EnsureTarget = $true }
)
