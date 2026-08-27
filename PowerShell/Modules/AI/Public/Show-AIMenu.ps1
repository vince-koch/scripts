<#
.SYNOPSIS
Interactive menu and command front door for the AI module.

.DESCRIPTION
With no arguments, opens an interactive menu. With arguments, dispatches
to the matching command (init, home, update skills, update agents, agents, help).

.EXAMPLE
ai
.EXAMPLE
ai help
.EXAMPLE
ai init
.EXAMPLE
ai home
.EXAMPLE
ai update skills
.EXAMPLE
ai update agents
.EXAMPLE
ai agents
#>
function Show-AIMenu {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [string[]]$ArgumentList,

        [Alias('h')]
        [switch]$Help
    )

    $tokens = @(
        $ArgumentList |
            ForEach-Object { "$_".Trim() } |
            Where-Object { $_ }
    )
    $verb = if ($tokens.Count -gt 0) { $tokens[0].ToLowerInvariant() } else { '' }
    $noun = if ($tokens.Count -gt 1) { $tokens[1].ToLowerInvariant() } else { '' }

    if ($Help -or $verb -in @('help', '--help', '/help', '/?', '-h', '-?')) {
        Show-AIHelp
        return
    }

    if ($verb) {
        if ($verb -in @('init', 'initialize')) {
            Initialize-AI
            return
        }

        if ($verb -eq 'home') {
            Set-AIHome
            return
        }

        if ($verb -eq 'update') {
            if ($noun -in @('skill', 'skills')) {
                Update-SkillRepositories
                return
            }
            if ($noun -in @('agent', 'agents')) {
                Configure-AgentSkillRepositories
                return
            }
            Write-SpectreHost "[red]Usage:[/] [yellow]ai update skills[/] or [yellow]ai update agents[/]"
            return
        }

        if ($verb -in @('list', 'agent', 'agents')) {
            if ($verb -eq 'list' -and $noun -and $noun -notin @('agent', 'agents')) {
                Write-SpectreHost "[red]Usage:[/] [yellow]ai agents[/] or [yellow]ai list agents[/]"
                return
            }
            Show-InstalledAgents
            return
        }

        Write-SpectreHost "[red]Unknown command '$($tokens[0])'. Try [yellow]ai help[/].[/]"
        return
    }

    $choices = @(
        '1. Initialize AI (first-time setup)'
        '2. Update Skill Repositories'
        '3. Configure AI Agents'
        '4. Show Installed Agents'
        '5. Go to AI_HOME'
        '6. View Help'
        '7. View Help with Examples'
        '0. Exit'
    )

    while ($true) {
        $action = Read-SpectreSelection `
            -Message 'AI Module' `
            -Choices $choices `
            -PageSize 10 `
            -EnableSearch `
            -Color 'Cyan1'

        if (-not $action -or $action -eq '0. Exit') {
            return
        }

        switch ($action) {
            '1. Initialize AI (first-time setup)' {
                Initialize-AI
            }
            '2. Update Skill Repositories' {
                Update-SkillRepositories
            }
            '3. Configure AI Agents' {
                Configure-AgentSkillRepositories
            }
            '4. Show Installed Agents' {
                Show-InstalledAgents
            }
            '5. Go to AI_HOME' {
                Set-AIHome
                return
            }
            '6. View Help' {
                Show-AIHelp
            }
            '7. View Help with Examples' {
                Show-AIHelp -ShowExamples
            }
        }
    }
}

function ai {
    <#
    .SYNOPSIS
    Front door for the AI module.
    .NOTES
    Same as Show-AIMenu.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [string[]]$ArgumentList,

        [Alias('h')]
        [switch]$Help
    )

    $parameters = @{
        ArgumentList = @($ArgumentList)
    }
    if ($Help) {
        $parameters.Help = $true
    }
    Show-AIMenu @parameters
}
