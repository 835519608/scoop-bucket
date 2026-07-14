$ErrorActionPreference = 'Stop'

function Get-GitHubRepo {
    param([object]$Manifest)

    $sources = @(
        $Manifest.homepage,
        $Manifest.architecture.'64bit'.url,
        $Manifest.autoupdate.architecture.'64bit'.url
    ) | Where-Object { $_ }

    foreach ($source in $sources) {
        if ($source -match 'github\.com/(?<owner>[^/]+)/(?<repo>[^/#?]+)') {
            return "$($Matches.owner)/$($Matches.repo -replace '\.git$', '')"
        }
    }

    throw 'cannot infer GitHub repository'
}

function Invoke-WithRetry {
    param(
        [scriptblock]$Action,
        [int]$Attempts = 3,
        [int]$DelaySeconds = 5
    )

    $lastError = $null
    for ($i = 1; $i -le $Attempts; $i++) {
        try {
            return & $Action
        } catch {
            $lastError = $_
            if ($i -eq $Attempts) {
                throw
            }

            Write-Warning ("Attempt {0}/{1} failed: {2}. Retrying in {3}s..." -f $i, $Attempts, $_.Exception.Message, $DelaySeconds)
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    throw $lastError
}

function Invoke-GitHubLatest {
    param([string]$Repo)

    $headers = @{
        'Accept' = 'application/vnd.github+json'
    }

    if ($env:GITHUB_TOKEN) {
        $headers.Authorization = "Bearer $env:GITHUB_TOKEN"
        $headers.'X-GitHub-Api-Version' = '2022-11-28'
    }

    Invoke-WithRetry -Action {
        Invoke-RestMethod -Headers $headers -TimeoutSec 30 -Uri "https://api.github.com/repos/$Repo/releases/latest"
    }
}

function Invoke-CheckverUrl {
    param([string]$Uri)

    Invoke-WithRetry -Action {
        (Invoke-WebRequest -UseBasicParsing -TimeoutSec 30 -Uri $Uri).Content
    }
}

function Assert-RegexMatch {
    param(
        [string]$App,
        [string]$InputText,
        [string]$Regex
    )

    $match = [regex]::Match($InputText, $Regex)
    if (-not $match.Success) {
        throw "couldn't match '$Regex'"
    }

    if ($match.Groups['version'].Success) {
        Write-Output "$App`: matched version $($match.Groups['version'].Value)"
    } else {
        Write-Output "$App`: matched checkver pattern"
    }
}

$failures = @()

foreach ($file in Get-ChildItem -Path 'bucket' -Filter '*.json' | Sort-Object Name) {
    $app = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $manifest = Get-Content -Raw -Path $file.FullName | ConvertFrom-Json
    $checkver = $manifest.checkver

    if (-not $checkver) {
        continue
    }

    try {
        if ($checkver -is [string]) {
            if ($checkver -ne 'github') {
                throw "unsupported string checkver '$checkver'"
            }

            $repo = Get-GitHubRepo -Manifest $manifest
            $release = Invoke-GitHubLatest -Repo $repo
            $version = $release.tag_name -replace '^v', ''

            if (-not $version) {
                throw "GitHub latest release for $repo has no tag_name"
            }

            Write-Output "$app`: github latest $version"
            continue
        }

        if ($checkver.url -and $checkver.regex) {
            $content = Invoke-CheckverUrl -Uri $checkver.url
            Assert-RegexMatch -App $app -InputText $content -Regex $checkver.regex
            continue
        }

        if ($checkver.script -and $checkver.regex) {
            $script = [scriptblock]::Create(($checkver.script -join "`n"))
            $content = & $script
            Assert-RegexMatch -App $app -InputText $content -Regex $checkver.regex
            continue
        }

        throw 'unsupported checkver shape'
    } catch {
        $failures += "$app`: $($_.Exception.Message)"
    }
}

if ($failures.Count -gt 0) {
    Write-Error ($failures -join "`n")
    exit 1
}
