function Environment-List {
    Get-ChildItem Env:
}

function Environment-Get {
    param (
        [Parameter(Mandatory = $true)]
        [string] $name
    )

    [Environment]::GetEnvironmentVariable($name)
}

function Environment-Set {
    param (
        [Parameter(Mandatory = $true)] [string] $name,
        [Parameter(Mandatory = $true)] [string] $value,
        [switch] $silent
    )

    if ($null -eq $value) {
        if ($Silent) {
            Environment-UnSet -name $name -Silent
        }
        else {
            Environment-UnSet -name $name
        }

        return
    }
    
    # Creates, modifies, or deletes the variable in both the current process scope
    # so the change can take effect immediately, and be sticky for future sessions
    [Environment]::SetEnvironmentVariable($name, $value)
    if ($env:OS -eq 'Windows_NT') {
        [Environment]::SetEnvironmentVariable($name, $value, "User")
    }

    if (-not $silent) {
        Write-Host "Environment variable " -NoNewLine
        Write-Host $name -ForegroundColor Cyan -NoNewLine
        Write-Host " has been set to " -NoNewLine
        Write-Host $value -ForegroundColor Yellow
    }
}

function Environment-UnSet {
    param (
        [Parameter(Mandatory = $true)] [string] $name,
        [switch] $silent
    )

    # Remove from current session
    if (Test-Path "Env:$name") {
        Remove-Item "Env:$name" -Force
    }

    # Remove from user scope via registry
    if ($env:OS -eq 'Windows_NT') {
        $userEnvKey = "HKCU:\Environment"
        if (Test-Path $userEnvKey) {
            $props = Get-ItemProperty -Path $userEnvKey
            if ($props.PSObject.Properties.Name -contains $name) {
                Remove-ItemProperty -Path $userEnvKey -Name $name -Force
            }
        }
    }

    if (-not $silent) {
        Write-Host "Environment variable " -NoNewLine
        Write-Host $name -ForegroundColor Cyan -NoNewLine
        Write-Host " has been unset"
    }
}


function Environment-Help {
    Write-Host "env [command] [name] [value]"
    Write-Host "    env"
    Write-Host "    env list"
    Write-Host "    env get MY_VAR"
    Write-Host "    env set MY_VAR the-value"
    Write-Host "    env unset MY_VAR"
    Write-Host "    env del MY_VAR"
}

function Env {
    param (
        [Parameter(Mandatory = $false)]
        [string] $command = "list",

        [Parameter(Mandatory = $false)]
        [string] $name = $null,

        [Parameter(Mandatory = $false)]
        [string] $value = $null
    )

    switch ($command.ToLower()) {
        "list" { Environment-List }
        "get" { Environment-Get $name }
        "set" { Environment-Set $name $value }
        "unset" { Environment-Unset $name }
        "del" { Environment-Unset $name }
        default { Environment-Help }
    }
}

function Environment-PathAdd {
    param (
        [Parameter()] [string] $Value
    )

    [string[]] $pathArray = $env:PATH.Split(';')

    $pathArray = $pathArray.Where({ -Not [string]::Equals($_, $Value, "OrdinalIgnoreCase") })
    $pathArray += $Value

    $path = [string]::Join(";", $pathArray)
    $env:PATH = $path
}

function Environment-PathRemove {
    param (
        [Parameter()] [string] $Value
    )

    [string[]] $pathArray = $env:PATH.Split(';')
    $pathArray = $pathArray.Where({ -Not [string]::Equals($_, $Value, "OrdinalIgnoreCase") })

    [string] $path = [string]::Join(";", $pathArray)
    $env:PATH = $path
}

function Environment-PathPrint {
    $env:PATH
}

function Environment-PathList {
    [string[]] $pathArray = $env:PATH.Split(';')
    return $pathArray
}

Set-Alias -Name add-path -Value Environment-PathAdd
Set-Alias -Name remove-path -Value Environment-PathRemove

Export-ModuleMember -Function Env

Export-ModuleMember -Function Environment-List
Export-ModuleMember -Function Environment-Get
Export-ModuleMember -Function Environment-Set
Export-ModuleMember -Function Environment-Unset

Export-ModuleMember -Function Environment-PathAdd
Export-ModuleMember -Function Environment-PathRemove
Export-ModuleMember -Function Environment-PathPrint
Export-ModuleMember -Function Environment-PathList