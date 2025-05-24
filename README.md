# PSRBackup

**PSRBackup** (PowerShell Restic Backup) is a PowerShell module that simplifies and automates Windows backups using [restic](https://restic.net/). It provides easy commands for initializing repositories, managing backup passwords securely, running backups with exclusions, and restoring data.

## Features

- 🚀 Initialize and manage restic repositories
- 🔐 Secure password storage using PowerShell SecretManagement
- 🚫 Exclude files/folders from backup via config/exclude.txt
- 📏 Pre-backup checks for large files/folders
- 🤖 Automated backup, prune, cache cleanup, and integrity check
- ♻️ Easy restore from any snapshot
- 
## Getting Started

### Prerequisites

- 💻 [PowerShell 7+](https://github.com/PowerShell/PowerShell)
- 📦 [restic](https://restic.net/) (installed automatically if missing)
- 🗝️ [Microsoft.PowerShell.SecretManagement](https://www.powershellgallery.com/packages/Microsoft.PowerShell.SecretManagement) and [SecretStore](https://www.powershellgallery.com/packages/Microsoft.PowerShell.SecretStore) modules

### Installation

Run the setup script as administrator:

```powershell
cd path\to\PSRBackup
.\setup\Install.ps1
```

This copies the module to your PowerShell modules folder and imports it.

### Usage

#### 🚀 Initialize a Repository

```powershell
Initialize-Repository -RepoPath "D:\Backups\ResticRepo"
```

#### 📦 Start a Backup
Excludes can be handled in the exclude file or by adding the file `.resticignore` to a directory.

```powershell
Start-Backup -RepoPath "D:\Backups\ResticRepo" -SourcePath "C:\Users\Jax\Documents" -ExcludeFile "config\exclude.txt"
```

#### ♻️ Restore a Backup

```powershell
Restore-Backup -RepoPath "D:\Backups\ResticRepo" -TargetPath "C:\Restore"
```

## Excluding Files/Folders

Edit [`config/exclude.txt`](config/exclude.txt) to add patterns (one per line) for files/folders to exclude from backups.

## TO DO

- calender und kontake backup?

- 🗒️ OneNote Backup
- 🎮 Playnite Backup: https://api.playnite.link/docs/manual/library/backup.html
- 🖥️ NVIDIA Profile Backup: profile inspector
- Taskbar settings: C:\Users\Jax\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar

### Automate script execution

- create a main.ps1 file that runs with personal configurations
- create a scheduled task
- use a burnt toast notification
- check for connected volume
```
$desiredLabel = "MyBackupDrive"
$drive = Get-Volume | Where-Object { $_.FileSystemLabel -eq $desiredLabel }

if ($drive) {
    Write-Host "External backup drive '$desiredLabel' connected at $($drive.DriveLetter):"
    # Start backup
} else {
    Write-Warning "Backup drive '$desiredLabel' not found."
}
```

- use a loop in the scheduled task
```
$driveLetter = "E:"
$maxWaitMinutes = 30
$intervalSeconds = 10
$elapsed = 0

while ($elapsed -lt ($maxWaitMinutes * 60)) {
    if (Test-Path $driveLetter) {
        Write-Host "Drive found. Starting backup..."
        # Call backup here
        break
    }
    Start-Sleep -Seconds $intervalSeconds
    $elapsed += $intervalSeconds
}
if ($elapsed -ge ($maxWaitMinutes * 60)) {
    Write-Warning "External drive not connected after waiting $maxWaitMinutes minutes. Backup aborted."
}
```

## Emoji Legend

| Emoji | Meaning                       |
|-------|-------------------------------|
| ⬇️    | Installing                    |
| 📥    | Importing                     |
| ❌    | Error                         |
| ⚠️    | Warning                       |
| ✅    | Success                       |
| 🔄    | Reset                         |
| 🔍    | File scan, integrity check    |
| 🚨    | Alert                         |
| 🗑️    | Delete                        |
| 📁    | Copy, move, create            |
| 📝    | Logging                       |
| 🧹    | Cleanup                       |
| 🚀    | Initialize                    |
| 📦    | Backup operation              |
| ♻️    | Restore operation             |
| 🔐    | Passwords                     |
| 🗝️    | Key management                |
| 🛠️    | Helper/utilities              |
| 🗒️    | Notes/OneNote                 |
| 📅    | Calendar                      |
| 👥    | Contacts                      |
| 🎮    | Playnite                 |
| 🖥️    | System/NVIDIA                 |
| 📨    | Thunderbird             |

