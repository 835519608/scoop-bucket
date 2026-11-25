Get-Process -Name 'terminal', 'metaeditor', 'terminal64', 'metaeditor64' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

info '[metatrader4] Leaving persist\metatrader4-instances intact (if present)'
