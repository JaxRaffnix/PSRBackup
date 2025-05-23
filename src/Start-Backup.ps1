function Start-Backup {
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [Parameter(Mandatory)]
        [string]$SourcePath,

        [string]$ExcludeFile = "$PSScriptRoot..\config\exclude.txt",

        [string]$PasswordSecretName,

        [int64]$MaxFileSize = 100MB,
        [int64]$MaxFolderSize = 10GB
    )

    Write-Host "`n🔄 Starting restic backup..." -ForegroundColor Cyan
    Write-Host "  ├─ Source path: '$SourcePath'"
    Write-Host "  ├─ Repository path: '$RepoPath'"
    if ($ExcludeFile) {Write-Host "  ├─ Exclude file: '$ExcludeFile'"}   
    if ($PasswordSecretName) {Write-Host "  ├─ Password secret name: '$PasswordSecretName'"}  
    Write-Host "  ├─ Max file size: $MaxFileSize bytes"
    Write-Host "  └─ Max folder size: $MaxFolderSize bytes"
    
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
        $BackupArgs = @(
            "-r", $RepoPath, "backup", $SourcePath,
            "--exclude-caches", "--exclude-if-present", ".resticignore",
            "--skip-if-unchanged"
        )

        if ($ExcludeFile) {
            $BackupArgs += @("--iexclude-file", $ExcludeFile)
        }

        & restic.exe @BackupArgs
        if ($LASTEXITCODE -ne 0) { Throw "❌ Backup failed (exit code $LASTEXITCODE)." }
        Write-Host "Backup completed successfully."

        Write-Host "`n🔍 Running cleanup..."
        & restic.exe -r $RepoPath forget --prune --keep-hourly 8 --keep-daily 3 --keep-weekly 2 --keep-monthly 6 --keep-yearly 5
        if ($LASTEXITCODE -ne 0) { Throw "❌ Forget failed (exit code $LASTEXITCODE)." }

        & restic.exe -r $RepoPath cache --cleanup
        if ($LASTEXITCODE -ne 0) { Throw "❌ Cache cleanup failed (exit code $LASTEXITCODE)." }

        Write-Host "`n🔍 Running backup integrity check..."
        & restic.exe -r $RepoPath check --read-data
        if ($LASTEXITCODE -ne 0) { Throw "❌ Backup integrity check failed (exit code $LASTEXITCODE)." }

        Write-Host "`n✅ Backup completed successfully." -ForegroundColor Green
    } finally {
        Reset-ResticEnvironment
    }
}