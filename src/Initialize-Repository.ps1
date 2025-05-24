function Initialize-Repository {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [string]$PasswordSecretName,
        [switch]$Force
    )

    Write-Host "🚀 Initializing restic repository..." -ForegroundColor Cyan
    if ($PasswordSecretName) {Write-Host "  ├─ Password secret name: '$PasswordSecretName'"}
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

    if (-not $PasswordSecretName) {
        $PasswordSecretName = Get-DerivedSecretName -RepoPath $RepoPath
    }

    Write-Host "🔐 Saving password to SecretVault with name '$PasswordSecretName'..."
    Create-ResticPassword -Name $PasswordSecretName -Force:$Force
    
    Register-ResticSecretInfo -RepoPath $RepoPath -SecretName $PasswordSecretName

    Set-ResticEnvironment -RepoPath $RepoPath -PasswordSecretName $PasswordSecretName

    try {
        & restic init 
        if ($LASTEXITCODE -ne 0) {
            Throw "❌ Restic init failed with exit code $LASTEXITCODE."
        }
    } finally {
        Reset-ResticEnvironment
    }

    Write-Host "✅ Repository initialized at '$RepoPath' with secret name." -ForegroundColor Green
}
function Register-ResticSecretInfo {
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [Parameter(Mandatory)]
        [string]$SecretName,

        [string]$LogPath = "$env:LOCALAPPDATA\restic-repo-map.json"
    )

    Write-Host "📝 Registering restic secret info..." -ForegroundColor Cyan
    Write-Host "  ├─ Repository path: '$RepoPath'"
    Write-Host "  ├─ Secret name: '$SecretName'"
    Write-Host "  └─ Log path: '$LogPath'"

    if (-not (Test-Path $LogPath)) {
        # Create an empty JSON object if it doesn't exist
        '{}' | Out-File -Encoding UTF8 -FilePath $LogPath
    }

    try {
        $json = Get-Content $LogPath -Raw | ConvertFrom-Json
    } catch {
        Throw "❌ Failed to read JSON log at '$LogPath': $_"
    }

    $repoKey = [System.IO.Path]::GetFileName($RepoPath.TrimEnd('\', '/'))

    $json.$repoKey = @{
        path      = $RepoPath
        timestamp = (Get-Date).ToString("o")
        secret    = $SecretName
    }

    # Save the updated JSON
    $json | ConvertTo-Json -Depth 3 | Set-Content -Encoding UTF8 -Path $LogPath

    Write-Host "✅ Logged restic secret info for '$repoKey' to '$LogPath'." -ForegroundColor Green
}
