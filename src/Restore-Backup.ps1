function Restore-Backup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [Parameter(Mandatory)]
        [string]$TargetPath,

        [string]$SnapshotId = "latest",
        [string]$Key
    )

    Write-Host "♻️ Restoring backup..." -ForegroundColor Cyan
    Write-Host "  ├─ Repository path: '$RepoPath'"
    Write-Host "  ├─ Target path: '$TargetPath'"
    if ($Key) {Write-Host "  ├─ Password secret name: '$Key'"}
    Write-Host "  └─ Snapshot ID: '$SnapshotId'"
    
    Test-Installation -App 'restic'

    if (-not $Key) {
        $Key = Get-DerivedKey -RepoPath $RepoPath
    }
    Set-ResticEnvironment -RepoPath $RepoPath -Key $Key

    try {
        if (-not (Test-Path $TargetPath)) {
            New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
        }

        & restic restore $SnapshotId --target $TargetPath 
        if ($LASTEXITCODE -ne 0) {
            Throw "❌ Restic restore failed with exit code $LASTEXITCODE."
        }
    } finally {
        Reset-ResticEnvironment
    }

    Write-Host "✅ Restore completed." -ForegroundColor Green
}
