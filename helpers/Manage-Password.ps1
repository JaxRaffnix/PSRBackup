
function Save-ResticPassword {
    param (
        [string]$Name = "ResticPassword",

        [Parameter()]
        [switch]$Force
    )

    if ((Get-SecretInfo -Name $Name -ErrorAction SilentlyContinue) -and -not $Force) {
        Write-Error "A password with the name '$Name' already exists. Use -Force to overwrite."
        return
    }

    $secStr = Read-Host "Enter Restic password" -AsSecureString
    Set-Secret -Name $Name -Secret $secStr -Force:$Force
}

function Get-ResticPassword {
    param (
        [string]$Name = "ResticPassword"
    )

    if (-not (Get-SecretInfo -Name $Name -ErrorAction SilentlyContinue)) {
        Throw "No password found with the name '$Name'."
    }
    
    $secure = Get-Secret -Name $Name
    return [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    )
}