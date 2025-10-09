function Start-Backup {
    <#
    .SYNOPSIS
        Performs a backup of files from a source directory to a restic repository with optional exclusions and size checks.

    .DESCRIPTION
        The Start-Backup function automates the process of backing up files from a specified source path to a restic repository.
        It supports exclusion of files via an exclude file, enforces maximum file and folder size limits, and manages restic environment variables.
        The function also performs post-backup maintenance tasks such as pruning old snapshots, cleaning the cache, and verifying backup integrity.

    .PARAMETER RepoPath
        The file system path to the restic repository. Must already exist and contain a 'config' file. Mandatory parameter.

    .PARAMETER SourcePath
        The file system path to the directory or files to be backed up. Mandatory parameter.

    .PARAMETER ExcludeFile
        Path to a file containing patterns of files/folders to exclude from the backup. Defaults to '..\config\restic-exclude.txt' relative to the script root.

    .PARAMETER Key
        The SecretManagement key to get the repository password. If not provided, it is derived automatically.

    .PARAMETER MaxFileSize
        The maximum allowed size (in bytes) for any single file in the source directory. Defaults to 100MB.

    .PARAMETER MaxFolderSize
        The maximum allowed total size (in bytes) for the source directory. Defaults to 10GB.

    .EXAMPLE
        Start-Backup -RepoPath "D:\Backups\ResticRepo" -SourcePath "C:\Users\Jax\Documents"

        Performs a backup of the Documents folder to the specified restic repository using default exclusion and size settings.

    .EXAMPLE
        Start-Backup -RepoPath "D:\Backups\ResticRepo" -SourcePath "C:\Data" -ExcludeFile "C:\Backup\restic-exclude.txt" -Key "MySecret" -MaxFileSize 500MB -MaxFolderSize 50GB

        Backs up the Data folder, using a custom exclude file and secret, with increased file and folder size limits.

    .NOTES
        - Requires restic to be installed and available in the system PATH.
        - Performs snapshot pruning, cache cleanup, and integrity checking after backup.
#>

    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [Parameter(Mandatory)]
        [string]$SourcePath,

        [string]$ExcludeFile = "$PSScriptRoot\..\config\restic-exclude.txt",

        [string]$Key,

        [int64]$MaxFileSize = 100MB,
        [int64]$MaxFolderSize = 10GB
    )

    Write-Host "📦 Backing up files..." -ForegroundColor Cyan
    if ($ExcludeFile) {Write-Host "  ├─ Exclude file: '$ExcludeFile'"}   
    if ($Key) {Write-Host "  ├─ Password secret name: '$Key'"}  
    Write-Host "  ├─ Repository path: '$RepoPath'"
    Write-Host "  └─ Source path: '$SourcePath'"
    
    Test-Installation -App 'restic'

    if (-not (Test-Path "$RepoPath\config")) {
        Throw "❌ Restic repository does not exist at '$RepoPath'."
    }

    if (-not (Test-Path $SourcePath)) {
        Throw "❌ Source path '$SourcePath' does not exist."
    }

    if ($ExcludeFile -and -not (Test-Path $ExcludeFile)) {
        Throw "❌ Exclude file '$ExcludeFile' not found."
    }

    try {
        Test-BackupSize -Folder $SourcePath -ExcludeFile $ExcludeFile -MaxFileSize $MaxFileSize -MaxFolderSize $MaxFolderSize
    } catch {
        Throw "❌ Aborted due to large file/folder check: $_"
    }

    if (-not $Key) {
        $Key = Get-DerivedKey -RepoPath $RepoPath
    }
    Set-ResticEnvironment -RepoPath $RepoPath -Key $Key -Silent

    $ResticIgnoreFileName = ".resticignore"
    try {
        $BackupArgs = @(
            "backup", $SourcePath,
            "--exclude-if-present", $ResticIgnoreFileName,
            "--exclude-caches", 
            "--skip-if-unchanged"
        )

        if ($ExcludeFile) {
            $BackupArgs += @("--iexclude-file", $ExcludeFile)
        }

        Write-Host "`n📦 Running backup..."
        & restic.exe @BackupArgs
        if ($LASTEXITCODE -ne 0) { Throw "❌ Backup failed (exit code $LASTEXITCODE)." }

        Write-Host "`n🗑️ Deleting redundant snapshots..."
        & restic.exe forget --prune --keep-hourly 8 --keep-daily 7 --keep-weekly 2 --keep-monthly 6 --keep-yearly 5
        if ($LASTEXITCODE -ne 0) { Throw "❌ Forget failed (exit code $LASTEXITCODE)." }

        Write-Host "`n🧹 Running cache cleanup..."
        & restic.exe cache --cleanup
        if ($LASTEXITCODE -ne 0) { Throw "❌ Cache cleanup failed (exit code $LASTEXITCODE)." }

        Write-Host "`n🔍 Running backup integrity check..."
        & restic.exe check --read-data
        if ($LASTEXITCODE -ne 0) { Throw "❌ Backup integrity check failed (exit code $LASTEXITCODE)." }

        Write-Host "`n✅ Backup completed successfully." -ForegroundColor Green
    } finally {
        Reset-ResticEnvironment -Silent
    }
}