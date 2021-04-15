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