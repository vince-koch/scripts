param (
    [string] $verb = ""
)

if ($verb -eq "install") {
    # .\Profile.ps1 install ==> installs this file as the current user's $profile
    Write-Host "$($PSCommandPath) ==> $($profile)"
    Copy-Item -Path "$($PSCommandPath)" -Destination "$($profile)" -Force
}
elseif ($verb -eq "view") {
    # .\Profile.ps1 view ==> opens this file in notepad.exe
    [Profile]::View()
}

class Profile {
    static [void] Reload() {
        $profilePath = [Profile]::GetProfilePath()
        & $profilePath
        Write-Host "Profile reloaded"
    }

    static [void] Update() {
        $updateUrl = "https://raw.githubusercontent.com/vince-koch/scripts/main/PowerShell/Profile.ps1"
        $profilePath = [Profile]::GetProfilePath()
        $profileDirectory = [System.IO.Path]::GetDirectoryName($profilePath)

        # ensure folder exists
        [System.IO.Directory]::CreateDirectory($profileDirectory)

        # download the file
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($updateUrl, $profilePath)

        # message
        Write-Host "Success! " -ForegroundColor Green -NoNewLine
        Write-Host "Your profile located at [" -NoNewLine
        Write-Host $profilePath -ForegroundColor Cyan
        Write-Host "] has been updated"

        [Profile]::Reload()
    }

    static [void] View() {
        $notepadPath = "$([Environment]::SystemDirectory)\notepad.exe"
        $profilePath = [Profile]::GetProfilePath()
        Start-Process $notepadPath $profilePath
    }

    static [string] GetProfilePath() {
        [string] $profile = [System.IO.Path]::Combine( `
            [Environment]::GetFolderPath("MyDocuments"), `
            "WindowsPowerShell", `
            "Microsoft.PowerShell_profile.ps1")

        return $profile
    }
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

function Indent-Tabs-To-Spaces([string] $path, [int] $spacesPerTab = 4) {
    [string] $indent = $(" " * $spacesPerTab)
    [string[]] $lines = [System.IO.File]::ReadAllLines($path)

    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        $trimmed = $line.TrimStart()
        $start = $line.SubString(0, $line.Length - $trimmed.Length).Replace("`t", $indent)
        $lines[$i] = $start + $trimmed
    }

    [System.IO.File]::WriteAllLines($path, $lines)
}

Set-Alias -Name t2s -Value Indent-Tabs-To-Spaces

function SheBang {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $filename,

        [Parameter(Mandatory=$True, Position = 1, ValueFromRemainingArguments=$true)]
        [string[]] $arguments
    )

    [string] $shebang = "#! "

    if ([System.IO.File]::Exists($filename) -eq $false) {
        Write-Host "File [$filename] does not exist" -ForegroundColor Red
        return 1
    }

    [string] $first = Get-Content $filename -First 1
    if ($first.StartsWith($shebang) -eq $false) {
        Write-Host "File [$filename] did not begin with the shebang sequence [$shebang]" -ForegroundColor Red
        return 1
    }

    [string] $command = $first.Substring($shebang.Length)
    if ([string]::IsNullOrWhiteSpace($command)) {
        Write-Host "File [$filename] began with the shebang sequence but did not contain an instruction" -ForegroundColor Red
        return 1
    }

    Write-Host $command $arguments  -ForegroundColor DarkGray
    $startProcessParams = @{
        FilePath               = $command
        ArgumentList           = $arguments
        Wait                   = $true;
        PassThru               = $true;
        NoNewWindow            = $true;
    }

    $cmd = Start-Process @startProcessParams
    return $cmd.ExitCode
}

Set-Alias -Name sb -Value SheBang

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
        if ($timeSpan.Days -gt 0) { return "$(Floor($timeSpan.TotalDays)) days" }
        elseif ($timeSpan.Hours -gt 0) { return "$($timeSpan.TotalHours) hours" }
        elseif ($timeSpan.Minutes -gt 0) { return "$($timeSpan.TotalMinutes) minutes" }
        elseif ($timeSpan.Seconds -gt 0) { return "$($timeSpan.TotalSeconds) seconds" }
        else { return "$($timeSpan.TotalMilliseconds) ms" }
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

function Global:Prompt {
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

    Write-Host ""

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
