Get-Process -Name 'DingTalk*', 'DingTalkLauncher', 'DingtalkScheme', 'DingTalkApp' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

$dingtalkMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/DingTalk'; Target = '$persist_dir/AppData' }
    @{ Label = 'dinglive'; Source = 'AppData/dinglive'; Target = '$persist_dir/dinglive' }
    @{ Label = 'local91'; Source = 'LocalAppData/DingTalk_91'; Target = '$persist_dir/DingTalk_91' }
    @{ Label = 'local108'; Source = 'LocalAppData/DingTalk_108'; Target = '$persist_dir/DingTalk_108' }
    @{ Label = 'local133'; Source = 'LocalAppData/DingTalk_133'; Target = '$persist_dir/DingTalk_133' }
)
Uninstall-PersistDataLinks -Mappings $dingtalkMappings -Log:$true
