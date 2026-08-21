# USAGE
# Import-Module $PSScriptRoot\Git.psm1 -DisableNameChecking -Force

function Git-Zip {
    <#
    .SYNOPSIS
        Creates a configurable ZIP snapshot of the current Git repository.
    .DESCRIPTION
        Uses a checkbox menu by default. Tracked working-tree files and untracked,
        non-ignored files are streamed directly into the ZIP without staging copies.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$OutputFile,

        [switch]$IncludeChanges,

        [switch]$IncludeUntracked,

        [switch]$NoPrompt
    )

    $repositoryRoot = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $repositoryRoot) {
        throw 'The current directory is not inside a Git repository.'
    }
    $repositoryRoot = [System.IO.Path]::GetFullPath([string]$repositoryRoot)

    if (-not $NoPrompt -and
        -not $PSBoundParameters.ContainsKey('IncludeChanges') -and
        -not $PSBoundParameters.ContainsKey('IncludeUntracked')) {
        Import-Module PwshSpectreConsole -ErrorAction Stop
        $options = @(
            'Include uncommitted changes'
            'Include untracked files'
        )
        [string[]]$selectedOptions = @(
            Read-SpectreMultiSelection `
                -Message 'Select ZIP contents' `
                -Choices $options `
                -Color 'Cyan1'
        )
        $IncludeChanges = 'Include uncommitted changes' -in $selectedOptions
        $IncludeUntracked = 'Include untracked files' -in $selectedOptions
    }

    if (-not $OutputFile) {
        $OutputFile = "$(Split-Path -Leaf $repositoryRoot).zip"
    }
    if (-not [System.IO.Path]::IsPathRooted($OutputFile)) {
        $OutputFile = Join-Path (Get-Location) $OutputFile
    }
    $OutputFile = [System.IO.Path]::GetFullPath($OutputFile)

    if ([System.IO.File]::Exists($OutputFile)) {
        throw "Output file already exists: $OutputFile"
    }
    $outputDirectory = Split-Path $OutputFile -Parent
    if (-not [System.IO.Directory]::Exists($outputDirectory)) {
        throw "Output directory does not exist: $outputDirectory"
    }

    $addFiles = {
        param(
            [System.IO.Compression.ZipArchive]$Archive,
            [string[]]$Paths
        )

        foreach ($relativePath in $Paths) {
            $sourcePath = Join-Path $repositoryRoot $relativePath
            if (-not [System.IO.File]::Exists($sourcePath)) { continue }
            if ([System.IO.Path]::GetFullPath($sourcePath) -eq $OutputFile) { continue }

            $entryName = $relativePath.Replace('\', '/')
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $Archive,
                $sourcePath,
                $entryName,
                [System.IO.Compression.CompressionLevel]::Optimal
            ) | Out-Null
        }
    }

    try {
        if ($IncludeChanges) {
            [string[]]$trackedFiles = @(git -C $repositoryRoot ls-files --cached)
            $stream = [System.IO.File]::Open($OutputFile, [System.IO.FileMode]::CreateNew)
            try {
                $archive = [System.IO.Compression.ZipArchive]::new(
                    $stream,
                    [System.IO.Compression.ZipArchiveMode]::Create,
                    $false
                )
                try { & $addFiles $archive $trackedFiles }
                finally { $archive.Dispose() }
            }
            finally { $stream.Dispose() }
        }
        else {
            git -C $repositoryRoot archive --format=zip --output=$OutputFile HEAD
            if ($LASTEXITCODE -ne 0) { throw 'git archive failed.' }
        }

        if ($IncludeUntracked) {
            [string[]]$untrackedFiles = @(git -C $repositoryRoot ls-files --others --exclude-standard)
            $stream = [System.IO.File]::Open($OutputFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)
            try {
                $archive = [System.IO.Compression.ZipArchive]::new(
                    $stream,
                    [System.IO.Compression.ZipArchiveMode]::Update,
                    $false
                )
                try { & $addFiles $archive $untrackedFiles }
                finally { $archive.Dispose() }
            }
            finally { $stream.Dispose() }
        }
    }
    catch {
        if ([System.IO.File]::Exists($OutputFile)) {
            [System.IO.File]::Delete($OutputFile)
        }
        throw
    }

    Write-Host 'Created ' -NoNewline
    Write-Host $OutputFile -ForegroundColor Cyan
}

function Git-ChangeBranch {
    Import-Module PwshSpectreConsole -ErrorAction Stop

    # get a list of branches
    [array] $branches = @( git branch )
    if ($branches.Length -eq 0) {
        Write-Host "No git branches found?" -ForegroundColor Red
        return
    }

    [int] $currentIndex = [Array]::FindIndex($branches, [Predicate[String]] { param($s) $s.StartsWith("*") })
    $branches = $branches | ForEach-Object { $_.Trim(" *") }

    $selectedBranch = Read-SpectreSelection `
        -Message 'Select a Git branch' `
        -Choices $branches `
        -EnableSearch `
        -Color 'Cyan1'

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

function Git-DeleteBranches {
    Import-Module PwshSpectreConsole -ErrorAction Stop

    # get a list of branches
    [array] $branches = @( git branch )
    if ($branches.Length -eq 0) {
        Write-Host "No git branches found?" -ForegroundColor Red
        return
    }

    $branches = $branches | ForEach-Object { $_.Trim(" *") }

    [string[]] $selectedBranches = @(
        Read-SpectreMultiSelection `
            -Message 'Select local branches to delete' `
            -Choices $branches `
            -PageSize 20 `
            -Color 'Cyan1'
    )

    if ($selectedBranches.Length -eq 0) {
        Write-Host "No branches selected" -ForegroundColor Red
        return
    }

    $confirm = Read-SpectreConfirm `
        -Message "Delete $($selectedBranches.Length) local branches?" `
        -DefaultAnswer 'n'
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

function Git-UpdateCheck {
    git remote update | Out-Null
    
    [array] $lines = @( git status )

    # foreach ($line in $lines) {
    #     Write-Host "line: $line"
    # }

    if ($lines -match "Your branch is up to date with") {
        # Write-Host "CURRENT" -ForegroundColor Green
        return 0
    }
    
    if ($lines -match "Your branch is behind") {
        # Write-Host "UPDATE AVAILABLE" -ForegroundColor Red
        # if ($confirm) {
        #      git pull
        # }
        return -1
    }

    #if ($lines -match "Your branch is ahead") {
    #    Write-Host "AHEAD" -ForegroundColor Yellow
        return 1
    #}
}

Export-ModuleMember -Function Git-Zip

Export-ModuleMember -Function Git-ChangeBranch
Set-Alias -Name git-change-branch -Value Git-ChangeBranch

Set-Alias -Name git-create-branch -Value Git-CreateBranch
Export-ModuleMember -Function Git-CreateBranch -Alias git-create-branch

Set-Alias -Name git-delete-branch -Value Git-DeleteBranches
Set-Alias -Name git-delete-branches -Value Git-DeleteBranches
Export-ModuleMember -Function Git-DeleteBranches -Alias git-delete-branch, git-delete-branches

Export-ModuleMember -Function Git-GetBranchName
Export-ModuleMember -Function Git-GetCommitDate

Set-Alias -Name git-update-check -Value Git-UpdateCheck
Set-Alias -Name git-check-update -Value Git-UpdateCheck
Set-Alias -Name git-check-for-update -Value Git-UpdateCheck
Set-Alias -Name git-check-for-updates -Value Git-UpdateCheck
Export-ModuleMember -Function Git-UpdateCheck -Alias git-update-check, git-check-update, git-check-for-update, git-check-for-updates

Export-ModuleMember -Alias git-change-branch
