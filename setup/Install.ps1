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

#  in PowerShell 7

# Elevate privileges
# if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
#     Write-Warning "⚠️ This script needs to be run as an administrator. Restarting with elevated privileges..."
#     Start-Process powershell.exe "-NoExit -File `"$PSCommandPath`"" -Verb RunAs
#     exit
# }

# *: Make sure emojis are displayed correctly in the console
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Fix untrusted script execution
$RequiredPolicy = "RemoteSigned"
try {
    $CurrentExecutionPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($CurrentExecutionPolicy -ne $RequiredPolicy) {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy $RequiredPolicy -Force
        Write-Host "🔐 Execution Policy set to '$RequiredPolicy' for current user." -ForegroundColor Cyan
    }
} catch {
    Write-Error "❌ Failed to set execution policy: $_"
}

# Ensure PowerShell version is 5.1
if ($PSVersionTable.PSVersion.Major -ne 5) {
    Throw "This script requires PowerShell 5.1. Current version: $($PSVersionTable.PSVersion)"
}

# Define module info
$ModuleName = Split-Path (Split-Path $PSScriptRoot -Parent) -Leaf
$ModulePath = Split-Path -Path $PSScriptRoot -Parent
$UserModulesPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell\Modules"
$TargetPath = Join-Path -Path $UserModulesPath -ChildPath $ModuleName

Write-Host "⬇️ Installing module..." -ForegroundColor Cyan
Write-Host "  ├─ Module name: '$ModuleName'"
Write-Host "  ├─ Source path: '$ModulePath'"
Write-Host "  └─ Target path: '$TargetPath'"

# Unload if already loaded
if (Get-Module -Name $ModuleName) {
    try {
        Remove-Module -Name $ModuleName -Force -ErrorAction Stop
        Write-Host "🗑️ Removed previously loaded module '$ModuleName'."
    } catch {
        Write-Error "❌ Failed to unload module '$ModuleName': $_"
    }
}

# Remove existing module folder
if (Test-Path $TargetPath) {
    try {
        Remove-Item -Path $TargetPath -Recurse -Force -ErrorAction Stop
        Write-Host "🗑️ Removed existing module at '$TargetPath'."
    } catch {
        Write-Error "❌ Failed to remove existing module folder: $_"
    }
}

# Create target folder
New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null

# Copy files
$IgnoreFiles = @(".git", ".gitignore", "setup", "core/Generate-Manifest.ps1")
try {
    Copy-Item -Path "$ModulePath\*" -Destination $TargetPath -Recurse -Force -ErrorAction Stop
    Write-Host "📁 Copied module files to target location."

    foreach ($file in $IgnoreFiles) {
        $filePath = Join-Path -Path $TargetPath -ChildPath $file
        if (Test-Path $filePath) {
            Remove-Item -Path $filePath -Force -ErrorAction Stop -Recurse
            Write-Host "  └─ Removed ignored item: '$file'"
        }
    }
} catch {
    Write-Error "❌ Failed during copy or cleanup: $_"
}

# Import module
try {
    # if (-not ($env:PSModulePath -like "*$UserModulesPath*")) {
    #     $env:PSModulePath += ";$UserModulesPath"
    # }
    Import-Module $ModuleName -Force -ErrorAction Stop
    Write-Host "✅ Module '$ModuleName' installed and imported." -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to import module '$ModuleName': $_"
}
