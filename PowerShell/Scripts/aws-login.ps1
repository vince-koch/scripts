<#
.SYNOPSIS
    Starts an AWS SSO login session.
.DESCRIPTION
    Selects an AWS profile interactively when one is not supplied and invokes the AWS CLI login.
#>

#Requires -Version 7.4
#Requires -Modules PwshSpectreConsole

param(
    [Parameter(Mandatory = $false)]
    [string]$Profile
)


function Get-AwsProfiles
{
    <#
    .SYNOPSIS
    Quickly retrieves AWS profiles by reading the config and credentials files directly.
    .DESCRIPTION
    Parses ~/.aws/config and ~/.aws/credentials to extract profile names. Much faster than 'aws configure list-profiles'.
    #>
    $configPath = Join-Path $env:USERPROFILE ".aws\config"
    $credentialsPath = Join-Path $env:USERPROFILE ".aws\credentials"
    
    $profiles = @()
    
    # Parse config file for [profile name] and [default] entries (skip [sso-session])
    if (Test-Path $configPath)
    {
        Get-Content $configPath | ForEach-Object {
            if ($_ -match '^\[profile\s+(.+)\]$')
            {
                $profiles += $matches[1]
            }
            elseif ($_ -match '^\[default\]$')
            {
                $profiles += 'default'
            }
        }
    }
    
    # Parse credentials file for [name] entries
    if (Test-Path $credentialsPath)
    {
        Get-Content $credentialsPath | ForEach-Object {
            if ($_ -match '^\[(.+)\]$')
            {
                $profiles += $matches[1]
            }
        }
    }
    
    # Return unique profiles only
    return $profiles | Select-Object -Unique
}


function Select-AwsProfile
{
    # Fast method: read config file directly
    # $profiles = aws configure list-profiles # Slow method: use AWS CLI (commented out for performance)
    [string[]]$profiles = @(Get-AwsProfiles | Sort-Object)

    if (-not $profiles)
    {
        Write-Host "No AWS profiles found." -ForegroundColor Red
        Write-Host "Please configure AWS profiles using 'aws configure' or by editing ~/.aws"
        exit 1
    }

    if (-not (Get-Module -Name PwshSpectreConsole))
    {
        if (-not (Get-Module -ListAvailable -Name PwshSpectreConsole))
        {
            throw 'Profile selection requires PwshSpectreConsole. Install it with: Install-Module PwshSpectreConsole -Scope CurrentUser'
        }

        Import-Module PwshSpectreConsole -ErrorAction Stop
    }

    $selectionParameters = @{
        Message      = 'Select an AWS profile'
        Choices      = $profiles
        EnableSearch = $true
        Color        = 'Cyan1'
    }

    return Read-SpectreSelection @selectionParameters
}


function Assert-Success
{
    <#
    .SYNOPSIS
    Checks if the last command succeeded, displays error and exits if it failed.
    .PARAMETER ErrorMessage
    The error message to display if the command failed.
    .PARAMETER Fatal
    Whether to exit the script on failure (default: $true).
    #>
    param(
        [string]$ErrorMessage,
        [bool]$Fatal = $true
    )
    
    if ($LASTEXITCODE -eq 0)
    {
        Write-Host "✔  $ErrorMessage" -ForegroundColor "Green"
    }    
    else
    {
        if ($Fatal)
        {
            Write-Host "✖  $ErrorMessage" -ForegroundColor "Red"
            exit 1
        }
        else {
            Write-Host "⚠  $ErrorMessage" -ForegroundColor "Yellow"
        }
    }
}


function Invoke-AwsCliWithSsoRetry
{
    <#
    .SYNOPSIS
    Runs an AWS CLI command and retries once after SSO re-login if it fails.
    .PARAMETER Profile
    The AWS profile name.
    .PARAMETER ActionName
    Description used for status output.
    .PARAMETER Command
    Script block that executes the AWS CLI command.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Profile,

        [Parameter(Mandatory = $true)]
        [string]$ActionName,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Command
    )

    $result = & $Command
    if ($LASTEXITCODE -eq 0)
    {
        Assert-Success $ActionName
        return $result
    }

    Write-Host "⚠  $ActionName failed. Refreshing AWS SSO session and retrying..." -ForegroundColor Yellow

    aws sso login --profile $Profile
    Assert-Success "AWS SSO Login"

    $result = & $Command
    Assert-Success $ActionName

    return $result
}


