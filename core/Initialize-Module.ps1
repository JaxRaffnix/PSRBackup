.PSScriptRoot\..\helpers\Test-Installation.ps1

$ModuleName = "PSRBackup"

Write-Host "🔧 Initializing Module $ModuleName..." -ForegroundColor Cyan

Test-Installation -App winget 

Write-Host "📦 Installing restic..."

$ResticPackageId = "Restic.Restic"
$resticInstalled = winget list --id $ResticPackageId | Select-String $ResticPackageId

if (-not $resticInstalled) {
    winget install --id $ResticPackageId `
                    --silent `
                    --accept-source-agreements `
                    --accept-package-agreements `
                    --disable-interactivity `
                    --force

    if ($LASTEXITCODE -ne 0) {
        Throw "❌ Failed to install restic."
    }

    Write-Host "✅ Restic installed successfully."
} else {
    Write-Host "✅ Restic already installed."
}

Write-Host "🔍 Ensuring SecretManagement modules are available..."
foreach ($module in @("Microsoft.PowerShell.SecretManagement", "Microsoft.PowerShell.SecretStore")) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "📦 Installing module '$module'..." -ForegroundColor Cyan
        Install-Module -Name $module -Scope CurrentUser -Force
    } else {
        Write-Host "✅ Module '$module' is already available."
    }
}

Write-Host "📥 Importing modules..."
Import-Module Microsoft.PowerShell.SecretManagement -Force
Import-Module Microsoft.PowerShell.SecretStore -Force

Write-Host "🔐 Ensuring vault '$VaultName' is registered..."
if (-not (Get-SecretVault -Name $VaultName -ErrorAction SilentlyContinue)) {
    Register-SecretVault -Name $VaultName -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
    Write-Host "✅ Secret vault '$VaultName' registered." -ForegroundColor Green
} else {
    Write-Host "✅ Vault '$VaultName' already registered."
}
