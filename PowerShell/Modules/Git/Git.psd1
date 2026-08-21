@{
    RootModule        = 'Git.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Git-Zip'
        'Git-ChangeBranch'
        'Git-CreateBranch'
        'Git-DeleteBranches'
        'Git-GetBranchName'
        'Git-GetCommitDate'
        'Git-UpdateCheck'
    )
    AliasesToExport = @(
        'git-change-branch'
        'git-create-branch'
        'git-delete-branch'
        'git-delete-branches'
        'git-update-check'
        'git-check-update'
        'git-check-for-update'
        'git-check-for-updates'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
}
