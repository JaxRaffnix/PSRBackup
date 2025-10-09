function Set-WindowsConfiguration {
    <#
    .SYNOPSIS
    Configures various Windows settings to enhance usability and functionality.

    .DESCRIPTION
    This function allows you to configure a range of Windows settings, such as enabling clipboard sync, hiding the search icon, enabling dark mode, showing hidden files, and more. You can enable individual settings or apply all configurations at once using the -All parameter.

    .PARAMETER All
    Applies all available configuration options.

    .PARAMETER EnableClipboardSync
    Enables clipboard history and synchronization across devices.

    .PARAMETER HideSearchIcon
    Hides the Windows Search icon from the taskbar.

    .PARAMETER EnableSearchIndex
    Enables and starts the Windows Search Indexing service to improve file search performance.

    .PARAMETER EnableDarkMode
    Activates dark mode for Windows applications and system UI.

    .PARAMETER EnableFullPathInExplorer
    Displays the full file path in the title bar of File Explorer.

    .PARAMETER ShowHiddenFiles
    Configures File Explorer to display hidden files and folders.

    .PARAMETER ShowFileExtensions
    Configures File Explorer to display file extensions for known file types.

    .PARAMETER EnableLongPaths
    Enables support for file paths longer than 260 characters.

    .PARAMETER EnableDeveloperMode
    Activates Windows Developer Mode, allowing the installation of unsigned apps and enabling advanced developer features.

    .PARAMETER DisableEdgeTabsInAltTabView
    Disables the display of Microsoft Edge tabs in the Alt+Tab view.

    .EXAMPLE
    Set-WindowsConfiguration -All
    Configures all available settings.

    .NOTES
    This function requires administrative privileges with the 'gsudo' tool for certain settings to be applied successfully.
    #>

    [CmdletBinding()]
    param (
        [switch]$All,
        [switch]$EnableClipboardSync,
        [switch]$HideSearchIcon,
        [switch]$EnableSearchIndex,
        [switch]$EnableDarkMode,
        [switch]$EnableFullPathInExplorer,
        [switch]$ShowHiddenFiles,
        [switch]$ShowFileExtensions,
        [switch]$EnableLongPaths,
        [switch]$EnableDeveloperMode,
        [switch]$DisableEdgeTabsInAltTabView
    )

    # Enable all options if -All is specified
    if ($All) {
        $EnableClipboardSync = $true
        $HideSearchIcon = $true
        $EnableSearchIndex = $true
        $EnableDarkMode = $true
        $EnableFullPathInExplorer = $true
        $ShowHiddenFiles = $true
        $ShowFileExtensions = $true
        $EnableLongPaths = $true
        $EnableDeveloperMode = $true
        $DisableEdgeTabsInAltTabView = $true
    }

    # Validate if at least one option is selected
    if (-not ($EnableClipboardSync -or $HideSearchIcon -or $EnableSearchIndex -or $EnableDarkMode -or $EnableFullPathInExplorer -or $ShowHiddenFiles -or $ShowFileExtensions -or $EnableLongPaths -or $EnableDeveloperMode)) {
        Throw "No configuration options were selected. Use -All or specify individual switches."
    }

    Test-Installation -App 'gsudo'

    Write-Host "Starting Windows configuration setup..." -ForegroundColor Cyan

    # Enable clipboard history and sync
    if ($EnableClipboardSync) {
        try {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Value 1 -Force
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardSync" -Value 1 -Force

            Write-Host "Clipboard history and sync enabled successfully." 
        } catch {
            Write-Error "Failed to enable clipboard history and sync: $_"
        }
    }

    # Hide Windows Search icon
    if ($HideSearchIcon) {
        try {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Force
           
            Write-Host "Windows Search icon hidden successfully." 
        } catch {
            Write-Error "Failed to hide Windows Search icon: $_"
        }
    }

    # Enable Windows Search Indexing
    if ($EnableSearchIndex) {
        try {
            Start-Service -Name "WSearch" -ErrorAction Stop
            gsudo Set-Service -Name "WSearch" -StartupType Automatic -ErrorAction Stop
           
            Write-Host "Windows Search Indexing service enabled successfully." 
        } catch {
            Write-Error "Failed to enable Windows Search Indexing service: $_"
        }
    }

    # Enable dark mode
    if ($EnableDarkMode) {
        try {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Force
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Force
           
            Write-Host "Dark mode enabled successfully." 
        } catch {
            Write-Error "Failed to enable dark mode: $_"
        }
    }

    # Enable full path in Explorer title bar
    if ($EnableFullPathInExplorer) {
        try {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" -Name "FullPathAddress" -Value 1 -Force
           
            Write-Host "Full path in Explorer title bar enabled successfully." 
        } catch {
            Write-Error "Failed to enable full path in Explorer title bar: $_"
        }
    }

    # Show hidden files
    if ($ShowHiddenFiles) {
        try {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Force
          
            Write-Host "Hidden files visibility enabled successfully." 
        } catch {
            Write-Error "Failed to enable hidden files visibility: $_"
        }
    }

    # Show file extensions
    if ($ShowFileExtensions) {
        try {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Force
           
            Write-Host "File extensions visibility enabled successfully." 
        } catch {
            Write-Error "Failed to enable file extensions visibility: $_"
        }
    }

    # Enable long paths
    if ($EnableLongPaths) {
        try {
            gsudo Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -Force
          
            Write-Host "Long paths support enabled successfully." 
        } catch {
            Write-Error "Failed to enable long paths support: $_"
        }
    }

    # Enable Developer Mode
    if ($EnableDeveloperMode) {
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Force
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowAllTrustedApps" -Value 1 -Force
         
            Write-Host "Developer Mode enabled successfully." 
        } catch {
            Write-Error "Failed to enable Developer Mode: $_"
        }
    }

    # Disable Edge tabs in Alt+Tab view
    if ($DisableEdgeTabsInAltTabView) {
        try {
            # Navigate to the registry key and set the property
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "MultiTaskingAltTabFilter" -Value 3

            Write-Host "Edge tabs in Alt+Tab view disabled successfully."
        } catch {
            Write-Error "Failed to disable Edge tabs in Alt+Tab view: $_"
        }
    }

    if ($DisableWindowsFeedback) {
        try {
            gsudo Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowWindowsFeedback" -Value 0 -Force

            Write-Host "Windows Feedback disabled successfully."
        } catch {
            Write-Error "Failed to disable Windows Feedback: $_"
        }
    }

    # Disable Telemetry
    if ($DisableTelemetry) {
        try {
            gsudo Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Force

            Write-Host "Telemetry disabled successfully."
        } catch {
            Write-Error "Failed to disable Telemetry: $_"
        }
    }

    # Restart Windows Explorer to apply changes
    Write-Warning "Restarting Windows Explorer to apply changes..."
    Stop-Process -Name explorer -Force
    Start-Process explorer

    Write-Host "Windows configuration setup completed." -ForegroundColor Green
}

