
$ModulePath = $PSScriptRoot

$HelperFolder = "$ModulePath\helpers"
foreach ($file in (Get-ChildItem -Path $HelperFolder -Filter '*.ps1')) {
    . $file.FullName
}

$ResticFolder = "$ModulePath\restic"
foreach ($file in (Get-ChildItem -Path $ResticFolder -Filter '*.ps1')) {
    . $file.FullName
}

$ProfileFolder = "$ModulePath\profiles"
foreach ($file in (Get-ChildItem -Path $ProfileFolder -Filter '*.ps1')) {
    . $file.FullName
}