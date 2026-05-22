$mcpMappings = @(@{ Label = 'roaming'; Source = 'AppData/MCP Router'; Target = '$persist_dir/roaming'; EnsureTarget = $true })
Install-PersistDataLinks -Mappings $mcpMappings -Log:$true
