function Find-File {
    <#
    .SYNOPSIS
        Finds the first matching file in a collection of directories.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$FileName,

        [Parameter(Mandatory, Position = 1)]
        [string[]]$Paths
    )

    Write-Verbose "Searching $($Paths.Length) paths for $FileName"
    foreach ($path in $Paths) {
        if ([string]::IsNullOrWhiteSpace($path)) { continue }

        try {
            $fullPath = Join-Path $path $FileName -ErrorAction Stop
            if ([System.IO.File]::Exists($fullPath)) {
                return [System.IO.Path]::GetFullPath($fullPath)
            }
        }
        catch {
            Write-Verbose "Unable to search '$path': $($_.Exception.Message)"
        }
    }

    return $null
}
