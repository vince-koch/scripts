function Expand-ZipFile {
    <#
    .SYNOPSIS
        Extracts a ZIP archive.
    .EXAMPLE
        unzip archive.zip .\output
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$ZipFile,

        [Parameter(Position = 1)]
        [string]$Destination = '.'
    )

    Expand-Archive -Path $ZipFile -DestinationPath $Destination -Force
}
