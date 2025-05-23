Try-Import-Module $PSScriptRoot\Console.psm1

function Aws-ListProfiles {
    aws configure list-profiles
}

function Aws-SelectProfile {
    param (
        [string] $profileName = $null
    )

    $profileNames = & aws configure list-profiles | ForEach-Object { $_ }
    
    $useIndex = -not [string]::IsNullOrWhiteSpace($profileName) -and ($profileNames -contains $profileName)
    if ($useIndex) {
        $currentIndex = [array]::IndexOf($profileNames, $profileName)
    }
    else {
        $currentIndex = 0
    }

    $selectedProfileName = Console-Menu -Items $profileNames -CurrentIndex $currentIndex -IgnoreEscape

    return $selectedProfileName
}

function Aws-SetVariable {
    param (
        [string] $VariableName,
        $VariableValue # no cast so we can accept null
    )

    # Set for future sessions (persistent for current user)
    [Environment]::SetEnvironmentVariable($VariableName, $VariableValue, "User")

    # Set for current process
    [System.Environment]::SetEnvironmentVariable($VariableName, $VariableValue, "Process")

    # Set for current process (PowerShell session and child processes)
    if ($VariableValue -eq $null) {
        Remove-Item -Path Env:$VariableName
    }
    else {
        Set-Item -Path Env:$VariableName -Value $VariableValue
    }
}

function Aws-ClearProfileVariables {
    Aws-SetVariable -VariableName "AWS_PROFILE" -VariableValue $null
    Aws-SetVariable -VariableName "AWS_ACCESS_KEY_ID" -VariableValue $null
    Aws-SetVariable -VariableName "AWS_SECRET_ACCESS_KEY" -VariableValue $null
    Aws-SetVariable -VariableName "AWS_SESSION_TOKEN" -VariableValue $null
    Aws-SetVariable -VariableName "AWS_SESSION_TOKEN_EXPIRATION" -VariableValue $null
}

function Aws-ExportProfileVariables {
    param (
        [string] $profileName = $null
    )

    if ([string]::IsNullOrWhiteSpace($profileName)) {
        $profileName = $Env:AWS_PROFILE
    }

    $json = aws configure export-credentials --profile $profileName --format process | ConvertFrom-Json
    # $json

    Aws-SetVariable -VariableName "AWS_PROFILE" -VariableValue $profileName
    Aws-SetVariable -VariableName "AWS_ACCESS_KEY_ID" -VariableValue $json.AccessKeyId
    Aws-SetVariable -VariableName "AWS_SECRET_ACCESS_KEY" -VariableValue $json.SecretAccessKey
    Aws-SetVariable -VariableName "AWS_SESSION_TOKEN" -VariableValue $json.SessionToken
    Aws-SetVariable -VariableName "AWS_SESSION_TOKEN_EXPIRATION" -VariableValue $json.Expiration
}

function Aws-Login {
    param (
        [string] $profileName = $null
    )

    Aws-ClearProfileVariables

    $profileName = Aws-SelectProfile $profileName

    aws sso login --profile $profileName

    $isAuthenticated = Aws-IsAuthenticated -profileName $profileName
    if ($isAuthenticated -eq $true) {
        Aws-SetVariable -VariableName "AWS_PROFILE" -VariableValue $profileName
        #Aws-ExportProfileVariables -profileName $profileName
    }
    else {
        Write-Host "AWS Profile $($profileName) has not been properly authenticated.  Maybe check ~/.aws/config?" -ForegroundColor Red
    }
}

function Aws-IsAuthenticated {
    param (
        [string] $profileName = $null
    )

    try {
        if ([string]::IsNullOrWhiteSpace($profileName)) {
            $profileName = $Env:AWS_PROFILE
        }

        $output = aws sts get-caller-identity --profile $profileName 2>&1
        if ($LASTEXITCODE -eq 0) {
            $true
        }
        else {
            $false
        }
    }
    catch {
        $false
    }
}

function Aws-LocalStack {
    param(
        [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )
    
    aws --endpoint-url=http://localhost:4566 @Args
}

New-Alias -Name awslocal -Value Aws-LocalStack -Force

Export-ModuleMember -Function Aws-ListProfiles
Export-ModuleMember -Function Aws-ClearProfileVariables
Export-ModuleMember -Function Aws-ExportProfileVariables
Export-ModuleMember -Function Aws-Login
Export-ModuleMember -Function Aws-IsAuthenticated
Export-ModuleMember -Function Aws-LocalStack

Export-ModuleMember -Alias awslocal