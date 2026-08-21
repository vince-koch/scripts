<#
.SYNOPSIS
    Displays objects as trimmed text.
.DESCRIPTION
    Converts objects to their normal PowerShell text representation and writes
    the trimmed result to the host. Objects may also be supplied by pipeline.
.EXAMPLE
    Get-Date | write-objects
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
    Write-Host (($objects | Out-String).Trim())
}
