function Set-ResticEnvironment {
    <#
    .SYNOPSIS
    Sets environment variables required for interacting with a restic repository.

    .DESCRIPTION
    The Set-ResticEnvironment function sets the RESTIC_PASSWORD and RESTIC_REPOSITORY environment variables for the current session, enabling secure access to a specified restic repository. If a key is not provided, it derives one from the repository path. The repository password is securely retrieved and converted to plain text for use as an environment variable.

    .PARAMETER RepoPath
    The file path to the restic repository. This parameter is mandatory.

    .PARAMETER Key
    The SecretManagement key used to retrieve the repository password. If not provided, the key is derived from the repository path.

    .PARAMETER Silent
    If specified, suppresses output messages during the execution of the function.

    .EXAMPLE
    Set-ResticEnvironment -RepoPath "C:\Backups\ResticRepo"

    Sets the environment variables for the restic repository at the specified path, deriving the key automatically.

    .EXAMPLE
    Set-ResticEnvironment -RepoPath "C:\Backups\ResticRepo" -Key "my-secret-key"

    Sets the environment variables for the restic repository at the specified path using the provided key.

    .NOTES
    This function stores the original RESTIC_PASSWORD in a script-scoped variable ($script:originalResticPassword) for potential with the Reset-ResticEnvironment function.
    #>

    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,

        [string]$Key,

        [string]$Silent
    )

    if (-not $Key) {
        $Key = Get-DerivedKey -RepoPath $RepoPath
    }

    try {
        $securePassword = Get-RepositoryPassword -Key $Key
        $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        )
    } catch {
        Throw "❌ Could not retrieve restic password: $_"
    }

    $script:originalResticPassword = $env:RESTIC_PASSWORD
    $env:RESTIC_PASSWORD = $plainPassword

    $env:RESTIC_REPOSITORY = $RepoPath

    if (-not $Silent) {
        Write-Host "🔐 Environment variables set for restic repository at '$RepoPath' with key $Key."
        Write-Warning "⚠️ The RESTIC_PASSWORD is stored in plain text in the environment variable for this session. Ensure to reset it after use by calling 'Reset-ResticEnvironment'."
    }
    
}

function Reset-ResticEnvironment {
    <#
    .SYNOPSIS
    Resets environment variables related to the Restic backup repository.

    .DESCRIPTION
    The Reset-ResticEnvironment function restores the RESTIC_PASSWORD environment variable to its original value if it was previously saved, or removes it if not. It also removes the RESTIC_REPOSITORY environment variable. After cleaning up the environment variables, it triggers garbage collection to free up memory and outputs a message indicating the reset is complete.

    .PARAMETER Silent
    If specified, suppresses output messages during the execution of the function.

    .EXAMPLE
    Reset-ResticEnvironment

    Resets the Restic environment variables to their original state or removes them if not set.

    .NOTES
    This function is intended to be used in scripts that interact with Restic repositories and require cleanup of sensitive environment variables after use.
    However, it can also be used by the user in a console to manually reset the environment variables if needed.
    #>

    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Silent
    )

    if ($script:originalResticPassword) {
        $env:RESTIC_PASSWORD = $script:originalResticPassword
        Remove-Variable -Name originalResticPassword -Scope Script -ErrorAction SilentlyContinue
    } else {
        Remove-Item Env:RESTIC_PASSWORD -ErrorAction SilentlyContinue
    }
    Remove-Item Env:RESTIC_REPOSITORY -ErrorAction SilentlyContinue

    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    if (-not $Silent) {
        Write-Host "🔄 Environment variables for restic repository have been reset."
    }
}