param (
    [string] $verb = ""
)

# .\Profile.ps1 install ==> installs this file as the current user's $profile
if ($verb -eq "install") {
    Write-Host "$($PSCommandPath) ==> $($profile)"
    Copy-Item -Path "$($PSCommandPath)" -Destination "$($profile)"
}

# .\Profile.ps1 view ==> opens this file in notepad.exe
if ($verb -eq "view") {
    $notepadPath = "$([Environment]::SystemDirectory)\notepad.exe"
    $profilePath = "$($profile)"
    Start-Process $notepadPath $profilePath
}

function Write-Colors {
    Write-Host "Black" -ForegroundColor Black
    Write-Host "Blue" -ForegroundColor Blue
    Write-Host "Cyan" -ForegroundColor Cyan
    Write-Host "DarkBlue" -ForegroundColor DarkBlue
    Write-Host "DarkCyan" -ForegroundColor DarkCyan
    Write-Host "DarkGray" -ForegroundColor DarkGray
    Write-Host "DarkGreen" -ForegroundColor DarkGreen
    Write-Host "DarkMagenta" -ForegroundColor DarkMagenta
    Write-Host "DarkRed" -ForegroundColor DarkRed
    Write-Host "DarkYellow" -ForegroundColor DarkYellow
    Write-Host "Gray" -ForegroundColor Gray
    Write-Host "Green" -ForegroundColor Green
    Write-Host "Magenta" -ForegroundColor Magenta
    Write-Host "Red" -ForegroundColor Red
    Write-Host "White" -ForegroundColor White
    Write-Host "Yellow" -ForegroundColor Yellow
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

function Write-GitBranchName {
    try {
        $branch = git rev-parse --abbrev-ref HEAD

        if ($branch -eq "HEAD") {
            # we're probably in detached HEAD state, so print the SHA
            $branch = git rev-parse --short HEAD
            Write-Host " ($branch)" -ForegroundColor Red -NoNewLine
        }
        elseif ($branch) {
            # we're on an actual branch, so print it
            Write-Host " ($branch)" -ForegroundColor Blue -NoNewLine
        }
    }
	catch {
        # we'll end up here if we're in a newly initiated git repo
        Write-Host " (no branches yet)" -ForegroundColor Yellow -NoNewLine
    }
}

function Global:Prompt {
	$lastCommandSuccess = $?
    $lastCommand = Get-History -Count 1
    $lastCommandRunTime = ($lastCommand.EndExecutionTime - $lastCommand.StartExecutionTime).TotalSeconds
	
    $isAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    $userName = [Security.Principal.WindowsIdentity]::GetCurrent().Name;
    $computerName = $env:COMPUTERNAME
    $folder = Split-Path -Path $pwd -Leaf
    $timestamp = Get-Date -Format 'dddd hh:mm:ss tt'
	$time = Get-Date -Format 'hh:mm:ss tt'
	
    Write-Host ""

	# admin indicator
    if ($isAdmin) {
        Write-Host "Admin " -ForegroundColor Red -NoNewline
    }

	# username, computer name, current folder, and git branch
    Write-Host "$userName" -ForegroundColor Green -NoNewLine
    Write-Host " $computerName" -ForegroundColor DarkGray -NoNewLine
    Write-Host " $pwd" -ForegroundColor Yellow -NoNewLine
    Write-GitBranchName
	
	# duration of last command, and color indication of whether or not it failed
	if ("$lastCommandRunTime".Length -gt 0) {
		$x = $Host.UI.RawUI.WindowSize.Width - ("$lastCommandRunTime".Length + "$time".Length + 1)
		$y = $Host.UI.RawUI.CursorPosition.Y
		$Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $x, $y
		if ($lastCommandSuccess) {
			Write-Host $lastCommandRunTime -ForegroundColor DarkGreen -NoNewLine
		}
		else {
			Write-Host $lastCommandRunTime -ForegroundColor DarkRed -NoNewLine
		}
	}
	
	# current time
	$x = $Host.UI.RawUI.WindowSize.Width - "$time".Length
	$y = $Host.UI.RawUI.CursorPosition.Y
	$Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $x, $y	
	Write-Host $time -ForegroundColor DarkGray -NoNewLine
	
	# prompt
	Write-Host ""
	$rightArrow = [char]0x2192
	return "PS> "
}
