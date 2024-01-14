function Ps-IsCore {
    $isCore = $PSVersionTable.PSEdition -eq "Core"
    return $isCore
}

function Ps-RestartCommand {
    param (
        [string] $command
    )

    Start-Process -FilePath "$command" -NoNewWindow -UseNewEnvironment
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

Set-Alias -Name reload -Value Ps-Restart
Set-Alias -Name restart -Value Ps-Restart
Set-Alias -Name reset -Value Ps-Restart
Set-Alias -Name pwsh -Value Ps-RestartPwsh
Set-Alias -Name powershell -Value Ps-RestartPowershell
Set-Alias -Name which -Value Ps-Which