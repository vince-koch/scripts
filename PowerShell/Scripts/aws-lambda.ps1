# Dependencies
#     dotnet tool install -g Amazon.Lambda.Tools
#     Install-Module AWS.Tools.Installer -Scope CurrentUser # Install the installer if not already installed
#     Install-AWSToolsModule AWS.Tools.Common, AWS.Tools.SecurityToken, AWS.Tools.Lambda -CleanUp # Install all required modules in one shot
#     Install-Module PwshSpectreConsole -Scope CurrentUser
#
# Other useful things
#     Update-AWSToolsModule AWS.Tools.Common, AWS.Tools.SecurityToken, AWS.Tools.Lambda -CleanUp
#     Get-Module -ListAvailable AWS.Tools.*

if ($PsVersionTable.PSVersion -lt [version]"7.0") {
    Write-Host "Use PowerShell Core 7+ you silly sausage!" -ForegroundColor Yellow
    exit 1
}

$ErrorActionPreference = 'Stop'
$scriptVersion = "1.7"


Import-Module AWS.Tools.Common
Import-Module AWS.Tools.SecurityToken
Import-Module AWS.Tools.Lambda
Import-Module PwshSpectreConsole


$region = "us-east-1"

$classes = @"
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.Json;

public class EnvironmentVariable {
    public string Key { get; set; }
    public string Value { get; set; }
}

public class DeploymentTarget {
    public string Label { get; set; }
    public string AwsAccountId { get; set; }
    public string LambdaName { get; set; }
    public List<EnvironmentVariable> EnvironmentVariables { get; set; }
}

public class LambdaSettings {
    public string ProjectName { get; set; }
    public string FunctionHandler { get; set; }
    public int FunctionTimeoutSeconds { get; set; }
}

public class ConfigRoot {
    public LambdaSettings Lambda { get; set; }
    public List<DeploymentTarget> DeploymentTargets { get; set; }
}
"@
Add-Type -TypeDefinition $classes
Add-Type -AssemblyName System.Text.Json


function LoadConfigJson {
    [string] $jsonPath = [System.IO.Path]::Combine($PSScriptRoot, "lambda.json")
    Write-Host "Config Path " -ForegroundColor DarkGray -NoNewLine; Write-Host $jsonPath

    $options = [System.Text.Json.JsonDocumentOptions]::new()
    $options.CommentHandling = [System.Text.Json.JsonCommentHandling]::Skip
    $options.AllowTrailingCommas = $true

    $stream = [System.IO.File]::OpenRead($jsonPath)
    $document = [System.Text.Json.JsonDocument]::Parse($stream, $options)
    $root = $document.RootElement

    $ms = [System.IO.MemoryStream]::new()
    $writer = [System.Text.Json.Utf8JsonWriter]::new($ms)
    $root.WriteTo($writer)
    $writer.Flush()

    $json = [System.Text.Encoding]::UTF8.GetString($ms.ToArray())

    $config = [System.Text.Json.JsonSerializer]::Deserialize($json, [ConfigRoot])
    $config.Lambda.FunctionHandler = $config.Lambda.FunctionHandler.Replace('$ProjectName', $config.Lambda.ProjectName)

    return $config
}


function Select-ItemByProperty {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Items,

        [Parameter(Mandatory=$true)]
        [string]$LabelPropertyName,

        [string]$Message = "Select an item"
    )

    if (-not $Items[0].PSObject.Properties[$LabelPropertyName]) {
        Throw "Property '$LabelPropertyName' does not exist on the provided items."
    }

    return Read-SpectreSelection -Message $Message -Choices $Items -ChoiceLabelProperty $LabelPropertyName -EnableSearch
}


function Select-MultipleItemsByProperty {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Items,

        [Parameter(Mandatory=$true)]
        [string]$LabelPropertyName,

        [string]$Message = "Select items (space to toggle, enter to confirm)"
    )

    if (-not $Items[0].PSObject.Properties[$LabelPropertyName]) {
        Throw "Property '$LabelPropertyName' does not exist on the provided items."
    }

    return @(Read-SpectreMultiSelection -Message $Message -Choices $Items -ChoiceLabelProperty $LabelPropertyName -PageSize 15)
}


function Lambda-Build {
    param (
        [string] $ProjectName,
        [string] $ProjectFolder,
        [string] $PackagePath
    )

    New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($PackagePath)) | Out-Null
    if (Test-Path $PackagePath) { Remove-Item $PackagePath -Force }

    Write-Host "Building package for '$ProjectName'." -ForegroundColor Cyan

    dotnet lambda package `
        --project-location "$ProjectFolder" `
        --configuration Release `
        --function-architecture x86_64 `
        --output-package "$PackagePath" | Out-Host

    if ($LASTEXITCODE -ne 0) {
        throw "Lambda package build failed with exit code $LASTEXITCODE"
    }

    Write-Host "Package built: $PackagePath" -ForegroundColor Green
}


