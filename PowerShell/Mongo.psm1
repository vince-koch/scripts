function Start-MongoUi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConnectionString
    )

    $MongoUiCommand = $env:MONGO_UI_COMMAND_LINE
    if ([string]::IsNullOrWhiteSpace($MongoUiCommand)) {
        Write-Verbose "MONGO_UI_COMMAND_LINE is not set. Falling back to 'mongo-compass' in PATH."
        $MongoUi = "mongo-compass"
        $useArgumentList = $true
    } else {
        if ($MongoUiCommand -match '^"([^"]+)"\s+"([^"]+)"$') {
            $MongoUi = $matches[1]
            $parameterFormat = $matches[2]
            $useArgumentList = $false
        } else {
            $MongoUi = $MongoUiCommand
            $useArgumentList = $true
        }
    }

    Write-Host "Launching Mongo UI with connection string: $ConnectionString" -ForegroundColor Green

    try {
        if ($useArgumentList) {
            Start-Process -FilePath $MongoUi -ArgumentList $ConnectionString
        } else {
            $commandWithConnection = $MongoUiCommand -replace '<CONNECTION_STRING>', $ConnectionString
            if ($commandWithConnection -match '^"([^"]+)"\s+(.+)$') {
                $executablePath = $matches[1]
                $arguments = $matches[2]
                Start-Process -FilePath $executablePath -ArgumentList $arguments
            } else {
                Start-Process -FilePath $MongoUi -ArgumentList $ConnectionString
            }
        }
    }
    catch {
        Write-Host "Failed to launch Mongo UI. Check that MONGO_UI_COMMAND_LINE is set correctly or Compass is in PATH." -ForegroundColor Red
    }
}

function Get-MongoConnectionString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Container,
        [string]$Username = $env:MONGO_DEFAULT_USERNAME,
        [string]$Password = $env:MONGO_DEFAULT_PASSWORD
    )

    $portMapping = $Container.Ports -split ","
    $mongoPort = $null

    foreach ($mapping in $portMapping) {
        if ($mapping -match "(\d+\.\d+\.\d+\.\d+):(\d+)->27017") {
            $host = $matches[1]
            $hostPort = $matches[2]
            $mongoPort = "$($host):$($hostPort)"
            break
        }
        elseif ($mapping -match "0.0.0.0:(\d+)->27017") {
            $hostPort = $matches[1]
            $mongoPort = "localhost:$($hostPort)"
            break
        }
    }

    if (-not $mongoPort) {
        Write-Host "Could not determine host port for MongoDB." -ForegroundColor Red
        return $null
    }

    $encodedUsername = [Uri]::EscapeDataString($Username)
    $encodedPassword = [Uri]::EscapeDataString($Password)
    $encodedAuth = if ([string]::IsNullOrWhiteSpace($Username) -and [string]::IsNullOrWhiteSpace($Password)) { "" } else { "$([Uri]::EscapeDataString($Username)):$([Uri]::EscapeDataString($Password))@" }

    if ([string]::IsNullOrWhiteSpace($Username) -or [string]::IsNullOrWhiteSpace($Password)) {
        $encodedUsername = [Uri]::EscapeDataString("mongo")
        $encodedPassword = [Uri]::EscapeDataString("mongo")
    }
    
    $mongoPort = $mongoPort -replace "0.0.0.0", "127.0.0.1"

    $connectionString = "mongodb://" + $encodedAuth + $mongoPort + "?directConnection=true"
    return $connectionString
}

function Get-MongoContainers {
    [CmdletBinding()]
    param()

    $containers = docker ps --format "{{.ID}}|{{.Image}}|{{.Names}}|{{.Ports}}|{{.Status}}" |
        Where-Object { $_ -match '\|mongo' } |
        ForEach-Object {
            $parts = $_ -split "\|"
            [PSCustomObject]@{
                Id     = $parts[0]
                Image  = $parts[1]
                Name   = $parts[2]
                Ports  = $parts[3]
                Status = $parts[4]
            }
        }

    return $containers
}

function Select-MongoContainer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Containers
    )

    if (-not $Containers) {
        Write-Host "No running MongoDB containers found." -ForegroundColor Red
        return $null
    }

    Write-Host "Select a MongoDB container to connect to:" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor DarkGray
    
    $index = 1
    $Containers | ForEach-Object {
        $containerNumber = "[$index]".PadRight(6)
        $containerName = $_.Name.PadRight(20)
        $containerImage = $_.Image.PadRight(15)
        $containerPorts = $_.Ports
        
        Write-Host $containerNumber -NoNewline -ForegroundColor Yellow
        Write-Host $containerName -NoNewline -ForegroundColor White
        Write-Host $containerImage -NoNewline -ForegroundColor Green
        Write-Host $containerPorts -ForegroundColor Cyan
        $index++
    }
    
    Write-Host ("=" * 80) -ForegroundColor DarkGray

    $selection = Read-Host "Enter the number of the container"
    if ($selection -notmatch '^\d+$' -or $selection -lt 1 -or $selection -gt $Containers.Count) {
        Write-Host "Invalid selection." -ForegroundColor Red
        return $null
    }

    return $Containers[$selection - 1]
}



function Docker-MongoUi {
    [CmdletBinding()]
    param ()

    $containers = Get-MongoContainers
    $chosen = Select-MongoContainer -Containers $containers
    if (-not $chosen) {
        return
    }

    $connectionString = Get-MongoConnectionString -Container $chosen
    if (-not $connectionString) {
        return
    }

    Start-MongoUi -ConnectionString $connectionString
}

Export-ModuleMember -Function Docker-MongoUi, Start-MongoUi, Get-MongoContainers, Select-MongoContainer, Get-MongoConnectionString

Set-Alias docker-mongo Docker-MongoUi
Export-ModuleMember -Alias docker-mongo 