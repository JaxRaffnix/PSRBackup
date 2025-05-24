function Start-Backup {
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [Parameter(Mandatory)]
        [string]$SourcePath,

        [string]$ExcludeFile = "$PSScriptRoot\..\config\exclude.txt",

        [string]$Key,

        [int64]$MaxFileSize = 100MB,
        [int64]$MaxFolderSize = 10GB
    )

    Write-Host "🔄 Starting restic backup..." -ForegroundColor Cyan
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
    Set-ResticEnvironment -RepoPath $RepoPath -Key $Key

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
        Reset-ResticEnvironment
    }
}