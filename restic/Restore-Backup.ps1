function Restore-Backup {
    <#
    .SYNOPSIS
        Restores a backup from a restic repository to a specified target directory.

    .DESCRIPTION
        The Restore-Backup function restores files from a restic backup repository to a given target path.
        It supports specifying a particular snapshot ID to restore, or defaults to the latest snapshot.
        If the target directory does not exist, it will be created.
        

    .PARAMETER RepoPath
        [string] The file system path to the restic repository from which to restore the backup. Mandatory parameter.

    .PARAMETER TargetPath
        [string] The destination directory where the backup will be restored. If it does not exist, it will be created.

    .PARAMETER SnapshotId
        [string] (Optional) The ID of the snapshot to restore. Defaults to "latest" if not specified.

    .PARAMETER Key
        [string] (Optional) The SecretManagement key used to get the restic repository password. If not provided, it will be derived automatically.

    .EXAMPLE
        Restore-Backup -RepoPath "D:\Backups\MyRepo" -TargetPath "C:\Restore"

        Restores the latest snapshot from the specified repository to the target directory.
    #>

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
    Set-ResticEnvironment -RepoPath $RepoPath -Key $Key -Silent

    try {
        if (-not (Test-Path $TargetPath)) {
            New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
        }

        & restic restore $SnapshotId --target $TargetPath 
        if ($LASTEXITCODE -ne 0) {
            Throw "❌ Restic restore failed with exit code $LASTEXITCODE."
        }
    } finally {
        Reset-ResticEnvironment -Silent
    }

    Write-Host "✅ Restore completed." -ForegroundColor Green
}
