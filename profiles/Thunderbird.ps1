function Backup-Thunderbird {
    <#
    .SYNOPSIS
    Backup Thunderbird profile data.

    .DESCRIPTION
    Backs up Thunderbird profile data to a specified backup directory, excluding unnecessary folders as defined in a config file.

    .PARAMETER SourcePath
    The source path for the Thunderbird profile. Defaults to the Scoop persist directory for Thunderbird.

    .PARAMETER TargetPath
    The destination path for the backup.

    .PARAMETER ExcludeFile
    A text file containing folder names (one per line) to exclude from the backup. Lines starting with '#' are treated as comments.

    .EXAMPLE
    Backup-Thunderbird -TargetPath "C:\Backup\Thunderbird"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$TargetPath,

        [string]$SourcePath = "$env:Appdata\thunderbird",

        [string]$ExcludeFile = "$PSScriptRoot\..\config\thunderbird-exclude.txt"
    )

    if (-not (Test-Path $SourcePath)) {
        Throw "Thunderbird profile not found: $SourcePath"
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

    # Parse exclude file
    $excludeArgs = @()
    if (Test-Path $ExcludeFile) {
        $excludes = Get-Content $ExcludeFile | Where-Object { $_ -and -not $_.StartsWith("#") }
        foreach ($item in $excludes) {
            $excludeArgs += @("/XD", $item)
        }
    }

    # TODO: is a MIR mirror really the best for restoring? a temporary profile might get deleted
    $robocopyArgs = @(
        $SourcePath,
        $TargetPath,
        "/E",        # Copy subdirectories including empty ones
        "/Z",        # Restartable mode
        "/XA:SH",     # Exclude system/hidden files
        "/MIR"      # Mirror the directory structure
    ) + $excludeArgs

    Write-Host "Starting Thunderbird profile backup..."
    $null = & robocopy @robocopyArgs

    if ($LASTEXITCODE -le 3) {
        Write-Host "Backup completed successfully to $TargetPath."
    } else {
        Write-Warning "Backup may have encountered errors. Robocopy exit code: $LASTEXITCODE"
    }
}

# Backup-Thunderbird -TargetPath "D:\Thunderbird Backup" -SourcePath "$env:Appdata\thunderbird"
Backup-Thunderbird -TargetPath "$env:Appdata\thunderbird" -SourcePath "D:\Thunderbird Backup"
