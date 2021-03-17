# Installation
# ------------
# 1. Run the following command to see where to place this file: $profile
# 2. Customize if desired
#
# Helpful Links
# -------------
# Basis for git prompt: https://stackoverflow.com/questions/1287718/how-can-i-display-my-current-git-branch-name-in-my-powershell-prompt
# Explaining profiles: https://devblogs.microsoft.com/scripting/understanding-the-six-powershell-profiles/

function Write-BranchName () {
    try {
        $branch = git rev-parse --abbrev-ref HEAD

        if ($branch -eq "HEAD") {
            # we're probably in detached HEAD state, so print the SHA
            $branch = git rev-parse --short HEAD
            Write-Host "[$branch] " -ForegroundColor Red -NoNewLine
        }
        else {
            # we're on an actual branch, so print it
            Write-Host "[$branch] " -ForegroundColor Blue -NoNewLine
        }
    }
    catch {
        # we'll end up here if we're in a newly initiated git repo
        Write-Host "[*new-repo*] " -ForegroundColor Yellow -NoNewLine
    }
}

function Get-TruncatedPath {
    $dirSep = [IO.Path]::DirectorySeparatorChar
    $pathComponents = $PWD.Path.Split($dirSep)
    $displayPath = if ($pathComponents.Count -le 3) {
        $PWD.Path
    } else {
        "...{0}{1}" -f $dirSep, ($pathComponents[-2,-1] -join $dirSep)
    }

    return $displayPath
}

function Prompt {
    $base = "PS "
    #$path = "$($executionContext.SessionState.Path.CurrentLocation)"
    $path = Get-TruncatedPath

    Write-Host "`n$base" -NoNewline

    if (Test-Path .git) {
        Write-BranchName
        Write-Host $path -NoNewLine        
    }
    else {
        # we're not in a repo so don't bother displaying branch name/sha
        Write-Host "$path" -NoNewLine
    }

    return "> "
}