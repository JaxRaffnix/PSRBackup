function Test-Backupsize {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Folder,

        [string]$ExcludeFile,

        [int64]$MaxFileSize = 100MB,
        [int64]$MaxFolderSize = 1GB
    )

    Write-Host "Scanning for large files and folders in: '$Folder' with ExcludeFile: '$ExcludeFile'" -ForegroundColor Cyan

    if (-not (Test-Path $Folder)) {
        Throw "The specified folder '$Folder' does not exist."
    }
    if (-not (Test-Path $ExcludeFile)) {
        Write-Warning "The specified exclude file '$ExcludeFile' does not exist. No exclusions will be applied."
    }

    $excludePatterns = @()
    if ($ExcludeFile) {
        $excludePatterns = Get-Content $ExcludeFile | Where-Object { $_ -and -not $_.StartsWith("#") }
    }

    function Test-Excluded {
        param ([string]$Path)
        foreach ($pattern in $excludePatterns) {
            # Handle absolute paths
            if ($pattern -like "/*") {
                $regex = "^" + [regex]::Escape($Folder + $pattern.TrimStart('/')).Replace("\\*", ".*").Replace("\\?", ".") + "$"
            } else {
                # Handle relative and wildcard patterns
                $regex = [regex]::Escape($pattern).Replace("\\*", ".*").Replace("\\?", ".")
            }
            if ($Path -match $regex) {
                return $true
            }
        }
        return $false
    }

    # Detect large files
    $largeFiles = Get-ChildItem $Folder -Recurse -File -Force | Where-Object {
        $_.Length -gt $MaxFileSize -and -not (Test-Excluded -Path $_.FullName)
    }

    if ($largeFiles) {
        Write-Host "Found large files"
        $largeFiles | Select-Object FullName, @{Name="Size"; Expression={"{0:N2} GB" -f ($_.Length / 1GB)}} | Format-Table
    }

    # Detect large folders (excluding based on patterns)
    $largeFolders = Get-ChildItem $Folder -Recurse -Directory -Force | ForEach-Object {
        if (Test-Excluded -Path $_.FullName) { return }

        $size = ($_ | Get-ChildItem -Recurse -File -Force | Where-Object {
            -not (Test-Excluded -Path $_.FullName)
        } | Measure-Object -Property Length -Sum).Sum ?? 0

        if ($size -gt $MaxFolderSize) {
            [PSCustomObject]@{
                FullName = $_.FullName
                SizeGB   = "{0:N2}" -f ($size / 1GB)
            }
        }
    }

    if ($largeFolders) {
        Write-Host "Found large folders"
        $largeFolders | Format-Table
    }

    # Prompt user if any large items were found
    if ($largeFiles.Count -gt 0 -or $largeFolders.Count -gt 0) {
        $confirmation = Read-Host "`nProceed with backup despite large files/folders? (y/n)"
        if ($confirmation -ne 'y') {
            Throw "Backup aborted by user."
        }
    }
}
