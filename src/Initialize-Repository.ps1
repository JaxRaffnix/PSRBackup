function Initialize-Repository {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [Parameter()]
        [SecureString]$PasswordSecretName,

        [Parameter()]
        [switch]$Force
    )

    Write-Host "🔧 Initializing Restic repository..." -ForegroundColor Cyan

    Test-Installation -App 'restic'

    if (-not (Test-Path $RepoPath)) {
        New-Item -ItemType Directory -Path $RepoPath -Force | Out-Null
    }

    $configPath = Join-Path $RepoPath "config"
    if (Test-Path $configPath) {
        if ($Force) {
            Write-Host "⚠️  Removing existing Restic repository at '$RepoPath' due to -Force..." -ForegroundColor Yellow
            Remove-Item -Path $RepoPath -Recurse -Force
            New-Item -ItemType Directory -Path $RepoPath -Force | Out-Null
        } else {
            Throw "❌ Restic repository already exists at '$RepoPath'. Use -Force to overwrite."
        }
    }

    # Derive default secret name from repo path if not provided
    if (-not $PasswordSecretName) {
        $PasswordSecretName = "ResticPassword_" + ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($RepoPath)) -replace "[^a-zA-Z0-9]", "")
        Write-Verbose "Derived secret name: $PasswordSecretName"
    }

    $meta = @{
        RepoPath = $RepoPath
        Initialized = (Get-Date).ToString("u")
        SecretName = $PasswordSecretName
    }
    $metaPath = [System.IO.Path]::Combine((Get-Item -Path $RepoPath -Resolve).FullName, ".restic-meta.json")
    $meta | ConvertTo-Json -Depth 10 | Set-Content -Path $metaPath

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

    Write-Host "🗃️ Initializing Restic repository at '$RepoPath'..." -ForegroundColor Cyan
    $originalEnv = $env:RESTIC_PASSWORD
    $env:RESTIC_PASSWORD = $plainPassword

    try {
        & restic init --repo "$RepoPath"
        if ($LASTEXITCODE -ne 0) {
            Throw "❌ Restic init failed with exit code $LASTEXITCODE."
        }
    } finally {
        $plainPassword = $null
        $env:RESTIC_PASSWORD = $originalEnv
        [System.GC]::Collect()
    }

    Write-Host "✅ Repository initialized at '$RepoPath' with secret name '$PasswordSecretName'." -ForegroundColor Green
}
