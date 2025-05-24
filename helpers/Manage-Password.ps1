
function Set-RepositoryPassword {
    param (
        [Parameter(Mandatory)]
        [string]$Key,

        [switch]$Force
    )

    Write-Host "🔑 Genrating password for restic repository..." -ForegroundColor Cyan
    if ($Force) {Write-Host "  ├─ Force: $Force"}
    Write-Host "  └─ Key name: '$Key'"

    if ((Get-SecretInfo -Name $Key -ErrorAction SilentlyContinue) -and -not $Force) {
        Throw "❌ A password with the key '$Key' already exists. Use -Force to overwrite."
    }

    # Generate a random 256-bit key (32 bytes) and convert it to a printable password
    $bytes = [byte[]]::new(32) # 32 bytes for a 256-bit key
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    $chars = ([char[]](33..126)) # Printable ASCII characters
    $plainPassword = -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })

    $SecurePassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force
    Set-Secret -Name $Key -Secret $SecurePassword

    Write-Host "Created a secure password and stored it." -ForegroundColor Green
}


function Get-RepositoryPassword {
    param (
        [Parameter(Mandatory)]
        [string]$Key 
    )

    if (-not (Get-SecretInfo -Name $Key -ErrorAction SilentlyContinue)) {
        Throw "❌ No password found for the key '$Key'."
    }

    return Get-Secret -Name $Name
}

function Get-DerivedKey {
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath
    )

    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($RepoPath))
    return "RepositoryPassword_" + ($encoded -replace "[^a-zA-Z0-9]", "")
}


function Set-ResticEnvironment {
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [string]$Key
    )

    if (-not $Key) {
        $Key = Get-DerivedKey -RepoPath $RepoPath
    }

    try {
        $securePassword = Get-RepositoryPassword -Name $Key
        $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        )
    } catch {
        Throw "❌ Could not retrieve restic password: $_"
    }

    $script:originalResticPassword = $env:RESTIC_PASSWORD
    $env:RESTIC_PASSWORD = $plainPassword

    $env:RESTIC_REPOSITORY = $RepoPath

    Write-Host "🔐 Environment variables set for restic repository at '$RepoPath' with key $Keys."
}


function Reset-ResticEnvironment {

    if ($script:originalResticPassword) {
        $env:RESTIC_PASSWORD = $script:originalResticPassword
        Remove-Variable -Name originalResticPassword -Scope Script -ErrorAction SilentlyContinue
    } else {
        Remove-Item Env:RESTIC_PASSWORD -ErrorAction SilentlyContinue
    }
    Remove-Item Env:RESTIC_REPOSITORY -ErrorAction SilentlyContinue

    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    Write-Host "🔄 Environment variables for restic repository have been reset."
}