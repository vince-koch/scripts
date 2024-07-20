function Ps-IsCore {
    $isCore = $PSVersionTable.PSEdition -eq "Core"
    return $isCore
}

function Ps-RestartCommand {
    param (
        [string] $command
    )

    #Start-Process -FilePath "$command" -NoNewWindow -UseNewEnvironment
    Start-Process -FilePath "$command" -NoNewWindow
    Write-Host "Exiting parent process $PID"
    Write-Host ""
    exit
}

function Ps-Restart {
    $path = (Get-Process -Id $PID).Path
    Ps-RestartCommand($path)
}

function Ps-RestartPwsh {
    Ps-RestartCommand("pwsh")
}

function Ps-RestartPowershell {
    Ps-RestartCommand("powershell")
}

function Ps-Which {
    param ([string] $command)
    (Get-Command $command).Path
}

# update to a specific version of powershell
function Ps-Update-Version {
    param (
        [Parameter(Mandatory = $true)]
        [string] $version
    )

    winget install Microsoft.PowerShell --version $version
}

# update powershell
function Ps-Update {
    param (
        [Parameter(Mandatory = $false)]
        [string] $version = $null
    )

    if ([string]::IsNullOrWhiteSpace($version)) {
        Write-Host "No version specified, searching for available versions..." -ForegroundColor "Yellow"
        Write-Host ""
        winget search Microsoft.PowerShell
    }
    
    Update-PowerShell-Version
}


Export-ModuleMember -Function Ps-IsCore
Export-ModuleMember -Function Ps-Restart
Export-ModuleMember -Function Ps-RestartPwsh
Export-ModuleMember -Function Ps-RestartPowershell
Export-ModuleMember -Function Ps-Which
Export-ModuleMember -Function Ps-Update-Version
Export-ModuleMember -Function Ps-Update

Set-Alias -Name reload -Value Ps-Restart
Set-Alias -Name restart -Value Ps-Restart
Set-Alias -Name reset -Value Ps-Restart
Set-Alias -Name pwsh -Value Ps-RestartPwsh
Set-Alias -Name powershell -Value Ps-RestartPowershell
Set-Alias -Name which -Value Ps-Which
Set-Alias -Name update -Value Ps-Update
