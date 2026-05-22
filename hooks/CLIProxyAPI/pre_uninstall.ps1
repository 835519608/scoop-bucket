$cliProxyMappings = @(@{ Label = 'auth'; Source = 'UserProfile/.cli-proxy-api'; Target = '$persist_dir/auth' })
Uninstall-PersistDataLinks -Mappings $cliProxyMappings
