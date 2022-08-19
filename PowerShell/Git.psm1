# USAGE
# Import-Module $PSScriptRoot\Git.psm1 -DisableNameChecking -Force

Import-Module $PSScriptRoot\Console.psm1 -DisableNameChecking -Force

function Git-CreateBranch {
    param (
        [Parameter(Mandatory=$true)]
        [string] $branchName,

        [Parameter(Mandatory=$true)]
        [string] $sourceBranch
    )

    $ErrorActionPreference = "Stop"

    git remote update
    if ($LastExitCode -ne 0) {
        exit
    }

    git checkout $sourceBranch
    if ($LastExitCode -ne 0) {
        exit
    }

    git pull
    if ($LastExitCode -ne 0) {
        exit
    }

    git checkout -b $branchName
    if ($LastExitCode -ne 0) {
        exit
    }
}

function Git-ChangeBranch {
    # get a list of branches
    [array] $branches = @( git branch )
    if ($branches.Length -eq 0) {
        return
    }

    [int] $currentIndex = [Array]::FindIndex($branches, [Predicate[String]] { param($s) $s.StartsWith("*") })
    $branches = $branches | ForEach-Object { $_.Trim(" *") }

    $selectedIndex = Console-Menu $branches -Index $currentIndex -ReturnIndex
    if ($selectedIndex -gt -1 -and $selectedIndex -ne $currentIndex) {
        git checkout $branches[$selectedIndex]
    }
}

Export-ModuleMember -Function Git-CreateBranch
Export-ModuleMember -Function Git-ChangeBranch