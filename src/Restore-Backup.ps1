function Restore-ResticBackup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [Parameter(Mandatory)]
        [string]$TargetPath,

        [string]$SnapshotId = "latest",
        [string]$SubPath = ".",
        [SecureString]$PasswordSecretName
    )

    Write-Host "🔄 Restoring backup..." -ForegroundColor Cyan
    Write-Host "  ├─ Repository path: $RepoPath"
    Write-Host "  └─ Target path: $TargetPath"
    if ($PasswordSecretName) {Write-Host "  ├─ Password secret name: $PasswordSecretName"}
    Write-Host "  ├─ Snapshot ID: $SnapshotId"
    Write-Host "  └─ Subpath: $SubPath"
    
    Test-Installation -App 'restic'

    if (-not $PasswordSecretName) {
        $PasswordSecretName = Get-DerivedSecretName -RepoPath $RepoPath
    }

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
        if (-not (Test-Path $TargetPath)) {
            New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
        }

        & restic restore $SnapshotId --repo $RepoPath --target $TargetPath --path $SubPath
        if ($LASTEXITCODE -ne 0) {
            Throw "❌ Restic restore failed with exit code $LASTEXITCODE."
        }
    } finally {
        Reset-ResticEnvironment
    }

    Write-Host "✅ Restore completed to '$TargetPath'." -ForegroundColor Green
}
