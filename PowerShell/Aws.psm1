if (-not (Get-Module -Name Console)) {
    Import-Module $PSScriptRoot\Console.psm1 -DisableNameChecking -Force
}

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
    
    $Env:AWS_PROFILE = $profile
}

function Aws-UnSetProfile {
    Remove-Item Env:AWS_PROFILE
}

function Aws-Login {
    $profile = $Env:AWS_PROFILE
    if ([string]::IsNullOrWhiteSpace($profile)) {
        Aws-SetProfile
    }
    
    aws sso login --profile $Env:AWS_PROFILE
}

Export-ModuleMember -Function Aws-ListProfiles
Export-ModuleMember -Function Aws-SetProfile
Export-ModuleMember -Function Aws-UnSetProfile
Export-ModuleMember -Function Aws-Login