function Backup-Playnite {
    param (
        [Parameter(Mandatory)]
        [string]$TargetPath,

        [string]$SourcePath = "C:\Users\Jax\Documents\Playnite Backup"
    )

    if (-not (Test-Path $SourcePath)) {
        Throw "Playnite profile not found: $SourcePath"
    }

    if (-not (Test-Path $TargetPath)) {
        try {
            New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
        } catch {
            Throw "Failed to create backup directory: $_"
        }
    } else {
        Write-Warning "Target path already exists. Backup will overwrite existing files."
    }

    $robocopyArgs = @(
        $SourcePath,
        $TargetPath,
        "/E",        # Copy subdirectories including empty ones
        "/Z",        # Restartable mode
        "/XA:SH",     # Exclude system/hidden files
        "/MIR"      # Mirror the directory structure
    )

    Write-Host "Starting Playnite profile backup..."
    $null = & robocopy @robocopyArgs

    if ($LASTEXITCODE -le 3) {
        Write-Host "Backup completed successfully to $TargetPath."
    } else {
        Write-Warning "Backup may have encountered errors. Robocopy exit code: $LASTEXITCODE"
    }
    
    # TODO: make this work: https://api.playnite.link/docs/manual/library/backup.html
}