<#
.SYNOPSIS
    Displays objects as a trimmed table.
.DESCRIPTION
    Formats objects as a table and writes the resulting text to the host.
    Objects may be supplied as an argument or through the pipeline.
.EXAMPLE
    Get-Process | write-table
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
    [Alias('Items')]
    [object[]]$InputObject
)

begin {
    $objects = [System.Collections.Generic.List[object]]::new()
}

process {
    foreach ($item in $InputObject) {
        $objects.Add($item)
    }
}

end {
    Write-Host (($objects | Format-Table | Out-String).Trim())
}
