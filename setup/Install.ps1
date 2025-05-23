<#
.SYNOPSIS
Installs the current PowerShell module into the user's module path.

.DESCRIPTION
This script automates the installation of a PowerShell module by copying the current folder to the user's module path located at 
'$env:USERPROFILE\Documents\PowerShell\Modules'. If a module with the same name already exists, 
it will be overwritten. After copying, the module is imported to make it immediately available 
for use in the current session.

.NOTES
- Ensure this script is run from the module folder.

.EXAMPLE
.\Install.ps1
This command installs the module located in the current folder into the user's PowerShell 
module path and imports it into the current session.
#>

# Elevate privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script needs to be run as an administrator in PowerShell 7. Restarting with elevated privileges..."
    Start-Process pwsh.exe "-NoExit -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Fix untrusted script execution
$RequiredPolicy = "RemoteSigned"
try {
    $CurrentExecutionPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($CurrentExecutionPolicy -ne $RequiredPolicy) {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy $RequiredPolicy -Force

        Write-Host "Execution Policy has been set to '$RequiredPolicy' for the current user."
    } 
    # else {
    #     Write-Host "Execution Policy is already set to '$CurrentExecutionPolicy' for the current user."
    # }
} catch {
    Write-Error "Failed to set execution policy: $_"
}

# Define Module name and paths
$ModuleName = "PSRBackup"  
$ModulePath = Split-Path -Path $PSScriptRoot -Parent  # The parent folder of the current script folder (i.e., 'WinSetup')
$UserModulesPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\PowerShell\Modules"
$TargetPath = Join-Path -Path $UserModulesPath -ChildPath $ModuleName

Write-Host "Installing module $ModuleName from '$ModulePath' to '$TargetPath'..." -ForegroundColor Cyan

# Check if the module is already loaded and remove it
if (Get-Module -Name $ModuleName) {
    try {
        Remove-Module -Name $ModuleName -Force -ErrorAction Stop

        Write-Host "Removed loaded module $ModuleName with older version from the current session."
    } catch {
        Write-Error "Failed to remove loaded module $ModuleName with older version : $_"
    }
}

# Remove the existing module folder if it exists
if (Test-Path $TargetPath) {
    try {
        Remove-Item -Path $TargetPath -Recurse -Force -ErrorAction Stop
        
        Write-Host "Removed existing module files with older version at: '$TargetPath'."
    } catch {
        Write-Error "Failed to remove existing module with older version: $_"
    }
}

# Create target path if it doesn't exist
if (-not (Test-Path $TargetPath)) {
    try {
        New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null

        Write-Host "Created target directory '$TargetPath'."
    } catch {
        Write-Error "Failed to create target directory: $_"
    }
} else {
    # this should never happen, because we removed it above
    Throw "❌ Target directory '$TargetPath' already exists."
}

$IgnoreFiles = @(".git", "setup", "core/Generate-Manifest.ps1")
# Copy all files from this folder to the user module path
try {
    Copy-Item -Path "$ModulePath\*" -Destination $TargetPath -Recurse -Force -ErrorAction Stop
    Write-Host "Copied Module from '$ModulePath' to '$TargetPath'."
    
    # Exclude the specified files from being copied
    foreach ($file in $IgnoreFiles) {
        $filePath = Join-Path -Path $TargetPath -ChildPath $file
        if (Test-Path $filePath) {
            Remove-Item -Path $filePath -Force -ErrorAction Stop -Recurse
            Write-Host "Removed ignored file '$file' from target path."
        }
    }
} catch {
    Write-Error "Failed to copy module files: $_"
}

# Import the module
try {
    $env:PSModulePath += ";$UserModulesPath"  # Update the environment variable to include the new module path
    Import-Module $ModuleName -Force -ErrorAction Stop

    Write-Host "Module $ModuleName installed successfully." -ForegroundColor Green
} catch {
    Write-Error "Failed to install module '$ModuleName': $_"
}
