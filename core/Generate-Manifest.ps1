New-ModuleManifest -Path .\WinSetup.psd1 `
    -RootModule 'PSRBackup.psm1' `
    -ModuleVersion '1.0.0' `
    -Author 'Jan Hoegen' `
    -Description 'Simplifies Windows backup process. Utilizes restic.' `
    -ProjectUri 'https://github.com/JaxRaffnix/PSRBackup' `
    -PowerShellVersion '5.1' `
    -ScriptsToProcess "core/Initialize-Module.ps1" `
    -FunctionsToExport  @(
    )
