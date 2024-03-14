function Env-List {
    Get-ChildItem Env:
}

function Env-Get {
    param (
        [Parameter(Mandatory=$true)]
        [string] $name
    )

    [Environment]::GetEnvironmentVariable($name)
}

function Env-Set {
    param (
        [Parameter(Mandatory=$true)]
        [string] $name,

        [Parameter(Mandatory=$true)]
        [string] $value
    )

	# Creates, modifies, or deletes an environment variable stored in the current process.
    [Environment]::SetEnvironmentVariable($name, $value)

    Write-Host "Variable " -NoNewLine
    Write-Host $name -ForegroundColor Cyan -NoNewLine
    Write-Host " has been set to " -NoNewLine
    Write-Host $value -ForegroundColor Yellow
}

function Env-UnSet {
    param (
        [Parameter(Mandatory=$true)]
        [string] $name
    )

	# Creates, modifies, or deletes an environment variable stored in the current process.
    [Environment]::SetEnvironmentVariable($name, $null)

    Write-Host "Variable " -NoNewLine
    Write-Host $name -ForegroundColor Cyan -NoNewLine
    Write-Host " has been unset"
}

function Env-Help {
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
        [Parameter(Mandatory=$false)]
        [string] $command = "list",

        [Parameter(Mandatory=$false)]
        [string] $name = $null,

        [Parameter(Mandatory=$false)]
        [string] $value = $null
    )

    switch ($command.ToLower()) {
        "list" { Env-List }
        "get" { Env-Get $name }
        "set" { Env-Set $name $value }
        "unset" { Env-Unset $name }
        "del" { Env-Unset $name }
        default { Env-Help }
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
    $env:PATH=$path
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
Export-ModuleMember -Function Environment-PathAdd
Export-ModuleMember -Function Environment-PathRemove
Export-ModuleMember -Function Environment-PathPrint
Export-ModuleMember -Function Environment-PathList