# USAGE
# Import-Module $PSScriptRoot\Docker.psm1 -DisableNameChecking -Force

Try-Import-Module $PSScriptRoot\Console.psm1

function Docker-Uninstall {
    param (
        [string] $name
    )

    $ docker rm $name | Out-Host
}

function Docker-Start {
    param (
        [string] $name
    )

    $ docker start $name | Out-Host
}

function Docker-Stop {
    param (
        [string] $name
    )

    $ docker stop $name | Out-Host
}

function Docker-Restart {
    param (
        [string] $name
    )

    $ docker restart $name | Out-Host
}

function MitmProxy-Install {
    Write-Host "1. Install mitmproxy"
    Write-Host "2. Please update your proxy settings"
    Write-Host "3. Point browser at http://mitm.it to install certificate"

    $result = Console-Confirm -Prompt "Would you like to continue with the installation? [y/N]" -Default $false
    if ($result -eq $false) {
        return
    }

    & docker run --name mitmproxy -p 8080:8080 -p 127.0.0.1:8081:8081 mitmproxy/mitmproxy mitmweb --web-host 0.0.0.0 | Out-Host
}

function MitmProxy {
    param (
        [string] $command
    )

    $containerName = "mitmproxy"

    switch ($command) {
        "install" { MitmProxy-Install }
        "start" { Docker-Start -Name $containerName }
        "restart" { Docker-Stop -Name $containerName }
        "stop" { Docker-Stop -Name $containerName }
        "uninstall" { Docker-Uninstall -Name $containerName }
        default {
            Write-Host "MitmProxy [command]"
            Write-Host ""
            Write-Host "    command"
            Write-Host "        install"
            Write-Host "        start"
            Write-Host "        restart"
            Write-Host "        stop"
            Write-Host "        uninstall"
        }
    }
}

Export-ModuleMember -Function Docker-Uninstall
Export-ModuleMember -Function Docker-Start
Export-ModuleMember -Function Docker-Stop
Export-ModuleMember -Function Docker-Restart
Export-ModuleMember -Function MitmProxy