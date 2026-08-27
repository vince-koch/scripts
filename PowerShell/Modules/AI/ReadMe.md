# AI Module

PowerShell module for managing AI agent configurations and skill repositories across Copilot, Claude, Cursor, and Codex.

The front door is the `ai` command. With no arguments it opens an interactive menu; with arguments it dispatches to the same operations.

## Requirements

- PowerShell 7+
- PwshSpectreConsole: `Install-Module -Name PwshSpectreConsole`
- Git (for repository cloning/pulling)

## Installation

### Method 1: From Module Path

Copy the `AI` folder to your PowerShell modules directory:

- **Windows**: `C:\Users\<username>\Documents\PowerShell\Modules\AI`
- **Linux/macOS**: `~/.local/share/powershell/Modules/AI`

### Method 2: From Custom Location

Add the module path to your PowerShell profile:

```powershell
$ModulePath = "c:\repos\vak\github\scripts\PowerShell\Modules"
if ($env:PSModulePath -notlike "*$ModulePath*") {
    $env:PSModulePath += ";$ModulePath"
}
```

## Usage

```powershell
Import-Module AI

ai                  # Interactive menu
ai help             # Show help (also: ai --help, ai -h)

ai init             # First-time setup (also: ai initialize)
ai home             # Change to the AI_HOME folder
ai update skills    # Clone or update skill repositories
ai update agents    # Symlink skill repos into selected agents
ai agents           # List installed agents (also: ai list, ai list agents)
```

`ai init` sets the user-level `AI_HOME` environment variable (default `~/.ai`), creates that directory, copies `skill-repositories.yml`, runs `ai update skills` (which also configures agents), then opens the folder in Explorer.

`ai home` changes the current location to `AI_HOME`.

`ai update skills` reads `skill-repositories.yml`, clones or pulls git repositories, and creates symbolic links for `file://` paths. Skills land in `<AI_HOME>/skills/<repo-name>`.

`ai update agents` detects installed agents, presents a multi-select menu, and creates a symlink for each skill repository into that agent's native skills directory (`~/.copilot/skills`, `~/.claude/skills`, `~/.cursor/skills`, `~/.agents/skills` for Codex). Canonical copies stay in `<AI_HOME>/skills/<repo-name>`.

The exported functions (`Initialize-AI`, `Update-SkillRepositories`, `Configure-AgentSkillRepositories`, `Get-InstalledAgents`, `Show-AIMenu`, `Show-AIHelp`) are equivalent to the `ai` commands above.

## Configuration

### Environment Variable: AI_HOME

```powershell
$env:AI_HOME = "C:\my\custom\ai\path"
```

If `AI_HOME` is not set, the module uses `~/.ai`. `ai init` writes it as a user-level environment variable.

### skill-repositories.yml

Edit `skill-repositories.yml` in `AI_HOME`:

```yaml
version: 1

repositories:
  - name: myskills
    url: https://github.com/user/my-skills.git

  - name: localskills
    url: file://c:/path/to/local/skills
```

## File Structure

### Module Location

```
Modules/AI/
  ├── AI.psd1
  ├── AI.psm1
  ├── skill-repositories.yml
  ├── ReadMe.md
  ├── Public/                  # Exported commands
  └── Private/                 # Internal helpers
```

### AI_HOME Directory Structure

```
~/.ai/
  ├── skill-repositories.yml
  ├── skills/
  │   ├── repo1/
  │   └── repo2/
  └── .gitignore               # Ignores skills/
```

## Functions

| Function | Front door |
|---|---|
| `Initialize-AI` | `ai init` |
| `Update-SkillRepositories [-ConfigPath <string>]` | `ai update skills` |
| `Configure-AgentSkillRepositories [-SkillsPath <string>]` | `ai update agents` |
| `Get-InstalledAgents` | `ai agents` |
| `Show-AIMenu` | `ai` |
| `Show-AIHelp` | `ai help` |

`Get-InstalledAgents` returns hashtables with `Name`, `HomePath`, `SkillsPath`, and `Installed`.

If `-ConfigPath` is omitted, skill updates use `<AI_HOME>/skill-repositories.yml`. If `-SkillsPath` is omitted, agent configuration uses `<AI_HOME>/skills`.

## Supported AI Agents

- **Copilot** — home `~/.copilot`, skills `~/.copilot/skills`
- **Claude** — home `~/.claude`, skills `~/.claude/skills`
- **Cursor** — home `~/.cursor`, skills `~/.cursor/skills`
- **Codex** — home `~/.codex`, skills `~/.agents/skills`

## Notes

- PwshSpectreConsole is required (interactive menus and formatted output)
- Directory links use junctions on Windows and symbolic links elsewhere
- Git must be available in PATH
- Deleting a symlink in an agent's skills folder does not delete the canonical repo under `AI_HOME`
