# 国内版 dataFolderName=.workbuddy（国际版为 .workbuddy-ai，勿混用）
$workbuddyCnMappings = @(
    @{ Label = 'profile'; Source = 'UserProfile/.workbuddy'; Target = '$persist_dir/.workbuddy'; EnsureTarget = $true }
    @{ Label = 'codebuddy'; Source = 'UserProfile/.codebuddy'; Target = '$persist_dir/.codebuddy'; EnsureTarget = $true }
    @{ Label = 'extension'; Source = 'LocalAppData/CodeBuddyExtension'; Target = '$persist_dir/CodeBuddyExtension'; EnsureTarget = $true }
)
Install-PersistDataLinks -Mappings $workbuddyCnMappings -Log:$true
Clear-DesktopShortcuts -Filter 'WorkBuddy*.lnk'
Clear-StartMenuShortcuts -Filter 'WorkBuddy*.lnk'
