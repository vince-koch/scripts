<#
.SYNOPSIS
    Manages named filesystem bookmarks and bookmark-related shortcuts.
.DESCRIPTION
    Provides commands for saving, listing, selecting, and navigating to bookmarks,
    plus an optional PSReadLine shortcut for inserting a bookmark at the cursor.
#>

$jsonModulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'Json\Json.psm1'
Import-Module $jsonModulePath -DisableNameChecking -ErrorAction Stop

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

function Get-Bookmark {
    <#
    .SYNOPSIS
        Returns saved bookmarks as objects containing Name and Path.
    #>
    [CmdletBinding()]
    param()

    if (-not (Test-Path $bookmarkFile)) {
        return
    }

    $bookmarks = Json-LoadHashtable -Path $bookmarkFile
    foreach ($name in ($bookmarks.Keys | Sort-Object)) {
        [PSCustomObject]@{
            Name = $name
            Path = $bookmarks[$name]
        }
    }
}

function List-Bookmarks {
    if (-not (Test-Path $bookmarkFile)) {
        Write-Host "No bookmarks available." -ForegroundColor Yellow
        return
    }
    
    Get-Bookmark | Format-Table -AutoSize
}

function Select-Bookmark {
    <#
    .SYNOPSIS
        Displays a searchable bookmark picker and returns the selected bookmark.
    #>
    [CmdletBinding()]
    param()

    $bookmarks = @(Get-Bookmark)
    if ($bookmarks.Count -eq 0) {
        Write-Host 'No bookmarks available.' -ForegroundColor Yellow
        return
    }

    Import-Module PwshSpectreConsole -ErrorAction Stop

    $nameWidth = ($bookmarks.Name | ForEach-Object Length | Measure-Object -Maximum).Maximum
    $choices = @(foreach ($bookmark in $bookmarks) {
        '{0}  {1}' -f $bookmark.Name.PadRight($nameWidth), $bookmark.Path
    })

    $selection = Read-SpectreSelection `
        -Message 'Insert bookmark' `
        -Choices $choices `
        -EnableSearch `
        -Color 'Cyan1'

    if ($null -eq $selection) { return }
    $bookmarks[[array]::IndexOf($choices, [string]$selection)]
}

function Install-BookmarkHotkeys {
    <#
    .SYNOPSIS
        Installs the Ctrl+Alt+B PSReadLine bookmark insertion shortcut.
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-Command Set-PSReadLineKeyHandler -ErrorAction Ignore)) { return }

    Set-PSReadLineKeyHandler `
        -Chord 'Ctrl+Alt+b' `
        -BriefDescription 'InsertBookmark' `
        -LongDescription 'Select and insert a filesystem bookmark at the cursor' `
        -ScriptBlock {
            param($key, $arg)

            try {
                $bookmark = Select-Bookmark
                if ($null -eq $bookmark) { return }

                $line = $null
                $cursor = 0
                [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
                $beforeCursor = $line.Substring(0, $cursor)

                $value = if ($beforeCursor -match '(?i)(?:^|[;|&])\s*(?:ccd|bookmark|bookmarks)\s+[^\s]*$') {
                    [string]$bookmark.Name
                }
                else {
                    [string]$bookmark.Path
                }

                $quotedValue = "'" + $value.Replace("'", "''") + "'"
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quotedValue)
            }
            catch {
                [console]::Beep()
            }
        }
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

Export-ModuleMember -Function Bookmark, Get-Bookmark, Select-Bookmark, Install-BookmarkHotkeys
Export-ModuleMember -Alias Bookmarks, ccd
