Try-Import-Module $PSScriptRoot\Json.psm1

$bookmarkFile = "$env:USERPROFILE\.bookmarks.json"

function Save-Bookmark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    $bookmarks = Json-LoadHashtable -Path $bookmarkFile
    $bookmarks[$Name] = (Get-Location).Path
    Json-SaveHashtable -Path $bookmarkFile -Hashtable $bookmarks
    
    Write-Host "Bookmark '$Name' saved for $($bookmarks[$Name])" -ForegroundColor Green
}

function GoTo-Bookmark {
    param(
        [string] $Name
    )

    if (-not (Test-Path $bookmarkFile)) {
        Write-Host "No bookmarks available." -ForegroundColor Yellow
        return
    }

    $bookmarks = Json-LoadPsObject -Path $bookmarkFile

    if ($bookmarks.PSObject.Properties.Name -contains $Name) {
        Set-Location ($bookmarks.$Name)
    }
    else {
        Write-Host "Bookmark '$Name' not found." -ForegroundColor Red
    }
}

function List-Bookmarks {
    if (-not (Test-Path $bookmarkFile)) {
        Write-Host "No bookmarks available." -ForegroundColor Yellow
        return
    }
    
    $bookmarks = Json-LoadHashtable -Path $bookmarkFile

    $bookmarks.Keys
        | Sort-Object
        | ForEach-Object {
            [PSCustomObject]@{
                Name = $_
                Path = $bookmarks[$_]
            }
        }
        | Format-Table -AutoSize
}

function Remove-Bookmark {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not (Test-Path $bookmarkFile)) {
        Write-Host "No bookmarks available." -ForegroundColor Yellow
        return
    }

    $bookmarks = Json-LoadPsObject -Path $bookmarkFile

    if (-not $bookmarks.PSObject.Properties.Name -contains $Name) {
        Write-Error "Bookmark '$Name' not found."
        return
    }

    $bookmarks.PSObject.Properties.Remove($Name)
    Json-SavePsObject -Path $bookmarkFile -Object $bookmarks
    Write-Host "Bookmark '$Name' removed." -ForegroundColor Green
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
            if ($Args.Count -lt 1) {
                Write-Error "Usage: Bookmark save <name>"
                return
            }
            Save-Bookmark -Name $Args[0]
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

        { $_ -in 'help', '--help', '/help', '/?', '' } {
            Write-Host "Usage:" -ForegroundColor Yellow
            Write-Host "    Bookmark save <name>     # Save current location"
            Write-Host "    Bookmark add <name>      # (alias for save)"
            Write-Host "    Bookmark list            # List saved bookmarks"
            Write-Host "    Bookmark remove <name>   # Delete a saved bookmark"
            Write-Host "    Bookmark <name>          # Jump to saved bookmark"
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
