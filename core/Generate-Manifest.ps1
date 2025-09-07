<#
.SYNOPSIS
Generates a manifest file for the backup process.

.EXAMPLE
.\Generate-Manifest.ps1
#>

New-ModuleManifest -Path .\$ModuleName.psd1 `
    -RootModule 'PSRBackup.psm1' `
    -ModuleVersion '1.0.0' `
    -Author 'Jan Hoegen' `
    -Description 'PSRBackup (PowerShell Restic Backup) is a PowerShell module that simplifies and automates Windows backups using [restic](https://restic.net/).' `
    -ProjectUri 'https://github.com/JaxRaffnix/PSRBackup' `
    -PowerShellVersion '5.1' `
    -ScriptsToProcess "core/Initialize-Module.ps1" `
    -FunctionsToExport  @(
        'Initialize-Repository'
        'Restore-Backup'
        'Start-Backup'
        'Set-ResticEnvironment'
        'Reset-ResticEnvironment'
    )
