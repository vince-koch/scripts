<#
.SYNOPSIS
    Configures the primary interactive PowerShell environment.
.DESCRIPTION
    Sets console defaults, defines core helpers, and registers local modules for lazy loading.
#>


# Let's just always have a UTF-8 console encoding
# Set it before importing so we don't trip the warning. Idempotent.
try {
    $utf8 = [System.Text.UTF8Encoding]::new()
    $OutputEncoding = $utf8
    [console]::InputEncoding  = $utf8
    [console]::OutputEncoding = $utf8
    #Write-Host "Encoding set to UTF8" -ForegroundColor DarkGray
} catch {
    Write-Host "Failed to set encoding to UTF8" -ForegroundColor Red
    Write-Host $_.Exception.ToString() -ForegroundColor Magenta
}


# A compact welcome banner with the shell, machine, date, and current location.
$edition = if ($PSVersionTable.PSEdition -eq 'Desktop') { 'Windows PowerShell' } else { 'PowerShell' }
$hostEnvironment = if ($env:TERM_PROGRAM -eq 'vscode') { "VS Code $env:TERM_PROGRAM_VERSION" } elseif ($env:VisualStudioEdition) { "Visual Studio $env:VisualStudioVersion" }
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


# default directory display is terrible, so let's make it blue.
# This is a no-op if the PSStyle object isn't available (e.g., in Windows PowerShell).
if ($PSStyle -and $PSStyle.FileInfo) {
    $PSStyle.FileInfo.Directory = "`e[34m"
}


# Register local modules for PowerShell's built-in command-driven auto-loading.
$moduleRoot = Join-Path $PSScriptRoot 'Modules'
$modulePathSeparator = [System.IO.Path]::PathSeparator
$modulePaths = $env:PSModulePath -split [regex]::Escape($modulePathSeparator)
if ($moduleRoot -notin $modulePaths) {
    $env:PSModulePath = "$moduleRoot$modulePathSeparator$env:PSModulePath"
}

# Register script commands without duplicating entries when the profile is reloaded.
$pathEntries = $env:Path -split [regex]::Escape($modulePathSeparator)
foreach ($pathEntry in @($PSScriptRoot, (Join-Path $PSScriptRoot 'Scripts'))) {
    if ($pathEntry -notin $pathEntries) {
        $env:Path = "$env:Path$modulePathSeparator$pathEntry"
        $pathEntries += $pathEntry
    }
}

$pathExtensions = $env:PATHEXT -split ';'
if ('.PS1' -notin $pathExtensions) {
    $env:PATHEXT = "$env:PATHEXT;.PS1"
}

$global:ScriptsPowerShellProfileLoaded = $true
