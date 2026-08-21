<#
.SYNOPSIS
    Extracts a ZIP archive.
.DESCRIPTION
    Expands an archive into the supplied destination, replacing existing files.
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
