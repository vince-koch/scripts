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
    [System.Environment]::SetEnvironmentVariable($VariableName, $VariableValue, "User")

    # Set for current process
    [System.Environment]::SetEnvironmentVariable($VariableName, $VariableValue, "Process")

    # Set for current process (PowerShell session and child processes)
    if ($VariableValue -eq $null) {
        Remove-Item -Path Env:$VariableName -ErrorAction SilentlyContinue
    }
    else {
        Set-Item -Path Env:$VariableName -Value $VariableValue
    }
}

function Aws-ClearVariables {
    Aws-SetVariable -VariableName "AWS_PROFILE" -VariableValue $null
    #Aws-SetVariable -VariableName "AWS_ACCESS_KEY_ID" -VariableValue $null
    #Aws-SetVariable -VariableName "AWS_SECRET_ACCESS_KEY" -VariableValue $null
    #Aws-SetVariable -VariableName "AWS_SESSION_TOKEN" -VariableValue $null
    #Aws-SetVariable -VariableName "AWS_SESSION_TOKEN_EXPIRATION" -VariableValue $null
}

function Aws-ExportVariables {
    param (
        [string] $profileName = $null
    )

    if ([string]::IsNullOrWhiteSpace($profileName)) {
        $profileName = $Env:AWS_PROFILE
    }

    $json = aws configure export-credentials --profile $profileName --format process | ConvertFrom-Json
    # $json

    Aws-SetVariable -VariableName "AWS_PROFILE" -VariableValue $profileName
    #Aws-SetVariable -VariableName "AWS_ACCESS_KEY_ID" -VariableValue $json.AccessKeyId
    #Aws-SetVariable -VariableName "AWS_SECRET_ACCESS_KEY" -VariableValue $json.SecretAccessKey
    #Aws-SetVariable -VariableName "AWS_SESSION_TOKEN" -VariableValue $json.SessionToken
    #Aws-SetVariable -VariableName "AWS_SESSION_TOKEN_EXPIRATION" -VariableValue $json.Expiration
}

function Aws-Login {
    param (
        [string] $profileName = $null
    )

    Aws-ClearVariables

    $profileName = Aws-SelectProfile $profileName
    if ([string]::IsNullOrWhiteSpace($profileName)) {
        Write-Host "❌ Operation cancelled by user." -ForegroundColor Yellow
        Return
    }

    aws sso login --profile $profileName

    $isAuthenticated = Aws-IsAuthenticated -profileName $profileName
    if ($isAuthenticated -eq $true) {
        Aws-SetVariable -VariableName "AWS_PROFILE" -VariableValue $profileName
        #Aws-ExportVariables -profileName $profileName
        Write-Host "✅ Authenticated using profile " -NoNewLine
        Write-Host "$profileName" -ForegroundColor Cyan
    }
    else {
        Write-Host "❌ AWS Profile $($profileName) has not been properly authenticated.  Maybe check ~/.aws/config?" -ForegroundColor Red
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

function Aws-Logout {
    param (
        [string] $profileName = $env:AWS_PROFILE
    )

    if (-not $profileName) {
        Write-Host "❌ No AWS profile is currently set via AWS_PROFILE." -ForegroundColor Yellow
        return
    }

    Write-Host "Logging out AWS profile " -NoNewLine
    Write-Host "$profileName" -ForegroundColor Cyan

    # Clear environment variables
    Aws-ClearVariables

    # Attempt to clear cached SSO session files
    $cacheDir = Join-Path $HOME ".aws\cli\cache"
    if (Test-Path $cacheDir) {
        $files = Get-ChildItem $cacheDir | Where-Object {
            (Get-Content $_.FullName -Raw) -match $profileName
        }
        foreach ($file in $files) {
            Write-Host "Removing cached session: $($file.Name)"
            Remove-Item $file.FullName -Force
        }
    }

    Write-Host "✅ AWS logout complete"
}

function Aws-CheckToken {
    try {
        $response = aws sts get-caller-identity --output json | ConvertFrom-Json

        Write-Host "✅ Authenticated to AWS:"
        Write-Host "  Account : $($response.Account)"
        Write-Host "  UserId  : $($response.UserId)"
        Write-Host "  ARN     : $($response.Arn)"
        return $true
    }
    catch {
        if ($_.Exception.Message -like "*ExpiredToken*") {
            Write-Host "❌ AWS credentials have expired." -ForegroundColor Red
        }
        else {
            Write-Host "❌ AWS authentication failed." -ForegroundColor Red
        }
        Write-Host $_.Exception.Message
        return $false
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
Export-ModuleMember -Function Aws-ClearVariables
Export-ModuleMember -Function Aws-ExportVariables
Export-ModuleMember -Function Aws-Login
Export-ModuleMember -Function Aws-Logout
Export-ModuleMember -Function Aws-IsAuthenticated
Export-ModuleMember -Function Aws-CheckToken
Export-ModuleMember -Function Aws-LocalStack

Export-ModuleMember -Alias awslocal