function Set-WallpaperAndLockScreen {
    <#
    .SYNOPSIS
    Sets the Windows wallpaper and lock screen image.

    .DESCRIPTION
    This function allows you to set a custom image as the Windows desktop wallpaper and lock screen image.

    .PARAMETER WallpaperPath
    The file path to the image to be used as the desktop wallpaper.

    .PARAMETER LockScreenPath
    The file path to the image to be used as the lock screen image.

    .EXAMPLE
    Set-WallpaperAndLockScreen -WallpaperPath "$HOME\Images\wallpaper.jpg" -LockScreenPath "$HOME\Images\lockscreen.jpg"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$WallpaperPath,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$LockScreenPath
    )

    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

    public const int SPI_SETDESKWALLPAPER = 20;
    public const int SPIF_UPDATEINIFILE = 0x01;
    public const int SPIF_SENDCHANGE = 0x02;

    public static void SetWallpaper(string path) {
        SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, path, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
    }
}
"@

    Write-Host "Setting desktop wallpaper to $WallpaperPath..." -ForegroundColor Cyan
    try {
        # Set the desktop wallpaper
        [Wallpaper]::SetWallpaper($WallpaperPath)

        Write-Host "Desktop wallpaper set successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to set desktop wallpaper: $_"
    }

    Write-Host "Setting lock screen image to $LockScreenPath..." -ForegroundColor Cyan
    try {
        # Set the lock screen image
        $lockScreenKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
        gsudo Set-ItemProperty -Path $lockScreenKey -Name "LockScreenImagePath" -Value $LockScreenPath -Force
        gsudo Set-ItemProperty -Path $lockScreenKey -Name "LockScreenImageStatus" -Value 1 -Force

        Write-Host "Lock screen image set successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to set lock screen image: $_"
    }
}