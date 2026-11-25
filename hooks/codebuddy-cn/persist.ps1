$persistMappings = @(
    @{ Label = 'profile-cli'; Source = 'UserProfile/.codebuddy'; Target = '$persist_dir/.codebuddy'; EnsureTarget = $true }
    @{ Label = 'roaming'; Source = 'AppData/CodeBuddy CN'; Target = '$persist_dir/roaming'; EnsureTarget = $true }
    @{ Label = 'local'; Source = 'LocalAppData/CodeBuddy CN'; Target = '$persist_dir/local'; EnsureTarget = $true }
)
