#
# Function to import a module if installed, and install if not installed
#

function Use-Module {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$MinimumVersion,

        [switch]$Force
    )

    # Already loaded?
    if (Get-Module -Name $Name) {
        return
    }

    # Try to import if already installed
    if (Get-Module -ListAvailable -Name $Name) {
        Import-Module $Name -Force:$Force
        return
    }

    # Install it from PowerShell Gallery
    try {
        Write-Host "Installing module '$Name'..."
        $installParams = @{
            Name        = $Name
            Scope       = 'CurrentUser'
            Force       = $Force.IsPresent
            ErrorAction = 'Stop'
        }

        if ($MinimumVersion) {
            $installParams.MinimumVersion = $MinimumVersion
        }

        Install-Module @installParams

        Write-Host "Importing module '$Name'..."
        Import-Module $Name -Force:$Force
    }
    catch {
        Write-Error "Failed to install or import module '$Name': $_"
        throw
    }
}