function Initialize-Repository {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [SecureString]$PasswordSecretName,
        [switch]$Force
    )

    Write-Host "🚀 Initializing restic repository..." -ForegroundColor Cyan
    if ($PasswordSecretName) {Write-Host "  ├─ Password secret name: $PasswordSecretName"}
    if ($Force) {Write-Host "  ├─ Force: $Force"}
    Write-Host "  └─ Repository path: $RepoPath"

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

    Log-SecretName -RepoPath $RepoPath -SecretName $PasswordSecretName

    Write-Host "🔐 Saving password to SecretVault with name '$PasswordSecretName'..."
    Save-ResticPassword -Name $PasswordSecretName

    try {
        $securePassword = Get-ResticPassword -Name $PasswordSecretName
        $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        )
    } catch {
        Throw "❌ Could not retrieve restic password: $_"
    }

    Set-ResticEnvironment -Password $plainPassword

    try {
        & restic init --repo "$RepoPath"
        if ($LASTEXITCODE -ne 0) {
            Throw "❌ Restic init failed with exit code $LASTEXITCODE."
        }
    } finally {
        Reset-ResticEnvironment
    }

    Write-Host "✅ Repository initialized at '$RepoPath' with secret name '$PasswordSecretName'." -ForegroundColor Green
}
function Log-SecretName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [Parameter(Mandatory)]
        [string]$SecretName
    )

    $logFile = Join-Path $PSScriptRoot "initialized-repos.txt"
    $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
    $entry = @{
        Timestamp = $timestamp
        RepoPath  = $RepoPath
        Secret    = $SecretName
    } | ConvertTo-Json -Compress

    try {
        Add-Content -Path $logFile -Value $entry
        Write-Host "🔑 Secret name logged to '$logFile'."
    } catch {
        Throw "❌ Failed to log secret name: $_"
    }
}
