Try-Import-Module $PSScriptRoot\Ansi.psm1
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

function Config {
    # Prepare menu items
    $menuItems = $configItems | ForEach-Object {
        $expanded = [System.Environment]::ExpandEnvironmentVariables($_['Path'])
        $_ + @{ 
            ExpandedPath = $expanded
            Exists = [System.IO.File]::Exists($expanded) 
        }
    }

    # Display menu
    $selection = Console-Menu -Title "Select a config file to open or ESC to cancel" `
        -Items $menuItems `
        -ItemsProperty { 
            param($item) 
            $pathColor = if ($item['Exists']) { $Ansi.Fg.BrightBlack } else { $Ansi.Fg.Red }
            $path = $item['Path']
            if ($path.Length -gt 40) {
                $path = $path.Substring(0, 20) + "…" + $path.Substring($path.Length - 20)
            }
            "$($item['Name']) $pathColor $path $($Ansi.Reset)"
        }

    # Handle selection (Open the file)
    if ($selection) {
        Write-Host ""
        
        if ($selection['Exists'] -eq $true) {
            Write-Host "Opening: $($selection['ExpandedPath'])" -ForegroundColor Cyan
            Invoke-Item $selection['ExpandedPath']
        }
        else {
            Write-Host "Not Found: $($selection['ExpandedPath'])" -ForegroundColor Red
        }
    }
}

Export-ModuleMember -Function Config