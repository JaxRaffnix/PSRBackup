.$PSScriptRoot\..\helpers\Test-Installation.ps1

$ModuleName = Split-Path (Split-Path $PSScriptRoot -Parent) -Leaf

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

Write-Host "🔍 Installing modules SecretManagement and SecretStore..."
foreach ($module in @("Microsoft.PowerShell.SecretManagement", "Microsoft.PowerShell.SecretStore")) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "📦 Installing module '$module'..." -ForegroundColor Cyan
        Install-Module -Name $module -Scope CurrentUser -Force
    } else {
        Write-Host "✅ Module '$module' is already available."
    }
}

Write-Host "📥 Importing modules SecretManagement and SecretStore..."
foreach ($module in @("Microsoft.PowerShell.SecretManagement", "Microsoft.PowerShell.SecretStore")) {
    if (-not (Get-Module -Name $module)) {
        Import-Module $module -Force
        Write-Host "✅ Module '$module' imported."
    } else {
        Write-Host "✅ Module '$module' is already imported."
    }
}

$VaultName = "PSRBackup"

Write-Host "🔐 Registering vault '$VaultName'..."
if (-not (Get-SecretVault -Name $VaultName -ErrorAction SilentlyContinue)) {
    Register-SecretVault -Name $VaultName -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
    Write-Host "✅ Secret vault '$VaultName' registered."
} else {
    Write-Host "✅ Vault '$VaultName' already registered."
}

Write-Host "Initialized module successfully." -ForegroundColor Green
