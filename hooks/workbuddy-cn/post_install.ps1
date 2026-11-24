# 国内版 dataFolderName=.workbuddy（国际版为 .workbuddy-ai）
# CodeBuddy IDE 的 .codebuddycn / AppData 由 codebuddy-cn 管理，勿在此联接
# 对齐 sdoog：同时联接 %APPDATA%\WorkBuddy（若日后写入）
$workbuddyCnMappings = @(
    @{ Label = 'profile'; Source = 'UserProfile/.workbuddy'; Target = '$persist_dir/.workbuddy'; EnsureTarget = $true }
    @{ Label = 'roaming'; Source = 'AppData/WorkBuddy'; Target = '$persist_dir/AppData'; EnsureTarget = $true }
)
Install-PersistDataLinks -Mappings $workbuddyCnMappings -Log:$true
Clear-DesktopShortcuts -Filter 'WorkBuddy*.lnk'
Clear-StartMenuShortcuts -Filter 'WorkBuddy*.lnk'
