
function Save-ResticPassword {
    param (
        [string]$Name = "ResticPassword",
        [switch]$Force
    )

    if ((Get-SecretInfo -Name $Name -ErrorAction SilentlyContinue) -and -not $Force) {
        Throw "❌ A password with the name '$Name' already exists. Use -Force to overwrite."
    }

    $secStr = Read-Host "Enter Restic password" -AsSecureString
    Set-Secret -Name $Name -Secret $secStr -Force:$Force
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
    return "ResticPassword_" + ($encoded -replace "[^a-zA-Z0-9]", "")
}

function Set-ResticEnvironment {
    param (
        [Parameter(Mandatory)]
        [SecureString]$Password
    )

    $script:originalResticPassword = $env:RESTIC_PASSWORD
    $env:RESTIC_PASSWORD = $Password
    $env:RESTIC_REPOSITORY = $RepoPath
}

function Reset-ResticEnvironment {
    Remove-Item Env:RESTIC_REPOSITORY -ErrorAction SilentlyContinue
    $env:RESTIC_PASSWORD = $script:originalResticPassword
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}