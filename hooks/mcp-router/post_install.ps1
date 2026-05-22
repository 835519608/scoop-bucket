$mcpMappings = @(@{ Label = 'roaming'; Source = 'AppData/MCP Router'; Target = '$persist_dir/roaming'; EnsureTarget = $true })
Install-PersistDataLinks -Mappings $mcpMappings -Log:$true

# 清理旧版 bucket 可能留下的启动器 / WMI / 计划任务
foreach ($name in @('mcp-router.vbs', 'mcp-router.cmd', 'mcp-router-launch.ps1')) {
    Remove-Item -LiteralPath (Join-Path $dir $name) -Force -ErrorAction SilentlyContinue
}
schtasks.exe /Delete /TN scoop-mcp-router-no-autostart /F 2>$null | Out-Null
$wmiFilter = 'Scoop_McpRouter_ProcessStart'
$wmiConsumer = 'Scoop_McpRouter_DisableAutostart'
$wmiNs = 'root\subscription'
$filter = Get-WmiObject -Namespace $wmiNs -Class __EventFilter -Filter "Name='$wmiFilter'" -ErrorAction SilentlyContinue
$consumer = Get-WmiObject -Namespace $wmiNs -Class CommandLineEventConsumer -Filter "Name='$wmiConsumer'" -ErrorAction SilentlyContinue
if ($filter -and $consumer) {
    Get-WmiObject -Namespace $wmiNs -Class __FilterToConsumerBinding -ErrorAction SilentlyContinue |
        Where-Object { $_.Filter -eq $filter.__RELPATH -and $_.Consumer -eq $consumer.__RELPATH } |
        ForEach-Object { $_.Delete() }
    $filter.Delete()
    $consumer.Delete()
}
