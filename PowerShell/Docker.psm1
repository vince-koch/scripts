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

function Docker-DotNet {
    param (
        [string] $directory = $null,
        [string] $image = "mcr.microsoft.com/dotnet/sdk",
        [string] $tag = "8.0",
        [string] $shell = "/bin/bash"
    )

    if ([string]::IsNullOrWhiteSpace($directory)) {
        $directory = ${PWD}
    }

    switch ($tag) {
        "8" { $tag = "8.0" }
        "9" { $tag = "9.0" }
        "10" { $tag = "10.0" }
        default { }
    }

    & docker run --rm -v "${directory}:/source" -w /source -it "${image}:${tag}" $shell
}

function Docker-Python {
    [CmdletBinding()] param (
        [string] $Script = $null,             # If provided, run this Python script; otherwise open shell
        [string] $Directory = $null,          # Host directory to mount
        [string] $Image = "python:3.12-slim", # Python image tag
        [string] $Shell = "/bin/bash"         # Shell for interactive mode when no script supplied
    )

    if ([string]::IsNullOrWhiteSpace($Directory)) {
        $Directory = $PWD
    }

    if (!(Test-Path -LiteralPath $Directory)) {
        throw "Directory '$Directory' not found"
    }

    $runScript = -not [string]::IsNullOrWhiteSpace($Script)
    if ($runScript) {
        $scriptPath = Join-Path $Directory $Script
        if (!(Test-Path -LiteralPath $scriptPath)) {
            throw "Script '$Script' not found in '$Directory'"
        }
    }

    Write-Host "Using image: $Image" -ForegroundColor Cyan
    Write-Host "Mounting host directory: $Directory" -ForegroundColor Cyan

    $volume = "${Directory}:/work"
    $commonArgs = @("run", "--rm", "-v", $volume, "-w", "/work")

    if ($runScript) {
        Write-Host "Executing Python script '$Script' in container..." -ForegroundColor Green
        & docker @commonArgs $Image python "$Script"
    }
    else {
        Write-Host "Starting interactive Python container (no script provided)..." -ForegroundColor Green
        & docker @commonArgs -it $Image $Shell
    }
}

Export-ModuleMember -Function Docker-Uninstall
Export-ModuleMember -Function Docker-Start
Export-ModuleMember -Function Docker-Stop
Export-ModuleMember -Function Docker-Restart
Export-ModuleMember -Function MitmProxy
Export-ModuleMember -Function Docker-DotNet
Export-ModuleMember -Function Docker-Python



# docker run --name localstack -it -p 127.0.0.1:4566:4566 -p 127.0.0.1:4510-4559:4510-4559 -v /var/run/docker.sock:/var/run/docker.sock localstack/localstack