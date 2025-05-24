function Initialize-Repository {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [string]$Key,
        [switch]$Force
    )

    Write-Host "🚀 Initializing restic repository..." -ForegroundColor Cyan
    if ($Key) {Write-Host "  ├─ Password key: '$Key'"}
    if ($Force) {Write-Host "  ├─ Force: $Force"}
    Write-Host "  └─ Repository path: '$RepoPath'"

    Test-Installation -App 'restic'

    if (-not (Test-Path $RepoPath)) {
        New-Item -ItemType Directory -Path $RepoPath -Force | Out-Null
    }

    if (Test-Path (Join-Path -Path $RepoPath -ChildPath "config")) {
        if ($Force) {
            Write-Warning "⚠️ Removing existing Restic repository at '$RepoPath' due to -Force..."
            Remove-Item -Path $RepoPath -Recurse -Force
            New-Item -ItemType Directory -Path $RepoPath -Force | Out-Null
        } else {
            Throw "❌ Restic repository already exists at '$RepoPath'. Use -Force to overwrite."
        }
    }

    if (-not $Key) {
        $Key = Get-DerivedKey -RepoPath $RepoPath
    }
    Set-ResticPassword -Name $Key -Force:$Force
    Register-KeyMapping -RepoPath $RepoPath -Key $Key
    Set-ResticEnvironment -RepoPath $RepoPath -Key $Key

    try {
        & restic init 
        if ($LASTEXITCODE -ne 0) {
            Throw "❌ Restic init failed with exit code $LASTEXITCODE."
        }
    } finally {
        Reset-ResticEnvironment
    }

    Write-Host "✅ Repository initialized." -ForegroundColor Green
}


function Register-KeyMapping {
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [Parameter(Mandatory)]
        [string]$Key,

        [string]$LogPath = "$env:LOCALAPPDATA\restic-repo-info.json"
    )

    $repoKey = [System.IO.Path]::GetFileName($RepoPath.TrimEnd('\', '/'))

    Write-Host "📝 Registering password key for restic repository..." -ForegroundColor Cyan
    Write-Host "  ├─ Repository name: '$repoKey'"
    Write-Host "  ├─ Repository path: '$RepoPath'"
    Write-Host "  ├─ Key: '$Key'"
    Write-Host "  └─ Log path: '$LogPath'"

    if (-not (Test-Path $LogPath)) {
        '{}' | Out-File -Encoding UTF8 -FilePath $LogPath
    }

    try {
        $json = Get-Content $LogPath -Raw | ConvertFrom-Json
    } catch {
        Throw "❌ Failed to read JSON log at '$LogPath': $_"
    }


    $repoInfo = [PSCustomObject]@{
        path      = $RepoPath
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        key    = @{
            name  = $Key
            vault = (Get-SecretVault | Where-Object { $_.IsDefault }).Name
        }
    }

    if ($json.PSObject.Properties.Name -notcontains $repoKey) {
        $json | Add-Member -MemberType NoteProperty -Name $repoKey -Value $repoInfo
    } else {
        $json.$repoKey = $repoInfo
    }

    $json | ConvertTo-Json -Depth 3 | Set-Content -Encoding UTF8 -Path $LogPath

    Write-Host "✅ Logged password key to logfile." -ForegroundColor Green
}
