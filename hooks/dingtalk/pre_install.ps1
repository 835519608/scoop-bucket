# Official installer is 7z-compatible: app under build\dist, launcher under build\updater
New-Item -ItemType Directory -Path "$dir\main\current" -Force | Out-Null
if (Test-Path "$dir\build\dist") {
    Move-Item "$dir\build\dist\*" "$dir\main\current" -Force
}
if (Test-Path "$dir\build\updater") {
    Move-Item "$dir\build\updater\*" $dir -Force
}
Remove-Item "$dir\uninst.exe", "$dir\DingTalkUpdater.exe" -Force -ErrorAction SilentlyContinue
Remove-Item "$dir\build", "$dir\`$PLUGINSDIR" -Recurse -Force -ErrorAction SilentlyContinue
