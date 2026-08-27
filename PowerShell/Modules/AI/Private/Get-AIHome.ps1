<#
.SYNOPSIS
Gets the AI home directory path.

.DESCRIPTION
Returns AI_HOME if set, otherwise ~/.ai.
#>
function Get-AIHomeFromEnvironment {
    foreach ($scope in @('Process', 'User', 'Machine')) {
        $value = [Environment]::GetEnvironmentVariable('AI_HOME', $scope)
        if ($value) {
            return $value
        }
    }
    return $null
}

function Get-AIHome {
    $fromEnvironment = Get-AIHomeFromEnvironment
    if ($fromEnvironment) {
        return $fromEnvironment
    }

    return Join-Path ([Environment]::GetFolderPath("UserProfile")) ".ai"
}

function Set-AIHomeEnvironment {
    param([string]$Path)

    [Environment]::SetEnvironmentVariable('AI_HOME', $Path, 'User')
    $env:AI_HOME = $Path
}

function Set-AIHome {
    $aiHome = Get-AIHome
    $escaped = [string]$aiHome | Get-SpectreEscapedText

    if (-not (Test-Path -LiteralPath $aiHome)) {
        Write-SpectreHost "[bold red]AI_HOME does not exist:[/] [yellow]$escaped[/]"
        Write-SpectreHost "Run [white]ai init[/] first."
        return
    }

    Set-Location -LiteralPath $aiHome
    Write-SpectreHost "[green]✓[/] [cyan]$escaped[/]"
}
