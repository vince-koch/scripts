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



function Start-DockerInteractive {
    # .SYNOPSIS
    # Interactively prompts user to configure and start a Docker container
    # .PARAMETER ImageName
    # Docker image name
    # .PARAMETER DefaultTag
    # Default image tag
    # .PARAMETER DefaultName
    # Default container name
    # .PARAMETER DefaultPorts
    # Array of default port mappings
    # .PARAMETER DefaultEnvVars
    # Array of default environment variables
    # .PARAMETER DefaultVolumePath
    # Suggested container volume path
    param(
        [Parameter(Mandatory=$true)]
        [string]$ImageName,
        [string]$DefaultTag = "latest",
        [string]$DefaultName = "",
        [string[]]$DefaultPorts = @(),
        [string[]]$DefaultEnvVars = @(),
        [string]$DefaultVolumePath = ""
    )
    
    # Initialize configuration with defaults
    $config = @{
        Tag = $DefaultTag
        Name = $DefaultName
        Detached = $true
        Interactive = $false
        Ports = [System.Collections.ArrayList]@($DefaultPorts)
        EnvVars = [System.Collections.ArrayList]@($DefaultEnvVars)
        Volumes = [System.Collections.ArrayList]@()
        RestartPolicy = "unless-stopped"
    }
    
    function Show-Configuration {
        Clear-Host
        Write-Host "=== Docker Container Configuration: $ImageName ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host " 1. Image Tag:        " -NoNewline; Write-Host $config.Tag -ForegroundColor Yellow
        Write-Host " 2. Container Name:   " -NoNewline; Write-Host $(if($config.Name){"$($config.Name)"}else{"(none)"}) -ForegroundColor Yellow
        Write-Host " 3. Mode:             " -NoNewline; Write-Host $(if($config.Detached){"Detached"}else{"Interactive"}) -ForegroundColor Yellow
        Write-Host " 4. Restart Policy:   " -NoNewline; Write-Host $config.RestartPolicy -ForegroundColor Yellow
        Write-Host ""
        Write-Host " 5. Ports:" -ForegroundColor Cyan
        if ($config.Ports.Count -gt 0) {
            foreach ($port in $config.Ports) {
                Write-Host "      $port" -ForegroundColor Gray
            }
        } else {
            Write-Host "      (none)" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host " 6. Environment Variables:" -ForegroundColor Cyan
        if ($config.EnvVars.Count -gt 0) {
            foreach ($env in $config.EnvVars) {
                $parts = $env -split '=', 2
                Write-Host "      $($parts[0]) = $($parts[1])" -ForegroundColor Gray
            }
        } else {
            Write-Host "      (none)" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host " 7. Volumes:" -ForegroundColor Cyan
        if ($config.Volumes.Count -gt 0) {
            foreach ($vol in $config.Volumes) {
                Write-Host "      $vol" -ForegroundColor Gray
            }
        } else {
            Write-Host "      (none)" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "───────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host " [1-7] Edit setting  |  [R] Run  |  [Q] Quit" -ForegroundColor DarkGray
        Write-Host "───────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host ""
    }
    
    function Edit-Tag {
        $newTag = Read-Host "Enter image tag (current: $($config.Tag))"
        if (-not [string]::IsNullOrWhiteSpace($newTag)) {
            $config.Tag = $newTag
        }
    }
    
    function Edit-Name {
        $newName = Read-Host "Enter container name (current: $(if($config.Name){$config.Name}else{'none'}))"
        $config.Name = $newName
    }
    
    function Edit-Mode {
        Write-Host "1. Detached (background)"
        Write-Host "2. Interactive (foreground with TTY)"
        $choice = Read-Host "Select mode (1-2)"
        if ($choice -eq '2') {
            $config.Detached = $false
            $config.Interactive = $true
        } else {
            $config.Detached = $true
            $config.Interactive = $false
        }
    }
    
    function Edit-RestartPolicy {
        Write-Host "1. no"
        Write-Host "2. always"
        Write-Host "3. unless-stopped"
        Write-Host "4. on-failure"
        $choice = Read-Host "Select restart policy (1-4)"
        $config.RestartPolicy = switch ($choice) {
            '1' { 'no' }
            '2' { 'always' }
            '3' { 'unless-stopped' }
            '4' { 'on-failure' }
            default { $config.RestartPolicy }
        }
    }
    
    function Edit-Ports {
        Write-Host "Port Mappings:"
        Write-Host "[A] Add port  [D] Delete port  [C] Clear all  [Enter] Done"
        
        while ($true) {
            Write-Host ""
            for ($i = 0; $i -lt $config.Ports.Count; $i++) {
                Write-Host "  $($i+1). $($config.Ports[$i])" -ForegroundColor Gray
            }
            
            $action = Read-Host "`nAction"
            switch -Wildcard ($action.ToUpper()) {
                'A*' {
                    $hostPort = Read-Host "  Host port"
                    $containerPort = Read-Host "  Container port"
                    if ($hostPort -and $containerPort) {
                        [void]$config.Ports.Add("${hostPort}:${containerPort}")
                    }
                }
                'D*' {
                    $idx = Read-Host "  Delete which number?"
                    $num = [int]$idx - 1
                    if ($num -ge 0 -and $num -lt $config.Ports.Count) {
                        $config.Ports.RemoveAt($num)
                    }
                }
                'C*' {
                    $config.Ports.Clear()
                }
                default { return }
            }
        }
    }
    
    function Edit-EnvVars {
        Write-Host "Environment Variables:"
        Write-Host "[A] Add variable  [E] Edit variable  [D] Delete variable  [C] Clear all  [Enter] Done"
        
        while ($true) {
            Write-Host ""
            for ($i = 0; $i -lt $config.EnvVars.Count; $i++) {
                $parts = $config.EnvVars[$i] -split '=', 2
                Write-Host "  $($i+1). $($parts[0]) = $($parts[1])" -ForegroundColor Gray
            }
            
            $action = Read-Host "`nAction"
            switch -Wildcard ($action.ToUpper()) {
                'A*' {
                    $name = Read-Host "  Variable name"
                    $value = Read-Host "  Variable value"
                    if ($name) {
                        [void]$config.EnvVars.Add("${name}=${value}")
                    }
                }
                'E*' {
                    $idx = Read-Host "  Edit which number?"
                    $num = [int]$idx - 1
                    if ($num -ge 0 -and $num -lt $config.EnvVars.Count) {
                        $parts = $config.EnvVars[$num] -split '=', 2
                        $newValue = Read-Host "  New value for $($parts[0]) (current: $($parts[1]))"
                        if (-not [string]::IsNullOrWhiteSpace($newValue)) {
                            $config.EnvVars[$num] = "$($parts[0])=$newValue"
                        }
                    }
                }
                'D*' {
                    $idx = Read-Host "  Delete which number?"
                    $num = [int]$idx - 1
                    if ($num -ge 0 -and $num -lt $config.EnvVars.Count) {
                        $config.EnvVars.RemoveAt($num)
                    }
                }
                'C*' {
                    $config.EnvVars.Clear()
                }
                default { return }
            }
        }
    }
    
    function Edit-Volumes {
        Write-Host "Volume Mounts:"
        if ($DefaultVolumePath) {
            Write-Host "Suggested container path: $DefaultVolumePath" -ForegroundColor Yellow
        }
        Write-Host "[A] Add volume  [D] Delete volume  [C] Clear all  [Enter] Done"
        
        while ($true) {
            Write-Host ""
            for ($i = 0; $i -lt $config.Volumes.Count; $i++) {
                Write-Host "  $($i+1). $($config.Volumes[$i])" -ForegroundColor Gray
            }
            
            $action = Read-Host "`nAction"
            switch -Wildcard ($action.ToUpper()) {
                'A*' {
                    $hostPath = Read-Host "  Host path"
                    $containerPath = Read-Host "  Container path$(if($DefaultVolumePath){" (suggested: $DefaultVolumePath)"})"
                    if ([string]::IsNullOrWhiteSpace($containerPath) -and $DefaultVolumePath) {
                        $containerPath = $DefaultVolumePath
                    }
                    if ($hostPath -and $containerPath) {
                        [void]$config.Volumes.Add("${hostPath}:${containerPath}")
                    }
                }
                'D*' {
                    $idx = Read-Host "  Delete which number?"
                    $num = [int]$idx - 1
                    if ($num -ge 0 -and $num -lt $config.Volumes.Count) {
                        $config.Volumes.RemoveAt($num)
                    }
                }
                'C*' {
                    $config.Volumes.Clear()
                }
                default { return }
            }
        }
    }
    
    # Main configuration loop
    $wasRunRequested = $false
    while (-not $wasRunRequested) {
        Show-Configuration
        $choice = Read-Host "Select option"
        
        switch ($choice.Trim().ToUpper()) {
            '1' { Edit-Tag }
            '2' { Edit-Name }
            '3' { Edit-Mode }
            '4' { Edit-RestartPolicy }
            '5' { Edit-Ports }
            '6' { Edit-EnvVars }
            '7' { Edit-Volumes }
            'R' { $wasRunRequested = $true }
            'Q' { 
                Write-Host "`nCancelled." -ForegroundColor Yellow
                return 
            }
            default {
                Write-Host "Invalid option. Please select 1-7, R, or Q" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
    
    # Build and execute the docker run command
    $fullImage = "${ImageName}:$($config.Tag)"
    $cmd = "docker run"
    
    if ($config.Detached) { $cmd += " -d" }
    if ($config.Interactive) { $cmd += " -it" }
    if ($config.Name) { $cmd += " --name $($config.Name)" }
    if ($config.RestartPolicy -ne 'no') { $cmd += " --restart $($config.RestartPolicy)" }
    
    foreach ($port in $config.Ports) {
        $cmd += " -p $port"
    }
    
    foreach ($volume in $config.Volumes) {
        $cmd += " -v `"$volume`""
    }
    
    foreach ($env in $config.EnvVars) {
        $cmd += " -e `"$env`""
    }
    
    $cmd += " $fullImage"
    
    Clear-Host
    Write-Host "=== Generated Docker Command ===" -ForegroundColor Cyan
    Write-Host $cmd -ForegroundColor Yellow
    Write-Host ""
    
    $execute = Read-Host "Execute this command? (y/n, default: y)"
    if ([string]::IsNullOrWhiteSpace($execute) -or $execute -eq 'y') {
        Write-Host "`nExecuting..." -ForegroundColor Green
        Invoke-Expression $cmd
        Write-Host "`n✓ Container started!" -ForegroundColor Green
    } else {
        Write-Host "`nCommand not executed." -ForegroundColor Yellow
    }
}

<#
function Start-DockerInteractive {
    # .SYNOPSIS
    #     Interactively prompts user to configure and start a Docker container
    # .PARAMETER ImageName
    #     Docker image name
    # .PARAMETER DefaultTag
    #     Default image tag
    # .PARAMETER DefaultName
    #     Default container name
    # .PARAMETER DefaultPorts
    #     Array of default port mappings
    # .PARAMETER DefaultEnvVars
    #     Array of default environment variables
    # .PARAMETER DefaultVolumePath
    #     Suggested container volume path
    param(
        [Parameter(Mandatory=$true)]
        [string]$ImageName,
        [string]$DefaultTag = "latest",
        [string]$DefaultName = "",
        [string[]]$DefaultPorts = @(),
        [string[]]$DefaultEnvVars = @(),
        [string]$DefaultVolumePath = ""
    )
    
    Write-Host "`n=== Starting $ImageName Container ===" -ForegroundColor Cyan
    
    # Image tag
    $tag = Read-Host "`nImage tag (default: $DefaultTag)"
    if ([string]::IsNullOrWhiteSpace($tag)) { $tag = $DefaultTag }
    $fullImage = "${ImageName}:${tag}"
    
    # Container name
    $namePrompt = if ($DefaultName) { "Container name (default: $DefaultName)" } else { "Container name (optional)" }
    $containerName = Read-Host $namePrompt
    if ([string]::IsNullOrWhiteSpace($containerName) -and $DefaultName) { 
        $containerName = $DefaultName 
    }
    
    # Detached mode
    $detached = Read-Host "`nRun in detached mode? (y/n, default: y)"
    $detached = if ([string]::IsNullOrWhiteSpace($detached) -or $detached -eq 'y') { $true } else { $false }
    
    # Interactive mode (if not detached)
    $interactive = $false
    if (-not $detached) {
        $interactive = Read-Host "Run in interactive mode with TTY? (y/n)"
        $interactive = $interactive -eq 'y'
    }
    
    # Port mappings
    Write-Host "`n--- Port Configuration ---" -ForegroundColor Cyan
    $ports = @()
    
    if ($DefaultPorts.Count -gt 0) {
        Write-Host "Suggested ports:" -ForegroundColor Yellow
        foreach ($port in $DefaultPorts) {
            Write-Host "  $port" -ForegroundColor Gray
        }
        $useDefaults = Read-Host "Use these ports? (y/n, default: y)"
        if ([string]::IsNullOrWhiteSpace($useDefaults) -or $useDefaults -eq 'y') {
            $ports = $DefaultPorts
        }
    }
    
    $addPort = Read-Host "Add/modify port mappings? (y/n)"
    while ($addPort -eq 'y') {
        $hostPort = Read-Host "  Host port"
        $containerPort = Read-Host "  Container port"
        if ($hostPort -and $containerPort) {
            $ports += "${hostPort}:${containerPort}"
        }
        $addPort = Read-Host "Add another port? (y/n)"
    }
    
    # Environment variables
    Write-Host "`n--- Environment Variables ---" -ForegroundColor Cyan
    $envVars = @()
    
    if ($DefaultEnvVars.Count -gt 0) {
        Write-Host "Suggested environment variables:" -ForegroundColor Yellow
        foreach ($env in $DefaultEnvVars) {
            $parts = $env -split '=', 2
            Write-Host "  $($parts[0]) = $($parts[1])" -ForegroundColor Gray
        }
        
        $customize = Read-Host "Customize these values? (y/n, default: n)"
        if ($customize -eq 'y') {
            foreach ($env in $DefaultEnvVars) {
                $parts = $env -split '=', 2
                $newValue = Read-Host "  $($parts[0]) (press Enter for: $($parts[1]))"
                if ([string]::IsNullOrWhiteSpace($newValue)) {
                    $envVars += $env
                } else {
                    $envVars += "$($parts[0])=$newValue"
                }
            }
        } else {
            $envVars = $DefaultEnvVars
        }
    }
    
    $addEnv = Read-Host "Add additional environment variables? (y/n)"
    while ($addEnv -eq 'y') {
        $envName = Read-Host "  Variable name"
        $envValue = Read-Host "  Variable value"
        if ($envName) {
            $envVars += "${envName}=${envValue}"
        }
        $addEnv = Read-Host "Add another? (y/n)"
    }
    
    # Volume mapping
    Write-Host "`n--- Volume Configuration ---" -ForegroundColor Cyan
    $volumes = @()
    
    if ($DefaultVolumePath) {
        Write-Host "Suggested container path: $DefaultVolumePath" -ForegroundColor Yellow
        $addVolume = Read-Host "Mount a volume for data persistence? (y/n)"
        if ($addVolume -eq 'y') {
            $hostPath = Read-Host "  Host path (where to store data)"
            if ($hostPath) {
                $volumes += "${hostPath}:${DefaultVolumePath}"
            }
        }
    }
    
    $addMore = Read-Host "Add additional volume mounts? (y/n)"
    while ($addMore -eq 'y') {
        $hostPath = Read-Host "  Host path"
        $containerPath = Read-Host "  Container path"
        if ($hostPath -and $containerPath) {
            $volumes += "${hostPath}:${containerPath}"
        }
        $addMore = Read-Host "Add another? (y/n)"
    }
    
    # Restart policy
    Write-Host "`n--- Restart Policy ---" -ForegroundColor Cyan
    Write-Host "  1. no"
    Write-Host "  2. always"
    Write-Host "  3. unless-stopped"
    Write-Host "  4. on-failure"
    $restartChoice = Read-Host "Select (1-4, default: 3)"
    $restartPolicy = switch ($restartChoice) {
        '1' { 'no' }
        '2' { 'always' }
        '4' { 'on-failure' }
        default { 'unless-stopped' }
    }
    
    # Build the docker run command
    $cmd = "docker run"
    
    if ($detached) { $cmd += " -d" }
    if ($interactive) { $cmd += " -it" }
    if ($containerName) { $cmd += " --name $containerName" }
    if ($restartPolicy -ne 'no') { $cmd += " --restart $restartPolicy" }
    
    foreach ($port in $ports) {
        $cmd += " -p $port"
    }
    
    foreach ($volume in $volumes) {
        $cmd += " -v `"$volume`""
    }
    
    foreach ($env in $envVars) {
        $cmd += " -e `"$env`""
    }
    
    $cmd += " $fullImage"
    
    # Display and confirm
    Write-Host "`n=== Generated Docker Command ===" -ForegroundColor Cyan
    Write-Host $cmd -ForegroundColor Yellow
    
    $execute = Read-Host "`nExecute this command? (y/n, default: y)"
    if ([string]::IsNullOrWhiteSpace($execute) -or $execute -eq 'y') {
        Write-Host "`nExecuting..." -ForegroundColor Green
        Invoke-Expression $cmd
        Write-Host "`n✓ Container started!" -ForegroundColor Green
    } else {
        Write-Host "`nCommand not executed." -ForegroundColor Yellow
    }
}
#>


# Container-specific functions that call Start-DockerInteractive with defaults

function Start-Mongo {
    <#
    .SYNOPSIS
        Interactively start a MongoDB container
    #>
    Start-DockerInteractive `
        -ImageName "mongo" `
        -DefaultTag "8.2.3" `
        -DefaultName "mongo-8-2-3" `
        -DefaultPorts @("27017:27017") `
        -DefaultEnvVars @(
            #"MONGO_INITDB_ROOT_USERNAME=admin",
            #"MONGO_INITDB_ROOT_PASSWORD=mongopass"
        ) `
        -DefaultVolumePath "/data/db"
}

function Start-Postgres {
    <#
    .SYNOPSIS
        Interactively start a PostgreSQL container
    #>
    Start-DockerInteractive `
        -ImageName "postgres" `
        -DefaultTag "15" `
        -DefaultName "postgres-dev" `
        -DefaultPorts @("5432:5432") `
        -DefaultEnvVars @(
            "POSTGRES_PASSWORD=postgrespass",
            "POSTGRES_DB=devdb"
        ) `
        -DefaultVolumePath "/var/lib/postgresql/data"
}

function Start-Redis {
    <#
    .SYNOPSIS
        Interactively start a Redis container
    #>
    Start-DockerInteractive `
        -ImageName "redis" `
        -DefaultTag "alpine" `
        -DefaultName "redis-dev" `
        -DefaultPorts @("6379:6379") `
        -DefaultVolumePath "/data"
}

function Start-LocalStack {
    <#
    .SYNOPSIS
        Interactively start a LocalStack container for AWS local development
    .DESCRIPTION
        Automatically detects LOCALSTACK_AUTH_TOKEN environment variable.
        If found, uses localstack-pro image and includes the auth token.
    #>
    
    # Check for LocalStack Pro auth token
    $authToken = $env:LOCALSTACK_AUTH_TOKEN
    $imageName = "localstack/localstack"
    $envVars = @("DEBUG=1", "SERVICES=")
    
    if ($authToken) {
        $imageName = "localstack/localstack-pro"
        $envVars += "LOCALSTACK_AUTH_TOKEN=$authToken"
        Write-Host "`n✓ Found LOCALSTACK_AUTH_TOKEN - using LocalStack Pro" -ForegroundColor Green
    } else {
        Write-Host "`nℹ No LOCALSTACK_AUTH_TOKEN found - using Community edition" -ForegroundColor Gray
        Write-Host "  (Set `$env:LOCALSTACK_AUTH_TOKEN to use Pro features)" -ForegroundColor Gray
    }
    
    Start-DockerInteractive `
        -ImageName $imageName `
        -DefaultTag "latest" `
        -DefaultName "localstack" `
        -DefaultPorts @("4566:4566") `
        -DefaultEnvVars $envVars `
        -DefaultVolumePath "/tmp/localstack"
}

function Start-SqlServer {
    <#
    .SYNOPSIS
        Interactively start a SQL Server container
    #>
    Start-DockerInteractive `
        -ImageName "mcr.microsoft.com/mssql/server" `
        -DefaultTag "2022-latest" `
        -DefaultName "sqlserver-dev" `
        -DefaultPorts @("1433:1433") `
        -DefaultEnvVars @(
            "ACCEPT_EULA=Y",
            "SA_PASSWORD=YourStrong@Passw0rd"
        ) `
        -DefaultVolumePath "/var/opt/mssql"
}

function Start-RabbitMQ {
    <#
    .SYNOPSIS
        Interactively start a RabbitMQ container with management UI
    #>
    Start-DockerInteractive `
        -ImageName "rabbitmq" `
        -DefaultTag "management-alpine" `
        -DefaultName "rabbitmq-dev" `
        -DefaultPorts @("5672:5672", "15672:15672") `
        -DefaultEnvVars @(
            "RABBITMQ_DEFAULT_USER=admin",
            "RABBITMQ_DEFAULT_PASS=rabbitpass"
        )
}

function Start-Nginx {
    <#
    .SYNOPSIS
        Interactively start an Nginx container
    #>
    Start-DockerInteractive `
        -ImageName "nginx" `
        -DefaultTag "alpine" `
        -DefaultName "nginx-dev" `
        -DefaultPorts @("80:80") `
        -DefaultVolumePath "/usr/share/nginx/html"
}

function Start-MySQL {
    <#
    .SYNOPSIS
        Interactively start a MySQL container
    #>
    Start-DockerInteractive `
        -ImageName "mysql" `
        -DefaultTag "8" `
        -DefaultName "mysql-dev" `
        -DefaultPorts @("3306:3306") `
        -DefaultEnvVars @(
            "MYSQL_ROOT_PASSWORD=mysqlpass",
            "MYSQL_DATABASE=devdb"
        ) `
        -DefaultVolumePath "/var/lib/mysql"
}

function Start-Elasticsearch {
    <#
    .SYNOPSIS
        Interactively start an Elasticsearch container
    #>
    Start-DockerInteractive `
        -ImageName "docker.elastic.co/elasticsearch/elasticsearch" `
        -DefaultTag "8.11.0" `
        -DefaultName "elasticsearch-dev" `
        -DefaultPorts @("9200:9200") `
        -DefaultEnvVars @(
            "discovery.type=single-node",
            "ELASTIC_PASSWORD=elasticpass",
            "xpack.security.enabled=true"
        ) `
        -DefaultVolumePath "/usr/share/elasticsearch/data"
}

# Helper to list available functions
function Get-DockerStartFunctions {
    Write-Host "`n=== Available Docker Start Functions ===" -ForegroundColor Cyan
    Write-Host "Start-Mongo          - MongoDB" -ForegroundColor Yellow
    Write-Host "Start-Postgres       - PostgreSQL" -ForegroundColor Yellow
    Write-Host "Start-Redis          - Redis" -ForegroundColor Yellow
    Write-Host "Start-LocalStack     - AWS LocalStack" -ForegroundColor Yellow
    Write-Host "Start-SqlServer      - SQL Server" -ForegroundColor Yellow
    Write-Host "Start-RabbitMQ       - RabbitMQ with Management" -ForegroundColor Yellow
    Write-Host "Start-Nginx          - Nginx" -ForegroundColor Yellow
    Write-Host "Start-MySQL          - MySQL" -ForegroundColor Yellow
    Write-Host "Start-Elasticsearch  - Elasticsearch" -ForegroundColor Yellow
    Write-Host "`nJust run the function (e.g., Start-Mongo) to begin!" -ForegroundColor Gray
}



Export-ModuleMember -Function Docker-Uninstall
Export-ModuleMember -Function Docker-Start
Export-ModuleMember -Function Docker-Stop
Export-ModuleMember -Function Docker-Restart
Export-ModuleMember -Function MitmProxy
Export-ModuleMember -Function Docker-DotNet
Export-ModuleMember -Function Docker-Python

Export-ModuleMember -Function Start-DockerInteractive
Export-ModuleMember -Function Start-Mongo
Export-ModuleMember -Function Start-Redis
Export-ModuleMember -Function Start-Postgres
Export-ModuleMember -Function Start-LocalStack
Export-ModuleMember -Function Start-SqlServer
Export-ModuleMember -Function Start-RabbitMQ
Export-ModuleMember -Function Start-Nginx
Export-ModuleMember -Function Start-MySQL
Export-ModuleMember -Function Start-Elasticsearch
Export-ModuleMember -Function Get-DockerStartFunctions

# docker run --name localstack -it -p 127.0.0.1:4566:4566 -p 127.0.0.1:4510-4559:4510-4559 -v /var/run/docker.sock:/var/run/docker.sock localstack/localstack