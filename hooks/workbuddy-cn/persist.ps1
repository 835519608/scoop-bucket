# 国内版 dataFolderName=.workbuddy（国际版为 .workbuddy-ai）
# CodeBuddy IDE 的 .codebuddycn / AppData 由 codebuddy-cn 管理，勿在此联接
$persistMappings = @(
    @{ Label = 'profile'; Source = 'UserProfile/.workbuddy'; Target = '$persist_dir/.workbuddy'; EnsureTarget = $true }
    @{ Label = 'roaming'; Source = 'AppData/WorkBuddy'; Target = '$persist_dir/AppData'; EnsureTarget = $true }
)
