function Get-NormalizedFullPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/').ToLowerInvariant()
}

function Set-SkillRepositoryLink {
    param(
        [string]$LinkPath,
        [string]$TargetPath
    )

    $repoName = Split-Path $LinkPath -Leaf
    $escapedLink = [string]$LinkPath | Get-SpectreEscapedText
    $escapedTarget = [string]$TargetPath | Get-SpectreEscapedText
    $desired = Get-NormalizedFullPath $TargetPath

    $existing = Get-Item -LiteralPath $LinkPath -Force -ErrorAction SilentlyContinue
    if ($existing) {
        $isLink = $existing.LinkType -in @('SymbolicLink', 'Junction')
        if (-not $isLink) {
            Write-SpectreHost "    [yellow]Skipped ${repoName}:[/] [blue]$escapedLink[/] exists and is not a link"
            return
        }

        $rawTarget = [string]@($existing.Target)[0]
        if ($rawTarget -and -not [System.IO.Path]::IsPathRooted($rawTarget)) {
            $rawTarget = Join-Path (Split-Path $LinkPath) $rawTarget
        }
        $current = Get-NormalizedFullPath $rawTarget
        if ($current -eq $desired) {
            Write-SpectreHost "    [green]✓[/] $repoName already linked"
            return
        }

        # Remove the link only — never -Recurse, which can delete the target
        Remove-Item -LiteralPath $LinkPath -Force
    }

    try {
        $linkType = if ($IsWindows) { 'Junction' } else { 'SymbolicLink' }
        New-Item -ItemType $linkType -Path $LinkPath -Target $TargetPath -Force | Out-Null
        Write-SpectreHost "    [green]✓[/] Linked [cyan]$repoName[/] → [blue]$escapedTarget[/]"
    }
    catch {
        $escapedError = [string]$_ | Get-SpectreEscapedText
        Write-SpectreHost "    [bold red]ERROR:[/] Failed to link [cyan]$repoName[/] to [blue]$escapedLink[/]: [yellow]$escapedError[/]"
    }
}

<#
.SYNOPSIS
Links each skill repository into an agent's native skills directory.
#>
function Update-AgentConfiguration {
    param (
        [hashtable]$Agent,
        [string]$SkillsPath
    )

    $agentName = $Agent.Name
    $agentSkillsPath = $Agent.SkillsPath
    $escapedAgentSkills = [string]$agentSkillsPath | Get-SpectreEscapedText

    Write-SpectreHost "`n[cyan]Configuring $agentName...[/]"

    if (-not (Test-Path $agentSkillsPath)) {
        New-Item -ItemType Directory -Path $agentSkillsPath -Force | Out-Null
        Write-SpectreHost "    [green]✓[/] Created [yellow]$escapedAgentSkills[/]"
    }

    $repos = @(Get-ChildItem -LiteralPath $SkillsPath -Directory -ErrorAction SilentlyContinue)
    if ($repos.Count -eq 0) {
        $escapedCanonical = [string]$SkillsPath | Get-SpectreEscapedText
        Write-SpectreHost "    [yellow]No skill repositories in $escapedCanonical. Run [white]ai update skills[/] first.[/]"
        return
    }

    Write-SpectreHost "    Skills: [blue]$escapedAgentSkills[/]"
    foreach ($repo in $repos) {
        Set-SkillRepositoryLink `
            -LinkPath (Join-Path $agentSkillsPath $repo.Name) `
            -TargetPath $repo.FullName
    }
}
