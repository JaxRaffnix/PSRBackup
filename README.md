# PSRBackup

**PSRBackup** (PowerShell Restic Backup) is a PowerShell module that simplifies and automates Windows backups using [restic](https://restic.net/). It provides easy commands for initializing repositories, managing backup passwords securely, running backups with exclusions, and restoring data.

## Features

- Initialize and manage restic repositories
- Secure password storage using PowerShell SecretManagement
- Exclude files/folders from backup via config/exclude.txt
- Pre-backup checks for large files/folders
- Automated backup, prune, cache cleanup, and integrity check
- Easy restore from any snapshot
- Modular and extensible PowerShell codebase

## Getting Started

### Prerequisites

- [PowerShell 7+](https://github.com/PowerShell/PowerShell)
- [restic](https://restic.net/) (installed automatically if missing)
- [Microsoft.PowerShell.SecretManagement](https://www.powershellgallery.com/packages/Microsoft.PowerShell.SecretManagement) and [SecretStore](https://www.powershellgallery.com/packages/Microsoft.PowerShell.SecretStore) modules

### Installation

Run the setup script as administrator:

```powershell
cd path\to\PSRBackup
.\setup\Install.ps1
```

This copies the module to your PowerShell modules folder and imports it.

### Usage

#### Initialize a Repository

```powershell
Initialize-Repository -RepoPath "D:\Backups\ResticRepo"
```

#### Start a Backup
Excludes can be handled in the exclude file or by adding the file `.resticignore` to a directory.

```powershell
Start-Backup -RepoPath "D:\Backups\ResticRepo" -SourcePath "C:\Users\Jax\Documents" -ExcludeFile "config\exclude.txt"
```

#### Restore a Backup

```powershell
Restore-Backup -RepoPath "D:\Backups\ResticRepo" -TargetPath "C:\Restore"
```

#### Manage Passwords

- Save a password: `Set-ResticPassword -Name "ResticPassword_MyRepo"`
- Retrieve a password: `Get-ResticPassword -Name "ResticPassword_MyRepo"`

## File Structure

- `src/` — Main backup/restore/init scripts
- `helpers/` — Utility functions (password, installation, backup size checks)
- `core/` — Module initialization and manifest
- `config/` — Exclusion lists
- `setup/` — Installation script

## Excluding Files/Folders

Edit [`config/exclude.txt`](config/exclude.txt) to add patterns (one per line) for files/folders to exclude from backups.


## TO DO

**Fix secure string errors. PasswordSecretName should only be a simple string!**

- Kalender Backup?
- Kontakte Backup?
- OneNote Backup
- Playnite Backup: https://api.playnite.link/docs/manual/library/backup.html
- NVIDIA Profile Backup: profile inspector
- Thunderbird Backup
- File Backup
