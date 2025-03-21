Try-Import-Module $PSScriptRoot\Console.psm1

function Aws-ListProfiles {
    aws configure list-profiles
}

function Aws-SetProfile {
    param (
        [string] $profile = $null
    )
    
    if ([string]::IsNullOrWhiteSpace($profile)) {
        $profiles = & aws configure list-profiles | ForEach-Object { $_ }
        
        $profile = Console-Menu -Items $profiles -IgnoreEscape
    }
    
    [Environment]::SetEnvironmentVariable("AWS_PROFILE", $profile)
    [Environment]::SetEnvironmentVariable("AWS_PROFILE", $profile, "User")
    $Env:AWS_PROFILE = $profile
}

function Aws-UnSetProfile {
    Remove-Item Env:AWS_PROFILE
}

function Aws-Login {
    <#
    $profile = $Env:AWS_PROFILE
    
    if ([string]::IsNullOrWhiteSpace($profile)) {
        Aws-SetProfile
    }
    #>
    Aws-SetProfile
    
    aws sso login --profile $Env:AWS_PROFILE
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
Export-ModuleMember -Function Aws-SetProfile
Export-ModuleMember -Function Aws-UnSetProfile
Export-ModuleMember -Function Aws-Login
Export-ModuleMember -Function Aws-LocalStack

Export-ModuleMember -Alias awslocal