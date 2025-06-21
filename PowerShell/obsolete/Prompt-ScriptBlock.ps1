Try-Import-Module $PSScriptRoot\Ansi.psm1
Try-Import-Module $PSScriptRoot\Colors.psm1
Try-Import-Module $PSScriptRoot\Git.psm1

$Ansi.Bg | Add-Member -MemberType ScriptMethod -Name "Separator" -Force -Value {
    param (
        [System.Drawing.Color] $leftColor,
        [System.Drawing.Color] $rightColor,
        [string] $separator = ""  # Default Powerline separator
    )

    $ESC = [char]27  # Escape character

    # Generate the ANSI color codes for the background and foreground
    $leftBg = "$ESC[48;2;$($leftColor.R);$($leftColor.G);$($leftColor.B)m"
    $leftFg = "$ESC[38;2;$($leftColor.R);$($leftColor.G);$($leftColor.B)m"
    $rightBg = "$ESC[48;2;$($rightColor.R);$($rightColor.G);$($rightColor.B)m"

    # Combine them to get the desired split background with separator
    return "$leftBg$rightBg$leftFg$separator$ESC[0m"
}


function Global:Git-GetStatus {
    $branch = Git-GetBranchName
    if (-not [string]::IsNullOrWhiteSpace($branch)) {
        $update = Git-UpdateCheck
        switch ($update) {
            -1 { $branch += " -" }
            1 { $branch += " +" }
        }
    }

    return $branch
}


function Global:Prompt {
    try {

        [System.Collections.Generic.List[ScriptBlock]] $segments = @(
            { [System.Environment]::NewLine }
            { $Ansi.Bg.Color($Colors.Dracula.Background) + "PS" }
            { $Ansi.Bg.Separator($Colors.Dracula.Background, $Colors.Dracula.Yellow) }
            { $Ansi.Bg.Color($Colors.Dracula.Yellow) + [System.Environment]::MachineName }
            { $Ansi.Bg.Separator($Colors.Dracula.Yellow, $Colors.Dracula.Pink) }
            { $Ansi.Bg.Color($Colors.Dracula.Pink) + [System.Environment]::UserName }
            { $Ansi.Bg.Separator($Colors.Dracula.Pink, $Colors.Dracula.Purple) }
            { $Ansi.Bg.Color($Colors.Dracula.Purple) + (pwd) }
            { $Ansi.Bg.Separator($Colors.Dracula.Purple, $Colors.Dracula.Cyan) }
            { $Ansi.Bg.Color($Colors.Dracula.Cyan) + $(Git-GetStatus) }
            { $Ansi.Bg.Separator($Colors.Dracula.Cyan, $Colors.Dracula.Comment) }
            { $Ansi.Bg.Color($Colors.Dracula.Comment) + ">" * ($nestedPromptLevel + 1) }
            { $Ansi.Bg.Separator($Colors.Dracula.Comment, $Colors.Dracula.Background) }
        )

        # [System.Collections.Generic.List[ScriptBlock]] $segments = @(
        #     { [System.Environment]::NewLine }
        #     { $Ansi.Bg.Color($Colors.Bootstrap.Indigo100) + "PS" }
        #     { $Ansi.Bg.Separator($Colors.Bootstrap.Indigo100, $Colors.Bootstrap.Indigo200) }
        #     { $Ansi.Bg.Color($Colors.Bootstrap.Indigo200) + [System.Environment]::MachineName }
        #     { $Ansi.Bg.Separator($Colors.Bootstrap.Indigo200, $Colors.Bootstrap.Indigo300) }
        #     { $Ansi.Bg.Color($Colors.Bootstrap.Indigo300) + [System.Environment]::UserName }
        #     { $Ansi.Bg.Separator($Colors.Bootstrap.Indigo300, $Colors.Bootstrap.Indigo400) }
        #     { $Ansi.Bg.Color($Colors.Bootstrap.Indigo400) + (pwd) }
        #     { $Ansi.Bg.Separator($Colors.Bootstrap.Indigo400, $Colors.Bootstrap.Indigo500) }
        #     { $Ansi.Bg.Color($Colors.Bootstrap.Indigo500) + $(Git-GetStatus) }
        #     { $Ansi.Bg.Separator($Colors.Bootstrap.Indigo500, $Colors.Bootstrap.Indigo600) }
        #     { $Ansi.Bg.Color($Colors.Bootstrap.Indigo600) + ">" * ($nestedPromptLevel + 1) }
        #     { $Ansi.Bg.Separator($Colors.Bootstrap.Indigo600, $Colors.Dracula.Background) }
        # )

        [string] $prompt = ""
        foreach ($block in $segments) {
            [string] $value = & $block
            $prompt += $value
        }

        return $prompt + $Ansi.Reset + " "
    } catch {
        Write-Host "Error in prompt function: $_" -ForegroundColor Red
    }
}
