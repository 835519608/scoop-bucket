$ErrorActionPreference = 'Stop'

$output = & scoop checkver --all 2>&1
$exitCode = $LASTEXITCODE
$text = ($output | ForEach-Object { $_.ToString() }) -join "`n"

Write-Output $text

if ($exitCode -ne 0) {
    throw "scoop checkver --all failed with exit code $exitCode"
}

$failurePattern = "(?i)(couldn't match|could not|failed|failure|exception|error)"

if ($text -match $failurePattern) {
    throw "scoop checkver --all reported at least one checkver failure"
}