function Lambda-WaitForReady {
    param(
        [Parameter(Mandatory)] [string] $FunctionName,
        [string] $ProfileName,
        [string] $Region = "us-east-1"
    )

    Write-Host "Waiting for lambda ready... " -NoNewLine

    $deadline = (Get-Date).AddMinutes(5)

    do {
        $cfg = Get-LMFunctionConfiguration -FunctionName $FunctionName -ProfileName $ProfileName -Region $Region
        # Helpful fields:
        # $cfg.State: Active | Pending | Inactive | Failed
        # $cfg.StateReason
        # $cfg.LastUpdateStatus: Successful | InProgress | Failed
        # $cfg.LastUpdateStatusReason

        if ($cfg.LastUpdateStatus -eq 'Failed' -or $cfg.State -eq 'Failed') {
            Write-Host "FAIL" -ForegroundColor Red
            throw "Lambda update failed. State=$($cfg.State). LastUpdateStatus=$($cfg.LastUpdateStatus). Reason=$($cfg.LastUpdateStatusReason)"
        }

        if ($cfg.LastUpdateStatus -eq 'Successful' -and $cfg.State -eq 'Active') {
            Write-Host "OK" -ForegroundColor Green
            return
        }

        Start-Sleep -Seconds 3
    } while ((Get-Date) -lt $deadline)

    Write-Host "FAIL" -ForegroundColor Red
    throw "Timed out waiting for Lambda to become Active/Successful."
}


function Lambda-CheckToken {
    param (
        [string] $ExpectedAccountId
    )

    try {
        $identity = Get-STSCallerIdentity
    }
    catch {
        throw "Unable to check AWS credentials."
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Invalid or expired AWS credentials (Exit=$LASTEXITCODE)."
    }

    if ($identity.Account -ne $expectedAccountId) {
        throw "Valid AWS credentials found, but for wrong account (Expected $ExpectedAccountId but found $($identity.Account))."
    }

    Write-Host "Valid AWS credentials for account $expectedAccountId." -ForegroundColor Green
}


function Lambda-Deploy {
    param (
        [string] $FunctionName,
        [string] $ProjectFolder,
        [string] $PackagePath,
        [string] $ProfileName,
        [string] $Region
    )

    Lambda-WaitForReady -FunctionName $FunctionName -ProfileName $ProfileName -Region $Region

    Write-Host "Updating code for function '$FunctionName' from '$PackagePath'." -ForegroundColor Cyan

    $output = dotnet lambda deploy-function $FunctionName `
        --project-location "$ProjectFolder" `
        --package "$PackagePath" `
        --function-runtime dotnet8 `
        --profile $ProfileName `
        --region $Region `
        --disable-interactive true

    $output | Out-Host

    if ($LASTEXITCODE -ne 0) {
        # Write-Host "Lambda code deployment failed with exit code $LASTEXITCODE" -ForegroundColor Red
        throw "Lambda code deployment failed with exit code $LASTEXITCODE"
    }

    Write-Host "Updated code for function '$FunctionName'." -ForegroundColor Green
}


function Lambda-SetFunctionHandler {
    param (
        [string] $FunctionName,
        [string] $FunctionHandler,
        [string] $ProfileName,
        [string] $Region
    )

    Lambda-WaitForReady -FunctionName $FunctionName -ProfileName $ProfileName -Region $Region

    Write-Host "Updating handler for function '$FunctionName' to '$FunctionHandler'." -ForegroundColor Cyan

    $output = Update-LMFunctionConfiguration `
        -FunctionName $FunctionName `
        -Handler "$FunctionHandler" `
        -ProfileName $ProfileName `
        -Region $Region

    $output | Out-Host

    if ($LASTEXITCODE -ne 0) {
        # Write-Host "Lambda configuration update failed with exit code $LASTEXITCODE" -ForegroundColor Red
        throw "Lambda configuration update failed with exit code $LASTEXITCODE"
    }

    Write-Host "Updated handler for function '$FunctionName' to '$FunctionHandler'." -ForegroundColor Green
}


