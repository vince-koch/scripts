# USAGE
# Import-Module $PSScriptRoot\Elevate.psm1 -DisableNameChecking -Force
# Ensure-Elevated $MyInvocation.MyCommand.Path

function Ensure-Elevated {
    [CmdletBinding()]
    param ( 
        [string] $scriptPath
    )

    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    {
        # relaunch as an elevated process:
        Write-Host "Requires elevation"
        Start-Process powershell.exe "-File",('"{0}"' -f $scriptPath) -Verb RunAs
        Exit
    }
    else
    {
        Write-Host "Already elevated"
    }
}

Export-ModuleMember -Function Ensure-Elevated