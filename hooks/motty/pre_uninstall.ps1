# 旧版（AppData 联接方案）的 manifest 仍会调用此路径；升级/卸载时必须存在。
# 便携 persist 方案下若未建联接，Uninstall-PersistDataLinks 为无操作。
$mottyMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/motty'; Target = '$persist_dir/roaming' }
)
Uninstall-PersistDataLinks -Mappings $mottyMappings
