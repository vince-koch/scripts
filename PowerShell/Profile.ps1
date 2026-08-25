<#
.SYNOPSIS
    Configures the primary interactive PowerShell environment.
.DESCRIPTION
    Sets console defaults, defines core helpers, and registers local modules for lazy loading.
#>

& {
    function Set-ProfileEncoding {
        try {
            $utf8 = [System.Text.UTF8Encoding]::new()
            [console]::InputEncoding = $utf8
            [console]::OutputEncoding = $utf8
        }
        catch {
            Write-Host 'Failed to set encoding to UTF8' -ForegroundColor Red
            Write-Host $_.Exception.ToString() -ForegroundColor Magenta
        }
    }

    function Show-ProfileWelcome {
        $edition = if ($PSVersionTable.PSEdition -eq 'Desktop') { 'Windows PowerShell' } else { 'PowerShell' }
        $hostEnvironment = if ($env:TERM_PROGRAM -eq 'vscode') {
            "VS Code $env:TERM_PROGRAM_VERSION"
        }
        elseif ($env:VisualStudioEdition) {
            "Visual Studio $env:VisualStudioVersion"
        }
        elseif ($env:WT_SESSION) {
            'Windows Terminal'
        }
        $location = (Get-Location).Path
        $date = Get-Date -Format 'dddd, MMMM d'

        if ($PSStyle) {
            $reset = $PSStyle.Reset
            $dim = $PSStyle.Foreground.BrightBlack
            $hostSuffix = if ($hostEnvironment) { "  ${dim}•${reset}  $($PSStyle.Foreground.Green)$hostEnvironment${reset}" } else { '' }
            Write-Host "${dim}╭─${reset} $($PSStyle.Foreground.Blue)$edition${reset} $($PSStyle.Foreground.Cyan)$($PSVersionTable.PSVersion)${reset}  ${dim}•${reset}  $($PSStyle.Foreground.Magenta)$env:USERNAME@$env:COMPUTERNAME${reset}$hostSuffix"
            Write-Host "${dim}╰─${reset} $($PSStyle.Foreground.Yellow)$date${reset}  ${dim}•${reset}  $($PSStyle.Foreground.Cyan)$location${reset}"
        }
        else {
            $hostSuffix = if ($hostEnvironment) { "  •  $hostEnvironment" } else { '' }
            Write-Host "╭─ $edition $($PSVersionTable.PSVersion)  •  $env:USERNAME@$env:COMPUTERNAME$hostSuffix" -ForegroundColor Cyan
            Write-Host "╰─ $date  •  $location" -ForegroundColor DarkGray
        }
    }

    function Set-ProfileFileStyle {
        if ($PSStyle -and $PSStyle.FileInfo) {
            $PSStyle.FileInfo.Directory = "`e[34m"
        }
    }

    function Register-ProfilePaths {
        param([Parameter(Mandatory)][string]$ProfileRoot)

        $moduleRoot = Join-Path $ProfileRoot 'Modules'
        $separator = [System.IO.Path]::PathSeparator
        $modulePaths = $env:PSModulePath -split [regex]::Escape($separator)
        if ($moduleRoot -notin $modulePaths) {
            $env:PSModulePath = "$moduleRoot$separator$env:PSModulePath"
        }

        $pathEntries = $env:Path -split [regex]::Escape($separator)
        foreach ($pathEntry in @($ProfileRoot, (Join-Path $ProfileRoot 'Scripts'))) {
            if ($pathEntry -notin $pathEntries) {
                $env:Path = "$env:Path$separator$pathEntry"
                $pathEntries += $pathEntry
            }
        }

        $pathExtensions = $env:PATHEXT -split ';'
        if ('.PS1' -notin $pathExtensions) {
            $env:PATHEXT = "$env:PATHEXT;.PS1"
        }
    }

    Set-ProfileEncoding
    Show-ProfileWelcome
    Set-ProfileFileStyle
    Register-ProfilePaths -ProfileRoot $PSScriptRoot

    $global:ScriptsPowerShellProfileLoaded = $true
}

if (Get-Command Set-PSReadLineKeyHandler -ErrorAction Ignore) {
    # Windows Terminal shortcuts. The module auto-loads only in its matching host.
    if ($env:WT_SESSION) {
        Install-WindowsTerminalHotkeys
    }

    # Bookmark insertion shortcut. SpectreConsole loads only when the picker is opened.
    Install-BookmarkHotkeys
}

function shruggie {
    $shrug = '¯\_(ツ)_/¯'
    $shrug | Set-Clipboard
    Write-Host $shrug -NoNewLine
    Write-Host " has been copied to the clipboard" -ForegroundColor DarkGray
}