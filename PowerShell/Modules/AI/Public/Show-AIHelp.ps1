<#
.SYNOPSIS
Displays help information for the AI module.

.DESCRIPTION
Shows the `ai` front-door commands and the exported PowerShell functions.

.PARAMETER ShowExamples
Display usage examples.
#>
function Show-AIHelp {
    param(
        [switch]$ShowExamples
    )

    Write-SpectreHost "[bold cyan]AI Module Help[/]"
    Write-SpectreRule -Title "Usage" -Color Cyan
    Write-SpectreHost "  [white]ai[/]                           Open the interactive menu"
    Write-SpectreHost "  [white]ai help[/], [white]ai --help[/]           Show this help"
    Write-SpectreHost "  [white]ai init[/], [white]ai initialize[/]       First-time setup"
    Write-SpectreHost "  [white]ai home[/]                      Change to the AI_HOME folder"
    Write-SpectreHost "  [white]ai update skills[/]             Clone or update skill repositories"
    Write-SpectreHost "  [white]ai update agents[/]             Configure installed agents"
    Write-SpectreHost "  [white]ai agents[/], [white]ai list[/]            List installed agents"

    Write-SpectreRule -Title "PowerShell Functions" -Color Cyan

    $commands = @(
        @{
            Name = "Initialize-AI"
            FrontDoor = "ai init"
            Description = "Sets up AI_HOME, syncs skill repositories, and configures agents"
        },
        @{
            Name = "Update-SkillRepositories"
            FrontDoor = "ai update skills"
            Description = "Clones or updates git repos and links local skill paths"
        },
        @{
            Name = "Configure-AgentSkillRepositories"
            FrontDoor = "ai update agents"
            Description = "Symlinks each skill repo into selected agents' skills directories"
        },
        @{
            Name = "Get-InstalledAgents"
            FrontDoor = "ai agents"
            Description = "Returns Copilot, Claude, Cursor, and Codex detections"
        },
        @{
            Name = "Show-AIMenu"
            FrontDoor = "ai"
            Description = "Front door: interactive menu or the commands above"
        }
    )

    foreach ($cmd in $commands) {
        Write-SpectreHost "`n[bold green]→[/] [yellow]$($cmd.Name)[/]  ([white]$($cmd.FrontDoor)[/])"
        Write-SpectreHost "  $($cmd.Description)"
    }

    if ($ShowExamples) {
        Write-SpectreRule -Title "Examples" -Color Green
        Write-SpectreHost "`n[yellow]First-time setup:[/]"
        Write-SpectreHost "  [white]ai init[/]`n"

        Write-SpectreHost "[yellow]Change to AI_HOME:[/]"
        Write-SpectreHost "  [white]ai home[/]`n"

        Write-SpectreHost "[yellow]Update skill repositories:[/]"
        Write-SpectreHost "  [white]ai update skills[/]`n"

        Write-SpectreHost "[yellow]Configure agents:[/]"
        Write-SpectreHost "  [white]ai update agents[/]`n"

        Write-SpectreHost "[yellow]List installed agents:[/]"
        Write-SpectreHost "  [white]ai agents[/]`n"

        Write-SpectreHost "[yellow]Interactive menu:[/]"
        Write-SpectreHost "  [white]ai[/]`n"

        Write-SpectreHost "[yellow]AI_HOME (optional override):[/]"
        Write-SpectreHost "  [white]`$env:AI_HOME[/]`n"
    }

    Write-SpectreRule -Color Cyan
    Write-SpectreHost "[cyan]For detailed help on a specific function, use:[/]"
    Write-SpectreHost "  [white]Get-Help [bold yellow]CommandName[/] -Detailed[/]`n"
}
