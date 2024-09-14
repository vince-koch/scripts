Try-Import-Module $PSScriptRoot\Ansi.psm1
Try-Import-Module $PSScriptRoot\Colors.psm1
Try-Import-Module $PSScriptRoot\NerdFont.psm1

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

class PromptSegment {
    [string] $color
    [string] $icon
    [string] $text

    PromptSegment() {
        $this.color = ""
        $this.icon = ""
        $this.text = ""
    }

    PromptSegment([string] $color, [string] $icon, [string] $text) {
        $this.color = $color
        $this.icon = $icon
        $this.text = $text
    }

    [boolean] HasColor() {
        return $this.color -ne $null -and $this.color.Length -gt 0
    }

    [boolean] HasIcon() {
        return $this.icon -ne $null -and $this.icon.Length -gt 0
    }

    [boolean] HasText() {
        return $this.text -ne $null -and $this.text.Length -gt 0
    }

    [boolean] HasContent() {
        return $this.HasIcon() -or $this.HasText()
    }

    [string] ToString() {
        [string] $pre = if ($this.HasColor()) { "$($this.color)" } else { "" }
        [string] $ico = if ($this.HasIcon()) { "$($this.icon)" } else { "" }
        [string] $space = if ($this.HasIcon() -and $this.HasText()) { " " } else { "" }
        [string] $txt = if ($this.HasText()) { "$($this.text)" } else { "" }
        [string] $post = if ($this.HasColor()) { "$([PromptSegment]::Ansi.Reset)" } else { "" }

        [string] $result = "$($pre)$($ico)$($space)$($txt)$($post)"
        return $result
    }

    [void] Render() {
        Write-Host "$($this.ToString())" -NoNewLine
    }

    [int] GetRenderLength() {
        [int] $ico = if ($this.HasIcon()) { 1 } else { 0 }
        [int] $space = if ($this.HasIcon() -and $this.HasText()) { 1 } else { 0 }
        [int] $txt = if ($this.HasText()) { "$($this.text)".Length } else { 0 }

        [int] $result = $ico + $space + $txt
        return $result
    }

    static $Ansi

    static PromptSegment() {
        [PromptSegment]::Ansi = Get-Ansi
    }

    static [PromptSegment] Empty() {
        return [PromptSegment]::new()
    }

    static [PromptSegment] Space() {
        return [PromptSegment]::new("", "", " ")
    }

    static [PromptSegment] Icon([string] $color, [string] $icon) {
        return [PromptSegment]::new($color, $icon, "")
    }
    
    static [PromptSegment] Text([string] $color, [string] $text) {
        return [PromptSegment]::new($color, "", $text)
    }

    static [PromptSegment] LastCommand([string] $successColor, [string] $failColor, [string] $icon) {
        #$lastCommandSuccess = $LastExitCode -eq 0
        $lastCommandSuccess = $?
        $lastCommand = Get-History -Count 1
        $lastCommandRunTime = [TimeSpanUtils]::ToHumanShort($lastCommand.EndExecutionTime - $lastCommand.StartExecutionTime)

        if ("$lastCommandRunTime".Length -eq 0) {
            return [PromptSegment]::Empty()
        }

        [PromptSegment] $segment = [PromptSegment]::new()
        $segment.color = if ($lastCommandSuccess) { $successColor } else { $failColor }
        $segment.icon = $icon
        $segment.text = $lastCommandRunTime

        return $segment
    }

    static [PromptSegment] CurrentTime([string] $color, [string] $icon) {
        [PromptSegment] $segment = [PromptSegment]::new()
        $segment.color = $color
        $segment.icon = $icon
        $segment.text = Get-Date -Format "hh:mm:ss tt"
        #$segment.text = Get-Date -Format "dddd hh:mm:ss tt"

        return $segment
    }

    static [PromptSegment] IsAdmin([string] $color, [string] $icon) {
        # admin indicator
        $isAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
        if ($isAdmin) {
            [PromptSegment] $segment = [PromptSegment]::new()
            $segment.color = $color
            $segment.icon = $icon
            $segment.text = " ADMIN "

            return $segment
        }

        return [PromptSegment]::Empty()
    }

    static [PromptSegment] ComputerName([string] $color, [string] $icon)
    {
        [PromptSegment] $segment = [PromptSegment]::new()
        $segment.color = $color
        $segment.icon = $icon
        $segment.text = $env:COMPUTERNAME

        return $segment
    }

    static [PromptSegment] UserName([string] $color, [string] $icon)
    {
        $computerName = $env:COMPUTERNAME
        $userName = [Security.Principal.WindowsIdentity]::GetCurrent().Name;
        if ($userName.StartsWith($computerName)) {
            $userName = $userName.SubString($computerName.Length + 1)
        }

        [PromptSegment] $segment = [PromptSegment]::new()
        $segment.color = $color
        $segment.icon = $icon
        $segment.text = $userName

        return $segment
    }

    static [PromptSegment] CurrentFolder([string] $color, [string] $icon)
    {
        [PromptSegment] $segment = [PromptSegment]::new()
        $segment.color = $color
        $segment.icon = $icon
        $segment.text = $pwd

        return $segment
    }

