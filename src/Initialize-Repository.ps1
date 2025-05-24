function Initialize-Repository {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [SecureString]$PasswordSecretName,
        [switch]$Force
    )

    Write-Host "🚀 Initializing restic repository..." -ForegroundColor Cyan
    if ($PasswordSecretName) {Write-Host "  ├─ Password secret name: '$PasswordSecretName'"}
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

    if (-not $PasswordSecretName) {
        $PasswordSecretName = Get-DerivedSecretName -RepoPath $RepoPath
    }

    Write-Host "🔐 Saving password to SecretVault with name '$PasswordSecretName'..."
    Set-ResticPassword -Name $PasswordSecretName -Force:$Force
    
    Register-ResticSecretInfo -RepoPath $RepoPath -PasswordSecretName $PasswordSecretName

    Set-ResticEnvironment -RepoPath $RepoPath -PasswordSecretName $PasswordSecretName

    try {
        & restic init 
        if ($LASTEXITCODE -ne 0) {
            Throw "❌ Restic init failed with exit code $LASTEXITCODE."
        }
    } finally {
        Reset-ResticEnvironment
    }

    Write-Host "✅ Repository initialized at '$RepoPath' with secret name." -ForegroundColor Green
}
function Register-ResticSecretInfo {
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [Parameter(Mandatory)]
        [SecureString]$PasswordSecretName,

        [string]$LogPath = "$env:LOCALAPPDATA\restic-repo-info.json"
    )

    if ($PasswordSecretName -is [SecureString]) {
    $PasswordSecretName = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($PasswordSecretName)
    )
    }

    $repoKey = [System.IO.Path]::GetFileName($RepoPath.TrimEnd('\', '/'))

    Write-Host "📝 Registering restic secret info..." -ForegroundColor Cyan
    Write-Host "  ├─ Repository name: '$repoKey'"
    Write-Host "  ├─ Secret name: '$PasswordSecretName'"
    Write-Host "  └─ Log path: '$LogPath'"

    if (-not (Test-Path $LogPath)) {
        '{}' | Out-File -Encoding UTF8 -FilePath $LogPath
    }

    try {
        $json = Get-Content $LogPath -Raw | ConvertFrom-Json
    } catch {
        Throw "❌ Failed to read JSON log at '$LogPath': $_"
    }


    # Decrypt the SecureString to plain text
    # $securePassword = Get-ResticPassword -Name $PasswordSecretName
    # $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    #     [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    # )

    $repoInfo = [PSCustomObject]@{
        path      = $RepoPath
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        secret    = @{
            name  = $PasswordSecretName
            vault = (Get-SecretVault | Where-Object { $_.IsDefault }).Name
            # value = $plainPassword
        }
    }

    if ($json.PSObject.Properties.Name -notcontains $repoKey) {
        $json | Add-Member -MemberType NoteProperty -Name $repoKey -Value $repoInfo
    } else {
        $json.$repoKey = $repoInfo
    }

    $json | ConvertTo-Json -Depth 3 | Set-Content -Encoding UTF8 -Path $LogPath

    Write-Host "✅ Logged restic secret info for '$repoKey' to '$LogPath'." -ForegroundColor Green
}

