<#
.SYNOPSIS
Displays detected AI agents.
#>
function Show-InstalledAgents {
    Write-SpectreHost "[bold cyan]Detecting AI agents...[/]"
    $agents = @(Get-InstalledAgents)
    if ($agents.Count -eq 0) {
        Write-SpectreHost "[yellow]No AI agents detected on this system.[/]"
        return
    }

    Write-SpectreHost "[green]Found [bold]$($agents.Count)[/] agent(s):[/]"
    foreach ($agent in $agents) {
        $homePath = [string]$agent.HomePath | Get-SpectreEscapedText
        $skillsPath = [string]$agent.SkillsPath | Get-SpectreEscapedText
        Write-SpectreHost "  • [cyan]$($agent.Name)[/]"
        Write-SpectreHost "    Home: [blue]$homePath[/]"
        Write-SpectreHost "    Skills: [blue]$skillsPath[/]"
    }
}
