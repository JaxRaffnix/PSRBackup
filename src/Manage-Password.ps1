
function Save-ResticPassword {
    param (
        [string]$Name = "ResticPassword"
    )
    $secStr = Read-Host "Enter Restic password" -AsSecureString
    Set-Secret -Name $Name -Secret $secStr
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