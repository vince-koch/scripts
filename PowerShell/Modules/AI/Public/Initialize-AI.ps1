<#
.SYNOPSIS
Initializes the AI module configuration and environment.

.DESCRIPTION
Sets up the AI_HOME environment variable, creates the necessary directory structure,
copies the skill-repositories.yml configuration file, syncs skill repositories,
and configures AI agents.
Similar to 'git init' for the AI module.
#>
function Initialize-AI {
    Write-SpectreHost "[bold cyan]AI Module Initialization[/]"
    Write-SpectreRule -Title "Checking Environment" -Color Cyan

    $existingHome = Get-AIHomeFromEnvironment
    $defaultHome = Join-Path ([Environment]::GetFolderPath("UserProfile")) ".ai"

    if ($existingHome) {
        $escapedExisting = [string]$existingHome | Get-SpectreEscapedText
        if (Test-Path $existingHome) {
            Set-AIHomeEnvironment -Path $existingHome
            Write-SpectreHost "[bold yellow]AI is already initialized![/]"
            Write-SpectreHost "AI_HOME is set to: [cyan]$escapedExisting[/]"
            return
        }
        else {
            Write-SpectreHost "[yellow]AI_HOME is set to:[/] [cyan]$escapedExisting[/]"
            Write-SpectreHost "[yellow]However, this folder does not exist.[/]"

            if (Read-SpectreConfirm -Message "Would you like to use this path?" -DefaultAnswer 'y') {
                $aiHome = $existingHome
            }
            else {
                $aiHome = Read-SpectreText -Message "Enter AI home directory" -DefaultAnswer $defaultHome
                if (-not $aiHome) {
                    return
                }
            }
        }
    }
    else {
        Write-SpectreHost "[cyan]AI_HOME environment variable not set.[/]"
        $aiHome = Read-SpectreText -Message "Enter AI home directory" -DefaultAnswer $defaultHome
        if (-not $aiHome) {
            return
        }
    }

    $escapedHome = [string]$aiHome | Get-SpectreEscapedText

    if (-Not (Test-Path $aiHome)) {
        Write-SpectreHost "`n[yellow]Creating directory:[/] [cyan]$escapedHome[/]"
        New-Item -ItemType Directory -Path $aiHome -Force | Out-Null
        Write-SpectreHost "[green]✓[/] Directory created"
    }
    else {
        Write-SpectreHost "`n[green]✓[/] Directory already exists: [cyan]$escapedHome[/]"
    }

    Write-SpectreHost "`n[yellow]Setting up configuration files...[/]"
    $moduleDir = Split-Path $PSCommandPath -Parent
    $moduleDir = Split-Path $moduleDir -Parent  # Go up one level to the module root
    $sourceConfig = Join-Path $moduleDir "skill-repositories.yml"
    $targetConfig = Join-Path $aiHome "skill-repositories.yml"

    if (Test-Path $sourceConfig) {
        if (-Not (Test-Path $targetConfig)) {
            Copy-Item -Path $sourceConfig -Destination $targetConfig -Force
            Write-SpectreHost "[green]✓[/] Copied skill-repositories.yml to: [cyan]$escapedHome[/]"
        }
        else {
            Write-SpectreHost "[yellow]skill-repositories.yml already exists[/]"
        }
    }
    else {
        Write-SpectreHost "[bold red]ERROR:[/] skill-repositories.yml not found in module directory"
        return
    }

    Write-SpectreHost "`n[yellow]Setting environment variable...[/]"
    Set-AIHomeEnvironment -Path $aiHome
    Write-SpectreHost "[green]✓[/] AI_HOME set to: [cyan]$escapedHome[/]"

    $gitignorePath = Join-Path $aiHome ".gitignore"
    if (-Not (Test-Path $gitignorePath)) {
        @"
# Ignore skill repositories
skills/
"@ | Set-Content -Path $gitignorePath
        Write-SpectreHost "[green]✓[/] Created .gitignore"
    }

    $skillsDir = Join-Path $aiHome "skills"
    if (-Not (Test-Path $skillsDir)) {
        New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
        Write-SpectreHost "[green]✓[/] Created skills directory"
    }

    Write-SpectreHost ""
    Update-SkillRepositories

    Write-SpectreHost "`n[yellow]Opening folder in Windows Explorer...[/]"
    Invoke-Item -Path $aiHome

    Write-SpectreRule -Color Green
    Write-SpectreHost "[bold green]✓ AI initialization completed![/]"
}
