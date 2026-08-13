#Requires -Module PwshSpectreConsole

# Install-Module PwshSpectreConsole -Scope CurrentUser

$options = @("Start Service", "Check Status", "Stop Service")
$selected = Read-SpectreSelection -Title "Choose an action" -Choices $options -Color "Green"
Write-Host "You chose: $selected"

$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
