function Start-Backup {
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [Parameter(Mandatory)]
        [string]$SourcePath,

        [string]$ExcludeFile,

        [SecureString]$PasswordSecretName,

        [int64]$MaxFileSize = 100MB,
        [int64]$MaxFolderSize = 10GB
    )

    Write-Host "`n🔄 Starting backup from '$SourcePath' to '$RepoPath'..." -ForegroundColor Cyan
    Write-Host "  ├─ Exclude file: '$ExcludeFile'"
    Write-Host "  ├─ Max file size: $($MaxFileSize / 1MB) MB"
    Write-Host "  ├─ Max folder size: $($MaxFolderSize / 1GB) GB"
    Write-Host "  └─ Password secret name: '$PasswordSecretName'"

    Test-Installation -App 'restic'

    if (-not (Test-Path "$RepoPath\config")) {
        Throw "❌ Restic repository does not exist at '$RepoPath'."
    }
    if (-not (Test-Path $SourcePath)) {
        Throw "❌ Source path '$SourcePath' does not exist."
    }
    if ($ExcludeFile -and -not (Test-Path $ExcludeFile)) {
        Write-Warning "⚠️ Exclude file '$ExcludeFile' not found. No exclusions applied."
    }

    try {
        Test-BackupSize -Folder $SourcePath -ExcludeFile $ExcludeFile -MaxFileSize $MaxFileSize -MaxFolderSize $MaxFolderSize
    } catch {
        Throw "❌ Aborted due to large file/folder check: $_"
    }

    # Derive secret name if not provided
    if (-not $PasswordSecretName) {
        $PasswordSecretName = "ResticPassword_" + ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($RepoPath)) -replace "[^a-zA-Z0-9]", "")
        Write-Verbose "Derived secret name: $PasswordSecretName"
    }

    try {
        $securePassword = Get-ResticPassword -Name $PasswordSecretName
        $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        )
    } catch {
        Throw "❌ Could not retrieve restic password: $_"
    }

    $originalEnv = $env:RESTIC_PASSWORD
    $env:RESTIC_PASSWORD = $plainPassword

    try {
        Write-Host "`n📦 Running restic backup..." -ForegroundColor Cyan
        & restic.exe -r "$RepoPath" backup "$SourcePath" `
            --exclude-caches `
            --exclude-if-present .resticignore `
            @("--iexclude-file", $ExcludeFile) `
            --skip-if-unchanged
        if ($LASTEXITCODE -ne 0) { Throw "❌ Backup failed (exit code $LASTEXITCODE)." }

        Write-Host "`n🧹 Pruning old snapshots..." -ForegroundColor DarkCyan
        & restic.exe -r "$RepoPath" forget --prune `
            --keep-hourly 8 `
            --keep-daily 3 `
            --keep-weekly 2 `
            --keep-monthly 6 `
            --keep-yearly 5
        if ($LASTEXITCODE -ne 0) { Throw "❌ Forget failed (exit code $LASTEXITCODE)." }

        Write-Host "`n🗑️ Cleaning restic cache..." -ForegroundColor DarkCyan
        & restic.exe -r "$RepoPath" cache --cleanup
        if ($LASTEXITCODE -ne 0) { Throw "❌ Cache cleanup failed (exit code $LASTEXITCODE)." }

        Write-Host "`n🔎 Running restic check..." -ForegroundColor DarkCyan
        & restic.exe -r "$RepoPath" check --read-data
        if ($LASTEXITCODE -ne 0) { Throw "❌ Backup integrity check failed (exit code $LASTEXITCODE)." }

        Write-Host "`n✅ Backup completed successfully." -ForegroundColor Green
    } finally {
        $plainPassword = $null
        $env:RESTIC_PASSWORD = $originalEnv
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}
