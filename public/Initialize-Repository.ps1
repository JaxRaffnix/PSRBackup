function Initialize-Repository {
    <#
    .SYNOPSIS
        Initializes a new backup repository in the specified location.

    .DESCRIPTION
        This script sets up the necessary folder structure and initializes a new restic repository.

    .PARAMETER RepoPath
        The file system path where the backup repository should be initialized.
        This parameter is required and must point to a valid directory location.

    .PARAMETER Key
        The SecretManagement key used to get the restic repository password.
        If not provided, a key will be derived from the repository path.

    .PARAMETER Force
        If specified, forces the initialization even if the target directory is not empty or already contains a repository.
        Use with caution as this may overwrite existing data.

    .EXAMPLE
        Initialize-Repository -Path "C:\Backups\MyRepo"

        Initializes a new backup repository at the specified path.

    .EXAMPLE
        Initialize-Repository -Path "C:\Backups\MyRepo" -Force

        Initializes a new backup repository at the specified path, overwriting any existing repository data.
    #>
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [string]$Key,
        [switch]$Force
    )

    Write-Host "`n🚀 Initializing restic repository..." -ForegroundColor Cyan
    if ($Key) {Write-Host "  ├─ Password key: '$Key'"}
    if ($Force) {Write-Host "  ├─ Force: $Force"}
    Write-Host "  └─ Repository path: '$RepoPath'"

    Test-Installation -App 'restic'

    if (-not (Test-Path $RepoPath)) {
        New-Item -ItemType Directory -Path $RepoPath -Force | Out-Null
    }

    if (Test-Path (Join-Path -Path $RepoPath -ChildPath "config")) {
        if ($Force) {
            Write-Warning "⚠️ Removing existing Restic repository at '$RepoPath' due to -Force..."
            Remove-Item -Path $RepoPath -Recurse -Force
            New-Item -ItemType Directory -Path $RepoPath -Force | Out-Null
        } else {
            Throw "❌ Restic repository already exists at '$RepoPath'. Use -Force to overwrite."
        }
    }

    if (-not $Key) {
        $Key = Get-DerivedKey -RepoPath $RepoPath
        Write-Host "🔑 Generated key from path name: '$Key'"
    }
    Set-RepositoryPassword -Key $Key -Force:$Force
    Register-KeyMapping -RepoPath $RepoPath -Key $Key
    Set-ResticEnvironment -RepoPath $RepoPath -Key $Key -Silent

    Write-Host "📁 Creating repository..."
    try {
        & restic init 
        if ($LASTEXITCODE -ne 0) {
            Throw "❌ Restic init failed with exit code $LASTEXITCODE."
        }
    } finally {
        Reset-ResticEnvironment -Silent
    }

    Write-Host "✅ Repository initialized." -ForegroundColor Green
}


function Register-KeyMapping {
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [Parameter(Mandatory)]
        [string]$Key,

        [string]$LogPath = "$env:LOCALAPPDATA\PSRBackup Repository Information.json"
    )



    Write-Host "`n📝 Logging password key for restic repository..." -ForegroundColor Cyan
    Write-Host "  ├─ Repository path: '$RepoPath'"
    Write-Host "  ├─ Key: '$Key'"
    Write-Host "  └─ Log path: '$LogPath'"

    $repoKey = [System.IO.Path]::GetFileName($RepoPath.TrimEnd('\', '/'))
    Write-Host "🛠️ Derived repository name: '$repoKey'"

    if (-not (Test-Path $LogPath)) {
        '{}' | Out-File -Encoding UTF8 -FilePath $LogPath
    }

    try {
        $json = Get-Content $LogPath -Raw | ConvertFrom-Json
    } catch {
        Throw "❌ Failed to read JSON log at '$LogPath': $_"
    }


    $repoInfo = [PSCustomObject]@{
        path      = $RepoPath
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        key    = @{
            vault = (Get-SecretVault | Where-Object { $_.IsDefault }).Name
            name  = $Key

        }
    }

    if ($json.PSObject.Properties.Name -notcontains $repoKey) {
        $json | Add-Member -MemberType NoteProperty -Name $repoKey -Value $repoInfo
    } else {
        $json.$repoKey = $repoInfo
    }

    $json | ConvertTo-Json -Depth 3 | Set-Content -Encoding UTF8 -Path $LogPath

    Write-Host "✅ Logged password key to logfile." -ForegroundColor Green
}
