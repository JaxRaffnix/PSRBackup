function Restore-ResticBackup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [Parameter(Mandatory)]
        [string]$TargetPath,

        [Parameter()]
        [string]$SnapshotId = "latest",

        [Parameter()]
        [string]$SubPath = ".",

        [Parameter()]
        [SecureString]$PasswordSecretName
    )

    Write-Host "🔄 Restoring backup from '$RepoPath' to '$TargetPath'..." -ForegroundColor Cyan
    Write-Host "  ├─ Snapshot ID: $SnapshotId"
    Write-Host "  ├─ Subpath: $SubPath"
    Write-Host "  └─ Target path: $TargetPath"

    Test-Installation -App 'restic'

    # Derive secret name if not provided
    if (-not $PasswordSecretName) {
        $PasswordSecretName = "ResticPassword_" + ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($RepoPath)) -replace "[^a-zA-Z0-9]", "")
        Write-Verbose "Derived secret name: $PasswordSecretName"
    }

    # Retrieve password
    try {
        $securePassword = Get-ResticPassword -Name $PasswordSecretName
        $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        )
    } catch {
        Throw "❌ Could not retrieve restic password: $_"
    }

    # Set environment variable
    $originalEnv = $env:RESTIC_PASSWORD
    $env:RESTIC_PASSWORD = $plainPassword

    try {
        # Create target directory if necessary
        if (-not (Test-Path $TargetPath)) {
            New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
        }

        # Run restore
        $restoreArgs = @(
            'restore', $SnapshotId,
            '--repo', $RepoPath,
            '--target', $TargetPath,
            '--path', $SubPath
        )
        & restic @restoreArgs

        if ($LASTEXITCODE -ne 0) {
            Throw "❌ Restic restore failed with exit code $LASTEXITCODE."
        }
    } finally {
        # Clear env var and password
        $env:RESTIC_PASSWORD = $originalEnv
        $plainPassword = $null
        [System.GC]::Collect()
    }

    Write-Host "✅ Restore completed to '$TargetPath'." -ForegroundColor Green
}
