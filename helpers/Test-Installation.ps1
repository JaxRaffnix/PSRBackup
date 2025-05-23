function Test-Installation {
    <#
    .SYNOPSIS
    Checks if a specific command-line application is installed and accessible.

    .DESCRIPTION
    Uses Get-Command to determine if an executable like 'git', 'gsudo', etc., is available in the system's PATH.

    .PARAMETER App
    The name of the application or command to check (e.g., 'git', 'gsudo').

    .EXAMPLE
    Test-Installation -App 'git'
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$App
    )

    try {
        # Check if the application is available in the PATH
        Get-Command -Name $App -ErrorAction Stop | Out-Null
    } catch {
        Write-Error "❌ $App is not installed or not available in the PATH. Please install $App and try again."
    }
}