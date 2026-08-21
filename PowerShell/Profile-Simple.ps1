<#
.SYNOPSIS
    Loads a minimal interactive PowerShell environment.
.DESCRIPTION
    Reuses the primary profile and replaces its prompt with a compact built-in prompt.
#>
if (-not $global:ScriptsPowerShellProfileLoaded) {
    . (Join-Path $PSScriptRoot 'Profile.ps1')
}


function global:Prompt {
    if ($?) { $lastExit = "[OK]" } else { $lastExit = "[ERR]" }
    if ($?) { $lastExitColor = "Green" } else { $lastExitColor = "Red" }
    Write-Host "$lastExit" -ForegroundColor $lastExitColor -NoNewLine                           # last exit code

    Write-Host " PS" -ForegroundColor Blue -NoNewLine                                           # powershell indicator
    Write-Host " $([System.Environment]::UserName)" -ForegroundColor Magenta -NoNewLine         # user name
    Write-Host " $([System.Environment]::MachineName)" -ForegroundColor DarkMagenta -NoNewLine  # machine name
    Write-Host " $((Get-Date).ToString("HH:mm"))" -ForegroundColor Gray -NoNewLine              # current time
    Write-Host " $((Get-Location).Path)" -ForegroundColor Cyan -NoNewLine                       # current folder
    Write-Host ">" -ForegroundColor White -NoNewLine                                             # prompt indicator

    Return " "
}
