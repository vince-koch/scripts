#Requires -Module PwshSpectreConsole

<#
.SYNOPSIS
    Demonstrates interactive selections with PwshSpectreConsole.
.DESCRIPTION
    Shows a small service-action menu for testing Spectre Console behavior and encoding.
#>

# Install-Module PwshSpectreConsole -Scope CurrentUser

$options = @("Start Service", "Check Status", "Stop Service")
$selected = Read-SpectreSelection -Title "Choose an action" -Choices $options -Color "Green"
Write-Host "You chose: $selected"

$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
