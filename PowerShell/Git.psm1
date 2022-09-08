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

    [string[]] $selectedBranches = Console-Menu $branches -MultiSelect

    if ($selectedBranches.Length -eq 0) {
        Write-Host "No branches selected" -ForegroundColor Red
        return
    }

    $confirm = Console-Confirm -Prompt "Are you sure you want to delete $($selectedBranches.Length) branches [y/N]? " -Default $false
    if ($confirm -ne $true) {
        Write-Host "User cancelled" -ForegroundColor Red
        return
    }

    foreach ($selectedBranch in $selectedBranches) {
        git branch -D "$selectedBranch"
    }
}

Set-Alias -Name git-create-branch -Value Git-CreateBranch
Set-Alias -Name git-change-branch -Value Git-ChangeBranch
Set-Alias -Name git-delete-branch -Value Git-DeleteBranches
Set-Alias -Name git-delete-branches -Value Git-DeleteBranches

Export-ModuleMember -Function Git-CreateBranch -Alias git-create-branch
Export-ModuleMember -Function Git-ChangeBranch -Alias git-change-branch
Export-ModuleMember -Function Git-DeleteBranches -Alias git-delete-branch, git-delete-branches