function Backup-ApplicationData {
    <#
    Only a single snaoshot will be safed and overwritten.
    #>
    
    param (
        $SourcePath,    
        $DesinationPath
    )

    if (-not (Test-Path $SourcePath)) {
        Write-Error "SourcePath $SourcePath does not exist."
    }

    
}