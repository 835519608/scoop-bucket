$ErrorActionPreference = 'Stop'

$candidates = @(
    $(if ($env:SCOOP) { Join-Path $env:SCOOP 'shims\scoop.ps1' }),
    $(if ($env:SCOOP) { Join-Path $env:SCOOP 'shims\scoop.cmd' }),
    $(if ($env:SCOOP_HOME) { Join-Path $env:SCOOP_HOME 'bin\scoop.ps1' })
) | Where-Object { $_ -and (Test-Path $_) }

$scoop = $candidates | Select-Object -First 1

if (-not $scoop) {
    $command = Get-Command scoop -ErrorAction SilentlyContinue
    if ($command) {
        $scoop = $command.Source
    }
}

if (-not $scoop) {
    throw 'scoop executable not found after ScoopInstaller/GithubActions setup'
}

Write-Output "Using scoop: $scoop"

$output = & $scoop checkver --all 2>&1
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
