# Check if winget is available
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget is not installed or not available in PATH. Please install winget first."
    exit 1
}

$ResticName = "restic.restic"

# Check if restic is already installed
$resticInstalled = winget list --id $ResticName | Select-String $ResticName

if ($resticInstalled) {
    # Write-Host "restic is already installed."
} else {
    Write-Host "Installing restic using winget..."
    winget install --id $ResticName --silent --accept-source-agreements --accept-package-agreements --disable-interactivity --force 

    if ($LASTEXITCODE -eq 0) {
        Write-Host "restic installed successfully."
    } else {
        Throw "Failed to install restic."
    }
}

if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretManagement)) {
    Install-Module Microsoft.PowerShell.SecretManagement -Scope CurrentUser -Force
}
if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretStore)) {
    Install-Module Microsoft.PowerShell.SecretStore -Scope CurrentUser -Force
}

# Check if this is necsessary
Import-Module Microsoft.PowerShell.SecretManagement
Import-Module Microsoft.PowerShell.SecretStore


if (-not (Get-SecretVault -Name ResticVault -ErrorAction SilentlyContinue)) {
    Register-SecretVault -Name ResticVault -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
}
