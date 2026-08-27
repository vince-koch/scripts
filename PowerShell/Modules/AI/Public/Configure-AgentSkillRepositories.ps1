<#
.SYNOPSIS
Main function to detect, select, and configure agents with skill repositories.

.DESCRIPTION
Detects installed agents, presents a selection menu, and symlinks
each skill repository into the selected agents' native skills directories.

.PARAMETER SkillsPath
The path to the skills directory.
If not specified, uses $AI_HOME/skills
#>
function Configure-AgentSkillRepositories {
    param (
        [string]$SkillsPath
    )

    # Use AI_HOME skills directory if SkillsPath not specified
    if ([string]::IsNullOrEmpty($SkillsPath)) {
        $aiHome = Get-AIHome
        $SkillsPath = Join-Path $aiHome "skills"
    }

    Write-SpectreHost "[bold magenta]AI Agent Configuration[/]"
    Write-SpectreRule -Title "Detecting Agents" -Color Magenta

    # Get installed agents
    $installedAgents = Get-InstalledAgents

    if ($installedAgents.Count -eq 0) {
        Write-SpectreHost "[bold yellow]No AI agents detected on this system.[/]"
        return
    }

    Write-SpectreHost "[green]✓[/] Found $($installedAgents.Count) agent(s)"

    $selectedAgents = Show-AgentSelectionMenu -Agents $installedAgents

    if ($selectedAgents.Count -eq 0) {
        Write-SpectreHost "[yellow]No agents selected. Exiting.[/]"
        return
    }

    # Ensure skills path exists
    if (-Not (Test-Path $SkillsPath)) {
        New-Item -ItemType Directory -Path $SkillsPath -Force | Out-Null
    }

    # Configure each selected agent
    Write-SpectreRule -Title "Configuring Selected Agents" -Color Green
    foreach ($agent in $selectedAgents) {
        Update-AgentConfiguration -Agent $agent -SkillsPath $SkillsPath
    }

    Write-SpectreRule -Color Green
    Write-SpectreHost "[bold green]✓ Agent configuration completed![/]"
    Write-SpectreHost "[cyan]Restart your agents to pick up the linked skill repositories.[/]"
}
