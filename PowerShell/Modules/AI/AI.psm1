# AI Module - Manages skill repositories and AI agent configurations

Import-Module PwshSpectreConsole -ErrorAction Stop

# Get the module root directory
$moduleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Dot-source all private functions
$privateFunctions = @(
    'Get-AIHome',
    'Show-AgentSelectionMenu',
    'Show-InstalledAgents',
    'Update-AgentConfiguration'
)

foreach ($function in $privateFunctions) {
    $functionPath = Join-Path $moduleRoot "Private\$function.ps1"
    if (Test-Path $functionPath) {
        . $functionPath
    }
}

# Dot-source all public functions
$publicFunctions = @(
    'Initialize-AI',
    'Update-SkillRepositories',
    'Configure-AgentSkillRepositories',
    'Get-InstalledAgents',
    'Show-AIMenu',
    'Show-AIHelp',
    'ai'
)

foreach ($function in $publicFunctions) {
    $functionPath = Join-Path $moduleRoot "Public\$function.ps1"
    if (Test-Path $functionPath) {
        . $functionPath
    }
}

# Export public functions
Export-ModuleMember -Function $publicFunctions
