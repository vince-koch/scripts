<#
.SYNOPSIS
    Enables file and folder icons in the interactive shell.
.DESCRIPTION
    Reuses the primary profile, then loads Terminal-Icons or offers to install it.
#>
if (-not $global:ScriptsPowerShellProfileLoaded) {
    . (Join-Path $PSScriptRoot 'Profile.ps1')
}

# Terminal-Icons
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module -Name Terminal-Icons
} 
else {
    Import-Module PwshSpectreConsole -ErrorAction Stop
    Write-Host "Terminal-Icons module is not installed." -ForegroundColor Red
    $installNow = Read-SpectreConfirm `
        -Message 'Would you like to install Terminal-Icons now?' `
        -DefaultAnswer 'y'
    if ($installNow -eq $true) {
        Install-Module -Name Terminal-Icons -Repository PSGallery -Scope CurrentUser -Force
        Import-Module -Name Terminal-Icons
    }
    elseif (Ps-IsCore) {
        # fix default directory coloring as best we can quickly and easily
        $PSStyle.FileInfo.Directory = "`e[94;3;4m"
    }
}