function Get-NuGetSourceNameByUrl
{
    <#
    .SYNOPSIS
    Resolves a NuGet source name from nuget.config by matching the source URL.
    .PARAMETER SourceUrl
    The package source URL to match.
    .PARAMETER ConfigPath
    Path to nuget.config. Defaults to the user-level config.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceUrl,

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = (Join-Path $env:APPDATA "NuGet\NuGet.Config")
    )

    if (-not (Test-Path $ConfigPath))
    {
        throw "NuGet config not found at '$ConfigPath'."
    }

    [xml]$config = Get-Content -Path $ConfigPath
    $normalizedUrl = $SourceUrl.TrimEnd("/")

    $match = $config.configuration.packageSources.add |
        Where-Object { $_.value -and ($_.value.TrimEnd("/") -ieq $normalizedUrl) } |
        Select-Object -First 1

    if (-not $match)
    {
        throw "No NuGet source in '$ConfigPath' matches URL '$SourceUrl'."
    }

    return $match.key
}


function Invoke-AwsLogin
{
    <#
    .SYNOPSIS
    Logs into AWS SSO and optionally CodeArtifact.
    .PARAMETER Profile
    The AWS profile name to log into.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Profile
    )

    # Login to AWS
    Write-SpectreHost "🔐 Logging into profile [darkorange]$Profile[/]"

    # aws sso login --profile $Profile
    # Assert-Success "AWS SSO Login"
    aws sts get-caller-identity `
        --profile $Profile `
        --output none 2>$null

    if ($LASTEXITCODE -eq 0)
    {
        Write-Host "✔  AWS SSO session already valid." -ForegroundColor Green
    }
    else
    {
        Write-Host "⚠  AWS SSO session expired. Logging in..." -ForegroundColor Yellow

        aws sso login --profile $Profile

        Assert-Success "AWS SSO Login"
    }

    $env:AWS_PROFILE = $Profile
    #Write-Host "AWS_PROFILE set to '$Profile' for this session."

    # If ClarisHealth profile
    if ($Profile -like "*735155089756*" -or $Profile -like "*Claris*")
    {
        # Login to CodeArtifact
        $token = Invoke-AwsCliWithSsoRetry `
            -Profile $Profile `
            -ActionName "Obtain CodeArtifact login token." `
            -Command {
                aws codeartifact get-authorization-token `
                    --domain etl-shared-nuget `
                    --domain-owner 735155089756 `
                    --profile $Profile `
                    --output text `
                    --query authorizationToken
            }

        $endpoint = Invoke-AwsCliWithSsoRetry `
            -Profile $Profile `
            -ActionName "Obtain CodeArtifact repository endpoint" `
            -Command {
                aws codeartifact get-repository-endpoint `
                    --domain etl-shared-nuget `
                    --domain-owner 735155089756 `
                    --repository clh-etl-nugets `
                    --profile $Profile `
                    --output text `
                    --query repositoryEndpoint `
                    --format nuget
            }

        $sourceUrl = $endpoint.TrimEnd("/") + "/v3/index.json"
        $sourceName = Get-NuGetSourceNameByUrl -SourceUrl $sourceUrl

        # Update Nuget source with new token (remove old source first to avoid duplicate errors)
        dotnet nuget remove source $sourceName 2>$null

        dotnet nuget add source $sourceUrl `
            --name $sourceName `
            --username aws `
            --password $token `
            --store-password-in-clear-text

        Assert-Success "Update nuget token"
    }
}


# Main logic: validate provided profile or select one
if ($Profile)
{
    # Profile provided via parameter - validate it exists
    [string[]]$allProfiles = @(Get-AwsProfiles)
    if ($allProfiles -notcontains $Profile)
    {
        Write-Host "Profile '$Profile' not found." -ForegroundColor Red
        Write-Host "Available profiles: $($allProfiles -join ', ')" -ForegroundColor Yellow
        exit 1
    }
    $selectedProfile = $Profile
}
else
{
    # No profile provided - show selection menu
    $selectedProfile = Select-AwsProfile
    if (-not $selectedProfile) {
        return
    }
}

# Execute login
Invoke-AwsLogin -Profile $selectedProfile
