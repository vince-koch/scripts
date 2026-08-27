@{
    RootModule            = 'AI.psm1'
    ModuleVersion         = '1.0.0'
    GUID                  = '8a4b2c1d-f9e3-4d7c-a2b1-e5f8c3d9a1b2'
    Author                = 'Vince'
    CompanyName           = 'Personal'
    Description           = 'Manages AI agent configurations and skill repositories for Copilot, Claude, Cursor, and Codex'

    PowerShellVersion     = '7.0'
    RequiredModules       = @('PwshSpectreConsole')

    FunctionsToExport     = @(
        'Initialize-AI',
        'Update-SkillRepositories',
        'Get-InstalledAgents',
        'Configure-AgentSkillRepositories',
        'Show-AIMenu',
        'Show-AIHelp',
        'ai'
    )

    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @()

    PrivateData           = @{
        PSData = @{
            Tags       = @('AI', 'agents', 'skills', 'copilot', 'claude', 'cursor', 'codex')
            LicenseUri = ''
            ProjectUri = ''
            ReleaseNotes = @'
1.0.0 - Initial release
- Support for detecting and configuring Copilot, Claude, Cursor, and Codex
- Skill repository management with git and local filesystem support
- Agent configuration with dynamic skills path injection
'@
        }
    }

    HelpInfoURI           = ''
}
