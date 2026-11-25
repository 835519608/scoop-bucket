Get-Process -Name 'terminal64', 'metaeditor64', 'metatester64', 'terminal' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

# Keep multi-account clones under persist\metatrader5-instances
info '[metatrader5] Leaving persist\metatrader5-instances intact (if present)'
