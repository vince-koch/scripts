Try-Import-Module $PSScriptRoot\Console.psm1

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

function Config {
    # Import the Console module
    Import-Module "$PSScriptRoot\Console.psm1" -DisableNameChecking

    # Prepare menu items
    $menuItems = $configItems | ForEach-Object { $_.Name }
    $menuItems += "Cancel"

    # Display menu
    $selection = Console-Menu -Title "Select a config file to open" -Items $menuItems

    # Handle selection
    if ($selection -and $selection -ne "Cancel") {
        $selectedItem = $configItems | Where-Object { $_.Name -eq $selection }
        if ($selectedItem) {
            # Open the file
            $path = [Environment]::ExpandEnvironmentVariables($selectedItem.Path)
            Invoke-Item $path
        }
    }
}

Export-ModuleMember -Function Config