<#
.SYNOPSIS
Updates skill repositories from the configuration file.

.DESCRIPTION
Reads the skill-repositories.yml file, determines the type of repository,
and installs or updates the skill repositories listed in it.
Skills land in AI_HOME/skills/repo-name.
URLs may be git urls or local paths. If a local path is specified, a soft link is created.

.PARAMETER ConfigPath
The path to the skill-repositories.yml configuration file.
If not specified, uses $AI_HOME/skill-repositories.yml
#>
function Update-SkillRepositories {
    param (
        [string]$ConfigPath
    )

    # Use AI_HOME if ConfigPath not specified
    if ([string]::IsNullOrEmpty($ConfigPath)) {
        $aiHome = Get-AIHome
        $ConfigPath = Join-Path $aiHome "skill-repositories.yml"
    }

    $escapedConfigPath = [string]$ConfigPath | Get-SpectreEscapedText

    Write-SpectreHost "[bold cyan]Skill Repository Manager[/]"
    Write-SpectreRule -Title "Reading Configuration" -Color Cyan
    Write-SpectreHost "Config Path: [yellow]$escapedConfigPath[/]"

    # Check if the config file exists
    if (-Not (Test-Path -Path $ConfigPath)) {
        Write-SpectreHost "[bold red]ERROR:[/] The skill-repositories.yml file does not exist at: [yellow]$escapedConfigPath[/]"
        return
    }

    # Determine the skills directory (from AI_HOME)
    $aiHome = Get-AIHome
    $skillsDir = Join-Path $aiHome "skills"

    # Create skills directory if it doesn't exist
    if (-Not (Test-Path -Path $skillsDir)) {
        New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
        $escapedSkillsDir = [string]$skillsDir | Get-SpectreEscapedText
        Write-SpectreHost "[green]✓[/] Created skills directory at: [cyan]$escapedSkillsDir[/]"
    }

    # Read and parse the YAML file
    $configContent = Get-Content -Path $ConfigPath -Raw
    $repositories = @()

    # Simple YAML parser for repositories section
    $lines = $configContent -split "`n"
    $inRepositories = $false
    $currentRepo = $null

    foreach ($line in $lines) {
        $trimmedLine = $line.Trim()

        if ($trimmedLine -eq "repositories:") {
            $inRepositories = $true
            continue
        }

        if ($inRepositories) {
            if ($trimmedLine.StartsWith("- name:")) {
                if ($currentRepo) {
                    $repositories += $currentRepo
                }
                $currentRepo = @{
                    name = $trimmedLine -replace "^- name:\s*", ""
                }
            }
            elseif ($trimmedLine.StartsWith("url:")) {
                if ($currentRepo) {
                    $currentRepo.url = $trimmedLine -replace "^url:\s*", ""
                }
            }
            elseif ($trimmedLine -eq "" -or $trimmedLine.StartsWith("version:") -or $trimmedLine.StartsWith("repositories:")) {
                # End of repositories section or end of current repo
                if ($currentRepo -and $trimmedLine.StartsWith("version:")) {
                    break
                }
            }
        }
    }

    # Add the last repository if it exists
    if ($currentRepo) {
        $repositories += $currentRepo
    }

    Write-SpectreHost "[green]✓[/] Found [bold yellow]$($repositories.Count)[/] repositories to process`n"

    # Process each repository
    $repoIndex = 0
    foreach ($repo in $repositories) {
        $repoIndex++
        $repoName = $repo.name
        $repoUrl = $repo.url
        $repoPath = Join-Path $skillsDir $repoName
        $escapedRepoName = [string]$repoName | Get-SpectreEscapedText
        $escapedRepoPath = [string]$repoPath | Get-SpectreEscapedText
        $escapedRepoUrl = [string]$repoUrl | Get-SpectreEscapedText

        Write-SpectreRule -Title "Repository $repoIndex/$($repositories.Count): $escapedRepoName" -Color Magenta

        if ($repoUrl.StartsWith("file://")) {
            # Local path - create a soft link
            $localPath = $repoUrl -replace "^file://", ""
            $localPath = $localPath -replace "/", "\"
            $localPath = $localPath.TrimEnd("\")
            $escapedLocalPath = [string]$localPath | Get-SpectreEscapedText

            Write-SpectreHost "[cyan]Type:[/] Local (file link)"
            Write-SpectreHost "[cyan]Source:[/] [yellow]$escapedLocalPath[/]"
            Write-SpectreHost "[cyan]Target:[/] [yellow]$escapedRepoPath[/]"

            # Check if source exists
            if (-Not (Test-Path -Path $localPath)) {
                Write-SpectreHost "[bold red]ERROR:[/] Source path does not exist: [yellow]$escapedLocalPath[/]"
                continue
            }

            # Remove existing link/directory if it exists
            if (Test-Path -Path $repoPath) {
                Write-SpectreHost "[yellow]Removing existing link/directory...[/]"
                Remove-Item -Path $repoPath -Force -ErrorAction SilentlyContinue
            }

            # Create soft link
            try {
                if ($PSVersionTable.Platform -eq "Unix" -or $PSVersionTable.OS -like "*Linux*" -or $PSVersionTable.OS -like "*Darwin*") {
                    # Unix-like system
                    ln -s $localPath $repoPath
                    Write-SpectreHost "[green]✓[/] Created symbolic link (Unix)"
                }
                else {
                    # Windows system
                    New-Item -ItemType SymbolicLink -Path $repoPath -Target $localPath -Force | Out-Null
                    Write-SpectreHost "[green]✓[/] Created symbolic link (Windows)"
                }
            }
            catch {
                $escapedError = [string]$_ | Get-SpectreEscapedText
                Write-SpectreHost "[bold red]ERROR:[/] Failed to create symbolic link: [yellow]$escapedError[/]"
                continue
            }
        }
        else {
            # Git repository URL
            Write-SpectreHost "[cyan]Type:[/] Git repository"
            Write-SpectreHost "[cyan]URL:[/] [yellow]$escapedRepoUrl[/]"

            if (Test-Path -Path $repoPath) {
                # Repository already exists, pull latest changes
                Write-SpectreHost "[yellow]Updating existing repository...[/]"
                Push-Location -Path $repoPath
                try {
                    $gitOutput = git pull origin main 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-SpectreHost "[green]✓[/] Repository updated successfully"
                    }
                    else {
                        Write-SpectreHost "[yellow]Update completed with warnings[/]"
                    }
                }
                catch {
                    $escapedError = [string]$_ | Get-SpectreEscapedText
                    Write-SpectreHost "[bold red]ERROR:[/] Failed to pull latest changes: [yellow]$escapedError[/]"
                }
                finally {
                    Pop-Location
                }
            }
            else {
                # Clone the repository
                Write-SpectreHost "[yellow]Cloning repository...[/]"
                try {
                    git clone $repoUrl $repoPath 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0) {
                        Write-SpectreHost "[green]✓[/] Repository cloned successfully"
                    }
                    else {
                        throw "Git clone failed with exit code $LASTEXITCODE"
                    }
                }
                catch {
                    $escapedError = [string]$_ | Get-SpectreEscapedText
                    Write-SpectreHost "[bold red]ERROR:[/] Failed to clone repository: [yellow]$escapedError[/]"
                    continue
                }
            }
        }

        Write-SpectreHost ""
    }

    Write-SpectreRule -Color Green
    Write-SpectreHost "[bold green]✓ Skill repositories update completed![/]"

    # Configure agents to use the skills directory
    Write-SpectreHost ""
    Configure-AgentSkillRepositories -SkillsPath $skillsDir
}
