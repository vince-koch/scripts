function Write-GitBranchName() {
    try {
        $branch = git rev-parse --abbrev-ref HEAD

        if ($branch -eq "HEAD") {
            # we're probably in detached HEAD state, so print the SHA
            $branch = git rev-parse --short HEAD
            Write-Host " ($branch)" -ForegroundColor Red -NoNewLine
        }
        elseif ($branch) {
            # we're on an actual branch, so print it
            Write-Host " ($branch)" -ForegroundColor Magenta -NoNewLine
        }
    }
    catch {
        if ("$error".StartsWith("The term 'git' is not recognized")) {
            # we don't have git - or it's not on path
            Write-Host " (git not found!)" -ForegroundColor Red -NoNewLine
        }
        else {
            # we'll end up here if we're in a newly initiated git repo
            Write-Host " (no branches yet)" -ForegroundColor Yellow -NoNewLine
        }
    }
}

function Global:Prompt {
    Write-Host ""
	Write-Host "PS " -ForegroundColor Blue -NoNewLine
	
    # admin indicator
    $isAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    if ($isAdmin) {
        $admin = "ADMIN "
        Write-Host $admin -ForegroundColor Red -NoNewline
    }

    # current folder
    #$folder = Split-Path -Path $pwd -Leaf
    $folder = $pwd
    Write-Host "$folder" -ForegroundColor Cyan -NoNewLine

    # git branch
    Write-GitBranchName

    # prompt
    Write-Host ">" -ForegroundColor Blue -NoNewLine
    
	# return
    return " "
}
