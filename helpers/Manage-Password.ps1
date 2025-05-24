
function Set-ResticPassword {
    param (
        [string]$Name = "ResticPassword",
        [switch]$Force
    )

    if ((Get-SecretInfo -Name $Name -ErrorAction SilentlyContinue) -and -not $Force) {
        Throw "❌ A password with the name '$Name' already exists. Use -Force to overwrite."
    }

    # Auto-generate a strong password
    $plainPassword = New-RandomSecurePassword
    $secStr = ConvertTo-SecureString $plainPassword -AsPlainText -Force

    Set-Secret -Name $Name -Secret $secStr
}


function New-RandomSecurePassword {
    param (
        [int]$Length = 32
    )

    $bytes = [byte[]]::new($Length)
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)

    $chars = ([char[]](33..126)) # Printable ASCII characters
    $securePassword = -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
    return $securePassword
}
function Get-ResticPassword {
    param (
        [string]$Name = "ResticPassword"
    )

    if (-not (Get-SecretInfo -Name $Name -ErrorAction SilentlyContinue)) {
        Throw "❌ No password found with the name '$Name'."
    }

    return Get-Secret -Name $Name
}

function Get-DerivedSecretName {
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath
    )

    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($RepoPath))
    return ConvertTo-SecureString ("ResticPassword_" + ($encoded -replace "[^a-zA-Z0-9]", "")) -AsPlainText -Force
}

function Set-ResticEnvironment {
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [SecureString]$PasswordSecretName
    )

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

    $script:originalResticPassword = $env:RESTIC_PASSWORD
    $env:RESTIC_PASSWORD = $plainPassword

    $env:RESTIC_REPOSITORY = $RepoPath
}

function Reset-ResticEnvironment {
    if ($script:originalResticPassword) {
        $env:RESTIC_PASSWORD = $script:originalResticPassword
    }
    Remove-Item Env:RESTIC_REPOSITORY -ErrorAction SilentlyContinue
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}