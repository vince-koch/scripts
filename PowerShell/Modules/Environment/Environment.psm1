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

function Show-EnvironmentHelp {
    Write-Host 'Usage:' -ForegroundColor Yellow
    Write-Host '    env                  # Open the interactive menu'
    Write-Host '    env list             # List environment variables'
    Write-Host '    env path             # List PATH entries one per line'
    Write-Host '    env get NAME         # Get a variable'
    Write-Host '    env set NAME VALUE   # Set a variable for this process and the current user'
    Write-Host '    env unset NAME       # Remove a variable'
    Write-Host '    env del NAME         # Alias for unset'
}

function Get-EnvironmentVariableNames {
    @(Get-ChildItem Env: | Sort-Object Name | Select-Object -ExpandProperty Name)
}

function Select-EnvironmentVariable {
    param([string]$Message)

    $names = Get-EnvironmentVariableNames
    if ($names.Count -eq 0) {
        Write-Warning 'No environment variables are available.'
        return $null
    }

    Read-SpectreSelection -Message $Message -Choices $names -EnableSearch -Color 'Cyan1'
}

function Show-Environment {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet('list', 'path', 'get', 'set', 'unset', 'del', 'help')]
        [string]$Command,

        [Parameter(Position = 1)]
        [string]$Name,

        [Parameter(Position = 2)]
        [AllowEmptyString()]
        [string]$Value
    )

    if ($Command) {
        switch ($Command) {
            'list' { Environment-List }
            'path' { Environment-PathList }
            'get' {
                if (-not $Name) { throw 'Usage: env get NAME' }
                Environment-Get -Name $Name
            }
            'set' {
                if (-not $Name -or -not $PSBoundParameters.ContainsKey('Value')) { throw 'Usage: env set NAME VALUE' }
                Environment-Set -Name $Name -Value $Value
            }
            { $_ -in 'unset', 'del' } {
                if (-not $Name) { throw 'Usage: env unset NAME' }
                Environment-Unset -Name $Name
            }
            'help' { Show-EnvironmentHelp }
        }
        return
    }

    Import-Module PwshSpectreConsole -ErrorAction Stop
    while ($true) {
        $action = Read-SpectreSelection -Message 'Environment variables' -Choices @('List', 'List PATH entries', 'Get', 'Set', 'Unset', 'Exit') -Color 'Cyan1'
        if (-not $action) { return }
        switch ($action) {
            'List' { Environment-List }
            'List PATH entries' { Environment-PathList }
            'Get' {
                $selectedName = Select-EnvironmentVariable -Message 'Select a variable'
                if ($selectedName) {
                    $selectedValue = Environment-Get -Name $selectedName
                    $escapedValue = [string]$selectedValue | Get-SpectreEscapedText
                    Write-SpectreHost "[cyan]$selectedName[/] = $escapedValue"
                }
            }
            'Set' {
                $selectedName = Read-SpectreText -Message 'Variable name'
                if ($selectedName) {
                    $currentValue = Environment-Get -Name $selectedName
                    $textParameters = @{ Message = 'Variable value'; AllowEmpty = $true }
                    if ($null -ne $currentValue) { $textParameters.DefaultAnswer = $currentValue }
                    $selectedValue = Read-SpectreText @textParameters
                    if ($null -ne $selectedValue) {
                        Environment-Set -Name $selectedName -Value $selectedValue
                    }
                }
            }
            'Unset' {
                $selectedName = Select-EnvironmentVariable -Message 'Select a variable to remove'
                if ($selectedName -and (Read-SpectreConfirm -Message "Remove [cyan]$selectedName[/]?" -DefaultAnswer 'n')) {
                    Environment-Unset -Name $selectedName
                }
            }
            'Exit' { return }
        }
    }
}

Set-Alias -Name add-path -Value Environment-PathAdd
Set-Alias -Name remove-path -Value Environment-PathRemove
Set-Alias -Name env -Value Show-Environment

Export-ModuleMember -Function Environment-List
Export-ModuleMember -Function Environment-Get
Export-ModuleMember -Function Environment-Set
Export-ModuleMember -Function Environment-Unset

Export-ModuleMember -Function Environment-PathAdd
Export-ModuleMember -Function Environment-PathRemove
Export-ModuleMember -Function Environment-PathPrint
Export-ModuleMember -Function Environment-PathList
Export-ModuleMember -Function Show-Environment -Alias add-path, remove-path, env
