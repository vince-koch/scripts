<#
.SYNOPSIS
Displays a checkbox menu for selecting agents.

.DESCRIPTION
Shows a multi-select checkbox menu using PwshSpectreConsole.
Returns the selected agents.
#>
function Show-AgentSelectionMenu {
    param (
        [array]$Agents
    )

    $Agents = @($Agents)
    if ($Agents.Count -eq 0) {
        Write-SpectreHost "[bold yellow]No AI agents detected on this system.[/]"
        return @()
    }

    $choices = @($Agents | ForEach-Object { $_.Name })

    $selectedNames = @(
        Read-SpectreMultiSelection `
            -Message 'Select agents to configure' `
            -Choices $choices `
            -PageSize 10 `
            -Color 'Cyan1' `
            -AllowEmpty
    )

    return @(
        $Agents | Where-Object { $_.Name -in $selectedNames }
    )
}
