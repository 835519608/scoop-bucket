$mcpMappings = @(@{ Label = 'roaming'; Source = 'AppData/MCP Router'; Target = '$persist_dir/roaming' })
Uninstall-PersistDataLinks -Mappings $mcpMappings -Log:$true
