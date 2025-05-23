function Initialize-ResticRepo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [Parameter()]
        [SecureString]$PasswordSecretName = "ResticPassword"
    )

    Write-Host "Initializing Restic repository at '$RepoPath'..." -ForegroundColor Cyan

    Save-ResticPassword -Name $PasswordSecretName

    $password = Get-ResticPassword -Name $PasswordSecretName

    # Check if repo already exists
    if (Test-Path "$RepoPath\config") {
        Throw "Restic repository already exists at '$RepoPath'."
    }

    # Create repository
    $env:RESTIC_PASSWORD = $password
    restic init --repo "$RepoPath"
    Remove-Item Env:RESTIC_PASSWORD

    Write-Host "Restic repository successfully initialized at '$RepoPath'." -ForegroundColor Green
}
