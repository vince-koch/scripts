$bookmarkFile = "$env:USERPROFILE\bookmarks.json"

$bookmarkFile = "$env:USERPROFILE\bookmarks.json"

function Save-Bookmark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    $path = Get-Location
    $bookmarks = @{}

    if (Test-Path $bookmarkFile) {
        $json = Get-Content $bookmarkFile -Raw
        $bookmarks = @{} + ($json | ConvertFrom-Json | ForEach-Object {
                $_.PSObject.Properties | ForEach-Object { @{ $_.Name = $_.Value } }
            } | Merge-Hashtables)
    }

    $bookmarks[$Name] = $path.Path
    $bookmarks | ConvertTo-Json -Depth 10 | Set-Content $bookmarkFile
    Write-Host "Bookmark '$Name' saved for $path" -ForegroundColor Green
}

function GoTo-Bookmark {
    param([string]$Name)
    if (Test-Path $bookmarkFile) {
        $json = Get-Content $bookmarkFile -Raw
        $bookmarks = $json | ConvertFrom-Json

        if ($bookmarks.PSObject.Properties.Name -contains $Name) {
            Set-Location ($bookmarks.$Name)
        }
        else {
            Write-Host "Bookmark '$Name' not found." -ForegroundColor Red
        }
    }
    else {
        Write-Host "No bookmarks found!" -ForegroundColor Red
    }
}

function List-Bookmarks {
    if (Test-Path $bookmarkFile) {
        $json = Get-Content $bookmarkFile -Raw
        $bookmarks = $json | ConvertFrom-Json

        $bookmarks.PSObject.Properties
        | Sort-Object Name
        | ForEach-Object {
            Write-Host ("{0,-20} => {1}" -f $_.Name, $_.Value)
        }
    }
    else {
        Write-Host "No bookmarks available." -ForegroundColor Yellow
    }
}

function Remove-Bookmark {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (!(Test-Path $bookmarkFile)) {
        Write-Error "No bookmarks found!"
        return
    }

    # Load existing bookmarks
    $json = Get-Content $bookmarkFile -Raw
    $bookmarks = $json | ConvertFrom-Json

    if (-not $bookmarks.PSObject.Properties.Name -contains $Name) {
        Write-Error "Bookmark '$Name' not found."
        return
    }

    # Remove the bookmark
    $bookmarks.PSObject.Properties.Remove($Name)

    # Save updated bookmarks (or delete file if empty)
    if ($bookmarks.PSObject.Properties.Count -eq 0) {
        Remove-Item $bookmarkFile -Force
        Write-Host "Bookmark '$Name' removed. No bookmarks left." -ForegroundColor Green
    }
    else {
        $bookmarks | ConvertTo-Json -Depth 10 | Set-Content $bookmarkFile
        Write-Host "Bookmark '$Name' removed." -ForegroundColor Green
    }
}

function Merge-Hashtables {
    param([Parameter(ValueFromPipeline = $true)]$input)

    $merged = @{}
    foreach ($h in $input) {
        foreach ($kv in $h.GetEnumerator()) {
            $merged[$kv.Key] = $kv.Value
        }
    }
    return $merged
}

function Bookmark {
    [CmdletBinding(DefaultParameterSetName = "Dispatch")]
    param(
        [Parameter(Position = 0)]
        [string]$Command,

        [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    switch ($Command) {
        'add' {
            # fall through to save
            $Command = 'save'
            continue
        }

        'save' {
            if ($Args.Count -lt 1) {
                Write-Error "Usage: Bookmark save <name>"
                return
            }
            Save-Bookmark -Name $Args[0]
        }

        'list' {
            List-Bookmarks
        }

        'remove' {
            if ($Args.Count -lt 1) {
                Write-Error "Usage: Bookmark remove <name>"
                return
            }
            Remove-Bookmark -Name $Args[0]
        }

        '' {
            Write-Host "Usage:" -ForegroundColor Yellow
            Write-Host "  Bookmark save <name>     # Save current location"
            Write-Host "  Bookmark add <name>      # (alias for save)"
            Write-Host "  Bookmark list            # List saved bookmarks"
            Write-Host "  Bookmark remove <name>   # Delete a saved bookmark"
            Write-Host "  Bookmark <name>          # Jump to saved bookmark"
        }

        default {
            GoTo-Bookmark -Name $Command
        }
    }
}

New-Alias -Name Bookmarks -Value Bookmark -Force
New-Alias -Name ccd -Value Bookmark -Force

Export-ModuleMember -Function Bookmark
Export-ModuleMember -Alias Bookmarks
Export-ModuleMember -Alias ccd