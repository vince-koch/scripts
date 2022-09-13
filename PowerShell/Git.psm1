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
        Write-Host "No git branches found?" -ForegroundColor Red
        return
    }

    [int] $currentIndex = [Array]::FindIndex($branches, [Predicate[String]] { param($s) $s.StartsWith("*") })
    $branches = $branches | ForEach-Object { $_.Trim(" *") }

    $menu = Console-CreateMenu
    $menu.Items = $branches
    $menu.CurrentIndex = $currentIndex
    $menu.TitleColor = [System.ConsoleColor]::Red
    $selectedBranch = $menu.Run()

    if ($selectedBranch -eq $null) {
        Write-Host "User cancelled" -ForegroundColor Red
        return
    }
    elseif ($selectedBranch -eq $branches[$currentIndex]) {
        Write-Host "Already on selected branch" -ForegroundColor Red
        return
    }
    else {
        git checkout $selectedBranch
    }
}

function Git-DeleteBranches {
    # get a list of branches
    [array] $branches = @( git branch )
    if ($branches.Length -eq 0) {
        Write-Host "No git branches found?" -ForegroundColor Red
        return
    }

    $branches = $branches | ForEach-Object { $_.Trim(" *") }

    [string[]] $selectedBranches = Console-Menu -Items $branches -IsMultiSelect

    if ($selectedBranches.Length -eq 0) {
        Write-Host "No branches selected" -ForegroundColor Red
        return
    }

    $confirm = Console-Confirm -Prompt "Are you sure you want to delete $($selectedBranches.Length) branches locally [y/N]? " -Default $false
    if ($confirm -ne $true) {
        Write-Host "User cancelled" -ForegroundColor Red
        return
    }

    foreach ($selectedBranch in $selectedBranches) {
        git branch -D "$selectedBranch"
    }
}

function Git-GetBranchName {
    try {
        $branch = git rev-parse --abbrev-ref HEAD
        if ($branch -eq "HEAD") {
            $branch = git rev-parse --short HEAD
        }

        if ($branch) {
            return $branch
        }
    }
    catch {
        if ("$error".StartsWith("The term 'git' is not recognized")) {
            throw "Please ensure git can be found on your PATH"
        }
    }

    return $null
}

function Git-GetCommitDate() {
    if (Git-GetBranchName) {
        $commitDate = git show -s --format=%ci
        return $commitDate
    }

    return $null
}

Set-Alias -Name git-create-branch -Value Git-CreateBranch
Set-Alias -Name git-change-branch -Value Git-ChangeBranch
Set-Alias -Name git-delete-branch -Value Git-DeleteBranches
Set-Alias -Name git-delete-branches -Value Git-DeleteBranches

Export-ModuleMember -Function Git-CreateBranch -Alias git-create-branch
Export-ModuleMember -Function Git-ChangeBranch -Alias git-change-branch
Export-ModuleMember -Function Git-DeleteBranches -Alias git-delete-branch, git-delete-branches
Export-ModuleMember -Function Git-GetBranchName
Export-ModuleMember -Function Git-GetCommitDate