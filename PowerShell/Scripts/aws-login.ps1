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
    $profiles = Get-AwsProfiles
    $profiles = $profiles | Sort-Object

    if (-not $profiles)
    {
        Write-Host "No AWS profiles found."
        exit 1
    }

    Write-Host ""
    Write-Host "Available AWS Profiles"
    Write-Host "----------------------"

    for ($i = 0; $i -lt $profiles.Count; $i++)
    {
        Write-Host "$($i + 1)) $($profiles[$i])"
    }

    Write-Host ""

    do
    {
        $selection = Read-Host "Select profile number"

        $valid =
            [int]::TryParse($selection, [ref]$null) -and
            [int]$selection -ge 1 -and
            [int]$selection -le $profiles.Count

        if (-not $valid)
        {
            Write-Host "Invalid selection." -ForegroundColor Red
        }

    } while (-not $valid)

    $profile = $profiles[[int]$selection - 1]
    return $profile
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
    Write-Host ""
    Write-Host "Logging into profile '$Profile'..." -ForegroundColor Cyan
    Write-Host ""

    # aws sso login --profile $Profile
    # Assert-Success "AWS SSO Login"
    try
    {
        aws sts get-caller-identity `
            --profile $Profile `
            --output none 2>$null
        
        Write-Host "✔  AWS SSO session already valid." -ForegroundColor Green
    }
    catch
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
        $token = aws codeartifact get-authorization-token `
            --domain etl-shared-nuget `
            --domain-owner 735155089756 `
            --profile $Profile `
            --output text `
            --query authorizationToken

        Assert-Success "Obtain CodeArtifact login token."
        
        $endpoint = aws codeartifact get-repository-endpoint `
            --domain etl-shared-nuget `
            --domain-owner 735155089756 `
            --repository clh-etl-nugets `
            --profile $Profile `
            --output text `
            --query repositoryEndpoint `
            --format nuget

        Assert-Success "Obtain CodeArtifact repository endpoint"

        $sourceName = "CodeArtifact"
        $sourceUrl = $endpoint.TrimEnd("/") + "/v3/index.json"

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
    $allProfiles = Get-AwsProfiles
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
}

# Execute login
Invoke-AwsLogin -Profile $selectedProfile