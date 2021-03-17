# USAGE
# Import-Module $PSScriptRoot\Elevate.psm1 -DisableNameChecking -Force
# $command = $PSCommandPath
# $arguments = $PsBoundParameters.Values + $args
# Ensure-Elevated $command $arguments

function Ensure-Elevated {
    [CmdletBinding()]
    param ( 
        [string] $command,
        [string[]] $arguments
    )

    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    {
        # relaunch as an elevated process:
        Write-Host "Requires elevation"
        $arguments = ,"-File $($command)" + $arguments
        Start-Process powershell.exe -Verb RunAs $arguments
        Exit
    }
}

function Is-Elevated {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

Export-ModuleMember -Function Ensure-Elevated
Export-ModuleMember -Function Is-Elevated