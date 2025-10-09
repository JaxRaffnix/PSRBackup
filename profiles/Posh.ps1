function Set-Posh {
    <#
    .SYNOPSIS
        Configures Oh My Posh and sets the MesloLGM Nerd Font for Windows Terminal.

    .DESCRIPTION
        Ensures Oh My Posh is initialized in the PowerShell profile, installs the MesloLGM Nerd Font,
        and updates Windows Terminal settings to use the font.

    .PARAMETER ProfilePath
        Optional. Path to the PowerShell profile to update. Defaults to $PROFILE.

    .EXAMPLE
        Set-Posh
        Sets up Oh My Posh and configures the font for Windows Terminal.
    #>
    [CmdletBinding()]
    param (
        [string]$ProfilePath = $PROFILE,
        [string]$FontName = "MesloLGM Nerd Font"
    )

    Write-Host "Setting up Oh My Posh..." -ForegroundColor Cyan

    # Ensure profile file exists
    if (!(Test-Path $ProfilePath)) {
        New-Item -Path $ProfilePath -Type File -Force | Out-Null
    }

    # Add Oh My Posh initialization if not already present
    $initLine = 'oh-my-posh init pwsh | Invoke-Expression'
    $profileContent = Get-Content $ProfilePath -Raw
    if ($profileContent -notmatch [regex]::Escape($initLine)) {
        Add-Content $ProfilePath "`n$initLine"
        Write-Host "Added Oh My Posh initialization to profile."
    } else {
        Write-Warning "Oh My Posh initialization already present in profile."
    }

    # Install MesloLGM Nerd Font if not already installed
    $fontInstalled = (Get-WmiObject -Query "Select * from Win32_FontInfoAction" | Where-Object { $_.Caption -like "*$FontName*" }).Count -gt 0
    if (-not $fontInstalled) {
        oh-my-posh font install meslo
        Write-Host "Installed MesloLGM Nerd Font." 
    } else {
        Write-Warning "MesloLGM Nerd Font already installed." 
    }

    # Update Windows Terminal font
    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path $settingsPath) {
        $json = Get-Content $settingsPath -Raw | ConvertFrom-Json
        if ($null -eq $json.profiles) { $json | Add-Member -MemberType NoteProperty -Name profiles -Value @{} }
        if ($null -eq $json.profiles.defaults) { $json.profiles | Add-Member -MemberType NoteProperty -Name defaults -Value @{} }
        $json.profiles.defaults.font = $json.profiles.defaults.font
        $json.profiles.defaults.font.face = $fontName
        $json | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
        Write-Host "Windows Terminal font updated to $fontName!"
    } else {
        Write-Warning "Windows Terminal settings.json not found. Skipping font update."
    }

    Write-Host "Oh My Posh setup completed." -ForegroundColor Green
}