function Lambda-SetTimeoutInSeconds {
    param (
        [string] $FunctionName,
        [int] $TimeoutInSeconds,
        [string] $ProfileName,
        [string] $Region
    )

    if ($TimeoutInSeconds -lt 1 -or $TimeoutInSeconds -gt 900) {
        Write-Output "TimeoutInSecond is invalid (must be between 1 and 900 seconds)" -ForegroundColor Red
        return;
    }
  
    Lambda-WaitForReady -FunctionName $FunctionName -ProfileName $ProfileName -Region $Region

    Write-Host "Updating function '$FunctionName' timeout to '$TimeoutInSeconds' seconds." -ForegroundColor Cyan

    $output = Update-LMFunctionConfiguration `
        -FunctionName $FunctionName `
        -Timeout $TimeoutInSeconds `
        -ProfileName $ProfileName `
        -Region $Region

    $output | Out-Host

    if ($LASTEXITCODE -ne 0) {
        # Write-Host "Lambda configuration update failed with exit code $LASTEXITCODE" -ForegroundColor Red
        throw "Lambda configuration update failed with exit code $LASTEXITCODE"
    }

    Write-Host "Updated function '$FunctionName' timeout to '$TimeoutInSeconds' seconds." -ForegroundColor Green
}


function Lambda-SetEnvironmentVariables {
    param (
        [string] $FunctionName,
        [array] $EnvironmentVariables,  # List of objects with .Key and .Value
        [string] $ProfileName,
        [string] $Region
    )

    if (-not $EnvironmentVariables -or $EnvironmentVariables.Count -eq 0) {
        Write-Host "No environment variables provided. Skipping update for '$FunctionName'." -ForegroundColor Yellow
        return
    }

    Lambda-WaitForReady -FunctionName $FunctionName -ProfileName $ProfileName -Region $Region

    Write-Host "Updating environment variables for function '$FunctionName'." -ForegroundColor Cyan

    # Retrieve current environment variables
    $functionConfig = Get-LMFunctionConfiguration `
        -FunctionName $FunctionName `
        -ProfileName $ProfileName `
        -Region $Region
    
    # Start with current environment variables
    $envVars = $functionConfig.Environment.Variables
    if ($null -eq $envVars) {
        $envVars = @{}
    }

    # Merge new environment variables
    foreach ($pair in $EnvironmentVariables) {
        $envVars[$pair.Key] = $pair.Value
    }

    # Run PowerShell cmdlet
    $output = Update-LMFunctionConfiguration `
        -FunctionName $FunctionName `
        -Environment_Variable $envVars `
        -ProfileName $ProfileName `
        -Region $Region

    $output | Out-Host

    if ($LASTEXITCODE -ne 0) {
        # Write-Host "Lambda configuration update failed with exit code $LASTEXITCODE" -ForegroundColor Red
        throw "Lambda configuration update failed with exit code $LASTEXITCODE"
    }

    Write-Host "Updated environment variables for function '$FunctionName'." -ForegroundColor Green
}


function Lambda-LocalTest {
    [string] $FunctionName,
    [string] $Payload

    dotnet lambda invoke-function MyFunction --payload "$Payload"
}


function Ensure-AwsProfile {
    param (
        [string] $AccountId
    )

    # list profiles
    $profiles = Get-AWSCredential -ListProfileDetail

    # see if we already have a session for the requested account
    foreach ($p in $profiles) {
        try {
            $identity = Get-STSCallerIdentity -ProfileName $p.ProfileName -Region $region
            if ($identity.Account -eq $AccountId) {
                $selectedProfile = $p
                break
            }
        }
        catch {
            # Write-Warning "Profile $($p.ProfileName) failed: $_"
        }
    }

    # otherwise lets give them a menu
    while ($selectedProfile -eq $null) {
        $p = Select-ItemByProperty -Items $profiles -LabelPropertyName "ProfileName" -Message "Select [cyan]AWS Profile[/]"

        # If this is an SSO profile, ensure a fresh login:
        Invoke-AWSSSOLogin -ProfileName $p.ProfileName       # opens browser if needed

        try {
            $identity = Get-STSCallerIdentity -ProfileName $p.ProfileName -Region $region
            if ($identity.Account -eq $AccountId) {
                $selectedProfile = $p
                break
            }
        }
        catch {
            # Write-Warning "Profile $($p.ProfileName) failed: $_"
        }
    }

    # Make the profile/region the default for this PS session:
    #Initialize-AWSDefaultConfiguration -ProfileName $selectedProfile.ProfileName -Region $region
    Set-AWSCredential -ProfileName $selectedProfile.ProfileName
    Set-DefaultAWSRegion -Region $region

    return $selectedProfile
}


function Main {
    # title and menu
    Write-Host "Lambda Deployment Script $($scriptVersion)" -ForegroundColor Magenta
    $configFile = LoadConfigJson    
    Write-Host "Project Name " -ForegroundColor DarkGray -NoNewLine; Write-Host "$($configFile.Lambda.ProjectName)" -ForegroundColor Magenta
    Write-Host "Function Name " -ForegroundColor DarkGray -NoNewLine; Write-Host "$($configFile.Lambda.FunctionHandler)"
    
    # package: reuse existing zip or build
    $ProjectFolder = [System.IO.Path]::Combine($PSScriptRoot, $configFile.Lambda.ProjectName)
    $PackagePath = [System.IO.Path]::Combine($PSScriptRoot, "artifacts", "$($configFile.Lambda.ProjectName).zip")

    $build = $true
    if (Test-Path $PackagePath) {
        $file = Get-Item $PackagePath
        Write-Host "Existing package" -ForegroundColor Cyan
        Write-Host "    File  " -ForegroundColor DarkGray -NoNewLine; Write-Host $file.FullName
        Write-Host "    Size  " -ForegroundColor DarkGray -NoNewLine; Write-Host ("{0:N1} MB" -f ($file.Length / 1MB))
        Write-Host "    Built " -ForegroundColor DarkGray -NoNewLine; Write-Host $file.LastWriteTime
        $useExisting = "Use existing package"
        $rebuild = "Rebuild package"
        $quit = "Quit"
        $answer = Read-SpectreSelection -Message "Package" -Choices @($useExisting, $rebuild, $quit)
        if ($answer -eq $quit) { Write-Host "User cancelled. Exiting script." -ForegroundColor Red; exit 1 }
        $build = $answer -eq $rebuild
    }

    if ($build) {
        Lambda-Build -ProjectName $configFile.Lambda.ProjectName -ProjectFolder $ProjectFolder -PackagePath $PackagePath
    }

    # where are we deploying to
    Write-Host "Deployment Targets" -ForegroundColor Cyan
    $selectedTargets = Select-MultipleItemsByProperty -Items $($configFile.DeploymentTargets) -LabelPropertyName "Label" -Message "Select [cyan]Deployment targets[/]"

    $results = @()
    foreach ($selectedTarget in $selectedTargets) {
        Write-Host ""
        Write-Host "Deployment Target " -ForegroundColor DarkGray -NoNewLine; Write-Host "$($selectedTarget.Label)" -ForegroundColor Magenta
        Write-Host "Lambda Name " -ForegroundColor DarkGray -NoNewLine; Write-Host "$($selectedTarget.LambdaName)"
        Write-Host "Account Id " -ForegroundColor DarkGray -NoNewLine; Write-Host "$($selectedTarget.AwsAccountId)"

        try {
            # ensure login
            $selectedProfile = Ensure-AwsProfile -AccountId $selectedTarget.AwsAccountId
            Write-Host "Profile " -ForegroundColor DarkGray -NoNewLine; Write-Host "$($selectedProfile.ProfileName)"

            Lambda-Deploy -FunctionName $selectedTarget.LambdaName -ProjectFolder $ProjectFolder -PackagePath $PackagePath -ProfileName $selectedProfile.ProfileName -Region $region
            Lambda-SetFunctionHandler -FunctionName $selectedTarget.LambdaName -FunctionHandler $configFile.Lambda.FunctionHandler -ProfileName $selectedProfile.ProfileName -Region $region
            Lambda-SetTimeoutInSeconds -FunctionName $selectedTarget.LambdaName -TimeoutInSeconds $configFile.Lambda.FunctionTimeoutSeconds -ProfileName $selectedProfile.ProfileName -Region $region
            Lambda-SetEnvironmentVariables -FunctionName $selectedTarget.LambdaName -EnvironmentVariables $selectedTarget.EnvironmentVariables -ProfileName $selectedProfile.ProfileName -Region $region
            Lambda-WaitForReady -FunctionName $selectedTarget.LambdaName -ProfileName $selectedProfile.ProfileName -Region $region
            $results += [pscustomobject]@{ Target = $selectedTarget.Label; Status = "OK"; Error = "" }
        }
        catch {
            Write-Host "Deployment to '$($selectedTarget.Label)' failed: $($_.Exception.Message)" -ForegroundColor Red
            $results += [pscustomobject]@{ Target = $selectedTarget.Label; Status = "FAILED"; Error = $_.Exception.Message }
        }
    }

    Write-Host ""
    Write-Host "Summary" -ForegroundColor Cyan
    foreach ($r in $results) {
        $color = if ($r.Status -eq "OK") { "Green" } else { "Red" }
        Write-Host "    $($r.Target): " -NoNewLine; Write-Host $r.Status -ForegroundColor $color
    }
    if ($results | Where-Object Status -eq "FAILED") { exit 1 }
}
    

Main