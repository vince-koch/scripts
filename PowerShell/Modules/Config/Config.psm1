$configItems = @(
    @{
        Name = "AWS CLI Config"
        Path = "%USERPROFILE%\.aws\config"
    },
    @{
        Name = "AWS CLI Credentials"
        Path = "%USERPROFILE%\.aws\credentials"
    },
    @{
        Name = "Claris Mongo Connections"
        Path = "%USERPROFILE%\.claris\mongo-connections.json"
    }
    @{
        Name = "Claude Desktop Config"
        Path = "%APPDATA%\Claude\claude_desktop_config.json"
    },
    @{
        Name = "Git Config"
        Path = "%USERPROFILE%\.gitconfig"
    },
    @{
        Name = "Nuget - User Config"
        Path = "%APPDATA%\NuGet\NuGet.Config"
    },
    @{
        Name = "PowerShell Profile"
        Path = "$PROFILE"
    },
    @{
        Name = "VS Code Keybindings"
        Path = "%USERPROFILE%\AppData\Roaming\Code\User\keybindings.json"
    },
    @{
        Name = "VS Code Settings"
        Path = "%USERPROFILE%\AppData\Roaming\Code\User\settings.json"
    },
    @{
        Name = "Windows Terminal Settings"
        Path = "%USERPROFILE%\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    }
)

function Show-Config {
    Import-Module PwshSpectreConsole -ErrorAction Stop

    # Prepare menu items
    $menuItems = $configItems | ForEach-Object {
        $expanded = [System.Environment]::ExpandEnvironmentVariables($_['Path'])
        $_ + @{ 
            ExpandedPath = $expanded
            Exists = [System.IO.File]::Exists($expanded) 
        }
    }

    # Display menu
    $selection = Read-SpectreSelection `
        -Message 'Select a config file to view' `
        -Choices $menuItems `
        -ChoiceLabelProperty {
            $status = if ($_['Exists']) { '[green]✓[/]' } else { '[red]✗[/]' }
            $name = ([string]$_['Name']).PadRight(30)
            $path = [string]$_['Path'] | Get-SpectreEscapedText
            $pathColor = if ($_['Exists']) { 'grey' } else { 'red' }

            "$status  [white]$name[/]  [$pathColor]$path[/]"
        } `
        -EnableSearch `
        -Color 'Cyan1'

    # Handle selection (Open the file)
    if ($selection) {
        Write-Host ""
        
        if ($selection['Exists'] -eq $true) {
            # Write-Host "Opening: $($selection['ExpandedPath'])" -ForegroundColor Cyan
            # Start-Process $selection['ExpandedPath']
            Write-Host ""
            Write-Host "$($selection['ExpandedPath'])" -ForegroundColor Cyan
            & cat $selection['ExpandedPath']
        }
        else {
            Write-Host "Not Found: $($selection['ExpandedPath'])" -ForegroundColor Red
        }
    }
}

Set-Alias -Name config -Value Show-Config

Export-ModuleMember -Function Show-Config -Alias config
