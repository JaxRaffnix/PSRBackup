
$ModulePath = $PSScriptRoot

$HelperFolder = "$ModulePath\helpers"
foreach ($file in (Get-ChildItem -Path $HelperFolder -Filter '*.ps1')) {
    . $file.FullName
}

$SourceFolder = "$ModulePath\src"
foreach ($file in (Get-ChildItem -Path $SourceFolder -Filter '*.ps1')) {
    . $file.FullName
}