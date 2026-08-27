<#
.SYNOPSIS
Detects AI agents installed on the current system.

.DESCRIPTION
Checks for Copilot, Claude, Cursor, and Codex by their home directories.
Returns hashtables with Name, HomePath, SkillsPath, and Installed.
#>
function Get-InstalledAgents {
    $agents = @()
    $home = [Environment]::GetFolderPath("UserProfile")

    $copilotHome = Join-Path $home ".copilot"
    if (Test-Path $copilotHome) {
        $agents += , @{
            Name = "Copilot"
            HomePath = $copilotHome
            SkillsPath = Join-Path $copilotHome "skills"
            Installed = $true
        }
    }

    $claudeHome = Join-Path $home ".claude"
    if (Test-Path $claudeHome) {
        $agents += , @{
            Name = "Claude"
            HomePath = $claudeHome
            SkillsPath = Join-Path $claudeHome "skills"
            Installed = $true
        }
    }

    $cursorHome = Join-Path $home ".cursor"
    if (Test-Path $cursorHome) {
        $agents += , @{
            Name = "Cursor"
            HomePath = $cursorHome
            SkillsPath = Join-Path $cursorHome "skills"
            Installed = $true
        }
    }

    $codexHome = Join-Path $home ".codex"
    if (Test-Path $codexHome) {
        $agents += , @{
            Name = "Codex"
            HomePath = $codexHome
            SkillsPath = Join-Path (Join-Path $home ".agents") "skills"
            Installed = $true
        }
    }

    return @($agents)
}
