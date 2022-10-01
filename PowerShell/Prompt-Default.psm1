# USAGE
# Import-Module $PSScriptRoot\Prompt-Default.psm1 -DisableNameChecking -Force

class TimeSpanUtils {
    static [string] ToHumanLong([TimeSpan] $timeSpan) {
        [string] $result = ""
        if ($timeSpan.Days -gt 0) { $result = "$result $(Floor($timeSpan.TotalDays))d" }
        if ($timeSpan.Hours -gt 0) { $result = "$result $($timeSpan.Hours)h" }
        if ($timeSpan.Minutes -gt 0) { $result = "$result $($timeSpan.Minutes)m" }
        if ($timeSpan.Seconds -gt 0) { $result = "$result $($timeSpan.Seconds)s" }
        if ($timeSpan.Milliseconds -gt 0) { $result = "$result $($timeSpan.Milliseconds)ms" }
        return $result.Trim()
    }

    static [string] ToHumanShort([TimeSpan] $timeSpan) {
        if ($timeSpan.Days -gt 0) { return "$(Floor($timeSpan.TotalDays.ToString("0.###"))) d" }
        elseif ($timeSpan.Hours -gt 0) { return "$($timeSpan.TotalHours.ToString("0.###")) h" }
        elseif ($timeSpan.Minutes -gt 0) { return "$($timeSpan.TotalMinutes.ToString("0.###")) m" }
        elseif ($timeSpan.Seconds -gt 0) { return "$($timeSpan.TotalSeconds.ToString("0.###")) s" }
        else { return "$($timeSpan.TotalMilliseconds.ToString("0.###")) ms" }
    }
}

function Write-GitBranchName([string] $GLYPH_GIT_BRANCH) {
    try {
        $branch = git rev-parse --abbrev-ref HEAD

        if ($branch -eq "HEAD") {
            # we're probably in detached HEAD state, so print the SHA
            $branch = git rev-parse --short HEAD
            Write-Host " ($GLYPH_GIT_BRANCH$branch)" -ForegroundColor Red -NoNewLine
        }
        elseif ($branch) {
            # we're on an actual branch, so print it
            Write-Host " ($GLYPH_GIT_BRANCH$branch)" -ForegroundColor Blue -NoNewLine
        }
    }
    catch {
        if ("$error".StartsWith("The term 'git' is not recognized")) {
            # we don't have git - or it's not on path
            Write-Host " ($GLYPH_GIT_BRANCHgit not found!)" -ForegroundColor Red -NoNewLine
        }
        else {
            # we'll end up here if we're in a newly initiated git repo
            Write-Host " ($GLYPH_GIT_BRANCHno branches yet)" -ForegroundColor Yellow -NoNewLine
        }
    }
}

function Prompt-Default {
    # https://gitlab.com/jake.gillberg/nerd-fonts-glyph-list/-/raw/master/glyph-list.txt
    # https://www.nerdfonts.com/cheat-sheet
    $nf_fa_shield        = "$([char]0xf132)"
    $nf_fa_user          = "$([char]0xf007)"
    $nf_mdi_laptop       = "$([char]0xf821)"
    $nf_fa_folder_open   = "$([char]0xf07c)"
    $nf_dev_git_branch   = "$([char]0xe725)"
    $nf_oct_watch        = "$([char]0xf49b)"
    $nf_mdi_clock        = "$([char]0xf64f)"
    $nf_custom_windows   = "$([char]0xe62a)"
    $nf_fa_arrow_right   = "$([char]0xf061)"

    $GLYPH_SHIELD        = $nf_fa_shield
    $GLYPH_USER          = $nf_fa_user
    $GLYPH_COMPUTER      = $nf_mdi_laptop
    $GLYPH_FOLDER_OPEN   = $nf_fa_folder_open
    $GLYPH_GIT_BRANCH    = $nf_dev_git_branch
    $GLYPH_TIMER         = $nf_oct_watch
    $GLYPH_CLOCK         = $nf_mdi_clock
    $GLYPH_WINDOWS       = $nf_custom_windows
    $GLYPH_PROMPT        = $nf_fa_arrow_right

	$hr = "_" * $Host.UI.RawUI.WindowSize.Width
    Write-Host "$hr" -ForegroundColor DarkGray

    # admin indicator
    $isAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    if ($isAdmin) {
        $admin = "$GLYPH_SHIELD ADMIN "
        Write-Host $admin -ForegroundColor Red -NoNewline
    }

    # username, computer name, current folder, and git branch
    $userName = [Security.Principal.WindowsIdentity]::GetCurrent().Name;
    $userName = "$GLYPH_USER $userName"
    Write-Host $userName -ForegroundColor Magenta -NoNewLine

    # computer name
    $computerName = $env:COMPUTERNAME
    $computerName = "$GLYPH_WINDOWS $computerName"
    Write-Host " $computerName" -ForegroundColor DarkGray -NoNewLine

    # current folder
    #$folder = Split-Path -Path $pwd -Leaf
    $folder = $pwd
    $folder = "$GLYPH_FOLDER_OPEN $folder"
    Write-Host " $folder" -ForegroundColor Yellow -NoNewLine

    # git branch
    Write-GitBranchName "$GLYPH_GIT_BRANCH "

    # duration of last command, and color indication of whether or not it failed
    $lastCommandSuccess = $?
    $lastCommand = Get-History -Count 1
    $lastCommandRunTime = [TimeSpanUtils]::ToHumanShort($lastCommand.EndExecutionTime - $lastCommand.StartExecutionTime)
    $lastCommandRunTime = "$GLYPH_TIMER $lastCommandRunTime"
    if ("$lastCommandRunTime".Length -gt 0) {
        $x = $Host.UI.RawUI.WindowSize.Width - ("$lastCommandRunTime".Length + 13 + 1)
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
    $timestamp = Get-Date -Format "dddd hh:mm:ss tt"
    $time = Get-Date -Format "hh:mm:ss tt"
    $time = "$GLYPH_CLOCK $time"
    $x = $Host.UI.RawUI.WindowSize.Width - "$time".Length
    $y = $Host.UI.RawUI.CursorPosition.Y
    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $x, $y
    Write-Host "$time" -ForegroundColor DarkGray -NoNewLine

    # prompt
    Write-Host ""
    #Write-Host "PS>" -ForegroundColor Cyan -NoNewLine
    Write-Host "$GLYPH_PROMPT" -ForegroundColor Cyan -NoNewLine
    return " "
}

Export-ModuleMember -Function Prompt-Default