    static [PromptSegment] GitBranch([string] $normalColor, [string] $warningColor, [string] $errorColor, [string] $icon)
    {
        [PromptSegment] $segment = [PromptSegment]::Empty()

        try {
            $branch = git rev-parse --abbrev-ref HEAD

            if ($branch -eq "HEAD") {
                # we're probably in detached HEAD state, so print the SHA
                $segment.color = $errorColor
                $segment.icon = $icon
                $segment.text = git rev-parse --short HEAD
            }
            elseif ($branch) {
                # we're on an actual branch, so print it
                $segment.color = $normalColor
                $segment.icon = $icon
                $segment.text = $branch
            }
        }
        catch {
            if ("$error".StartsWith("The term 'git' is not recognized")) {
                # we don't have git - or it's not on path
                $segment.color = $errorColor
                $segment.icon = $icon
                $segment.text = "git not found!"
            }
            else {
                # we'll end up here if we're in a newly initiated git repo
                $segment.color = $warningColor
                $segment.icon = $icon
                $segment.text = "no branches yet"
            }
        }

        return $segment
    }
}

function Prompt-MultiLine {
    $ansi = Get-Ansi
    $colors = Get-Colors
    $nerdfont = Get-NerdFont

    Write-Host ""

    $lastCommand = [PromptSegment]::LastCommand($ansi.fg.color($colors.Dracula.Green), $ansi.fg.color($colors.Dracula.Red), $nerdfont.nf_oct_stopwatch)
    if ($lastCommand.HasContent()) {
        $lastCommand.Render()
        [PromptSegment]::Space().Render()
    }

    [PromptSegment]::CurrentTime($ansi.fg.color($colors.Dracula.Comment), $nerdfont.nf_fa_clock_o).Render()
    [PromptSegment]::Space().Render()
    [PromptSegment]::ComputerName($ansi.fg.color($colors.Dracula.Purple), $nerdfont.nf_fa_windows).Render()
    [PromptSegment]::Space().Render()
    [PromptSegment]::UserName($ansi.fg.color($colors.Dracula.Pink), $nerdfont.nf_fa_user).Render()

    Write-Host ""
    
    $admin = [PromptSegment]::IsAdmin($ansi.bg.color($colors.Dracula.Red), $nerdfont.nf_fa_shield)
    if ($admin.HasContent())
    {
        $admin.Render()
        [PromptSegment]::Space().Render()
    }
    
    [PromptSegment]::CurrentFolder($ansi.fg.color($colors.Dracula.Cyan), $nerdfont.nf_fa_folder_open).Render()

    $gitBranch = [PromptSegment]::GitBranch($ansi.fg.color($colors.Dracula.Orange), $ansi.fg.color($colors.Dracula.Yellow), $ansi.fg.color($colors.Dracula.Red), $nerdfont.nf_dev_git_branch)
    if ($gitBranch.HasContent())
    {
        [PromptSegment]::Space().Render()
        $gitBranch.Render()
    }
   
    Write-Host ""
    [PromptSegment]::Icon($ansi.fg.color($colors.Dracula.Red), $nerdfont.nf_fa_bolt).Render()
    return " "
}

function Prompt-SingleLine {
    $ansi = Get-Ansi
    $colors = Get-Colors
    $nerdfont = Get-NerdFont

    Console-WriteHR -ForegroundColor DarkGray

    $admin = [PromptSegment]::IsAdmin($ansi.bg.color($colors.Dracula.Red), $nerdfont.nf_fa_shield)
    if ($admin.HasContent())
    {
        $admin.Render()
        [PromptSegment]::Space().Render()
    }

    [PromptSegment]::ComputerName($ansi.fg.magenta, $nerdfont.nf_custom_windows).Render()
    [PromptSegment]::Space().Render()
    [PromptSegment]::UserName($ansi.fg.brightmagenta, $nerdfont.nf_fa_user).Render()
    [PromptSegment]::Space().Render()
    [PromptSegment]::CurrentFolder($ansi.fg.cyan, $nerdfont.nf_fa_folder_open).Render()

    $gitBranch = [PromptSegment]::GitBranch($ansi.fg.color($colors.Dracula.Orange), $ansi.fg.color($colors.Dracula.Yellow), $ansi.fg.color($colors.Dracula.Red), $nerdfont.nf_dev_git_branch)
    if ($gitBranch.HasContent())
    {
        [PromptSegment]::Space().Render()
        $gitBranch.Render()
    }

    $lastCommand = [PromptSegment]::LastCommand($ansi.fg.green, $ansi.fg.red, $nerdfont.nf_oct_watch)
    $currentTime = [PromptSegment]::CurrentTime($ansi.fg.brightblack, $nerdfont.nf_oct_clock)

    $renderLength = if ($lastCommand.HasContent()) { $lastCommand.GetRenderLength() + 1 } else { 0 }
    $renderLength += $currentTime.GetRenderLength()

    $x = $Host.UI.RawUI.WindowSize.Width - ($renderLength + 1)
    $y = $Host.UI.RawUI.CursorPosition.Y
    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates ($x - 1), $y
  
    if ($lastCommand.HasContent()) {
        $lastCommand.Render()
        [PromptSegment]::Space().Render()
    }

    $currentTime.Render()

    Write-Host ""
    [PromptSegment]::Icon($ansi.fg.red, $nerdfont.nf_fa_bolt).Render()
    return " "
}

function Global:Prompt {
	#return Prompt-SingleLine
    return Prompt-MultiLine
}