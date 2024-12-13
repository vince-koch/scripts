Try-Import-Module $PSScriptRoot\Console.psm1

function Get-DockerContainerInfo {
    # Get container information using docker ps and format the output
    $containers = docker ps --format '{{.Names}}|{{.Image}}|{{.Ports}}'

    # Create an array to hold the parsed container info
    $containerInfo = @()

    # Helper function to parse port mappings
    function Parse-PortMapping {
        param ($portMappingString)

        if ([string]::IsNullOrEmpty($portMappingString)) {
            return @()
        }

        $portMappings = @()
        foreach ($portMapping in $portMappingString -split ', ') {
            # Example: "0.0.0.0:8080->80/tcp"
            if ($portMapping -match '(.*):(\d+)->(\d+)/(\w+)') {
                $ip = $matches[1]
                $externalPort = $matches[2]
                $internalPort = $matches[3]
                $portType = $matches[4]

                $portMappingObj = [pscustomobject]@{
                    IP           = $ip
                    ExternalPort = $externalPort
                    InternalPort = $internalPort
                    PortType     = $portType
                }
                
                $portMappings += $portMappingObj
            }
        }
        
        return $portMappings
    }

    # Parse each container's info and store it in a custom object
    foreach ($container in $containers) {
        $parts = $container -split '\|'
        $containerName = $parts[0]
        $imageName = $parts[1]
        $portMapping = $parts[2]

        # Create a custom object for each container with detailed port mapping
        $containerObj = [pscustomobject]@{
            Name         = $containerName
            Image        = $imageName
            PortMappings = Parse-PortMapping -portMappingString $portMapping
        }

        # Add the custom object to the array
        $containerInfo += $containerObj
    }

    # Return the container info as output
    return $containerInfo
}

function Studio3T {
    $containers = Get-DockerContainerInfo
    $mongoContainers = $containers | Where-Object { $_.Image -like "mongo:*" }
    $selectedContainer = Console-Menu `
        -Title "Which instance of Mongo would you like to connect to?" `
        -Items $mongoContainers `
        -ItemsProperty { param($item) "$($item.PortMappings[0].ExternalPort) => $($item.Name)" }

    if ($selectedContainer -ne $null) {
        $username = "mongo"
        $password = "mongo"
        $databaseName = "test"
        $externalPort = $selectedContainer.PortMappings[0].ExternalPort
        $connectionString = "mongodb://$($username):$($password)@localhost:$($externalPort)/$($databaseName)"
     
        $connectionString | Set-Clipboard
     
        $programPath = "$env:USERPROFILE\AppData\Local\Programs\3T Software Labs\Studio 3T\Studio 3T.exe"
        Start-Process $programPath -ArgumentList "--connect", $connectionString
    }
}

Export-ModuleMember -Function Studio3T