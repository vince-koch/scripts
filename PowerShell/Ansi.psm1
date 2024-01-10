# USAGE
# Import-Module $PSScriptRoot\Ansi.psm1 -DisableNameChecking -Force

# ANSI VT 100 Code Reference
# https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html#deletion
# https://en.wikipedia.org/wiki/ANSI_escape_code
# https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences

Add-Type -AssemblyName System.Drawing

[string] $ESC = "$([char]27)"

function ansi_cursor_up {
    param (
        [Parameter(Mandatory = $false)]
        [int] $lines = 1
    )

    return "$ESC[$($lines)A"
}

function ansi_cursor_down {
    param (
        [Parameter(Mandatory = $false)]
        [int] $lines = 1
    )

    return "$ESC[$($lines)B"
}

function ansi_cursor_right {
    param (
        [Parameter(Mandatory = $false)]
        [int] $columns = 1
    )

    return "$ESC[$($lines)C"
}

function ansi_cursor_left {
    param (
        [Parameter(Mandatory = $false)]
        [int] $columns = 1
    )

    return "$ESC[$($lines)D"
}

[PsCustomObject] $Ansi = [PsCustomObject] @{
    Reset 				= "$ESC[0m"

    Bold	            = "$ESC[1m"
    BoldReset           = "$ESC[22m"
    Underline           = "$ESC[4m"
    UnderlineReset	    = "$ESC[24m"
    Invert			    = "$ESC[7m"
    InvertReset		    = "$ESC[27m"
    Blink               = "$ESC[5m"
    
    Fg = [PsCustomObject] @{
        Black           = "$ESC[30m"
        Red             = "$ESC[31m"
        Green           = "$ESC[32m"
        Yellow          = "$ESC[33m"
        Blue            = "$ESC[34m"
        Magenta         = "$ESC[35m"
        Cyan            = "$ESC[36m"
        White           = "$ESC[37m"
        BrightBlack     = "$ESC[90m"
        BrightRed       = "$ESC[91m"
        BrightGreen     = "$ESC[92m"
        BrightYellow    = "$ESC[93m"
        BrightBlue      = "$ESC[94m"
        BrightMagenta   = "$ESC[95m"
        BrightCyan      = "$ESC[96m"
        BrightWhite     = "$ESC[97m"
    }

    Bg = [PsCustomObject] @{
        Black           = "$ESC[40m"
        Red             = "$ESC[41m"
        Green           = "$ESC[42m"
        Yellow          = "$ESC[43m"
        Blue            = "$ESC[44m"
        Magenta         = "$ESC[45m"
        Cyan            = "$ESC[46m"
        White           = "$ESC[47m"
        BrightBlack     = "$ESC[100m"
        BrightRed       = "$ESC[101m"
        BrightGreen     = "$ESC[102m"
        BrightYellow    = "$ESC[103m"
        BrightBlue      = "$ESC[104m"
        BrightMagenta   = "$ESC[105m"
        BrightCyan      = "$ESC[106m"
        BrightWhite     = "$ESC[107m"
    }

    Clear = [PsCustomObject] @{
        EndScreen       = "$ESC[0J" # clears from cursor until end of screen
        BeginScreen     = "$ESC[1J" # clears from cursor to beginning of screen
        Screen          = "$ESC[2J" # clears entire screen

        ToLineEnd       = "$ESC[0K" # clears from cursor until end of line
        ToLineStart     = "$ESC[1K" # clears from cursor to start of line
        Line            = "$ESC[2K" # clears entire line
    }

    Cursor = [PsCustomObject] @{
        Up      = ansi_cursor_up
        Down    = ansi_cursor_down
        Right   = ansi_cursor_right
        Left    = ansi_cursor_left
    }
}

$Ansi.Fg | Add-Member -MemberType ScriptMethod -Name "Color" -Force -Value {
    param (
        [System.Drawing.Color] $color
    )

    return "$ESC[38;2;$($color.R);$($color.G);$($color.B)m"    
}

$Ansi.Fg | Add-Member -MemberType ScriptMethod -Name "Hex" -Force -Value {
    param (
        [string] $hex
    )

    $color = [System.Drawing.ColorTranslator]::FromHtml($hex)
    $result = "$ESC[38;2;$($color.R);$($color.G);$($color.B)m"

    return $result
}

$Ansi.Fg | Add-Member -MemberType ScriptMethod -Name "Rgb" -Force -Value {
    param (
        [int] $r,
        [int] $g,
        [int] $b
    )

    return "$ESC[38;2;$($r);$($g);$($b)m"
}

$Ansi.Bg | Add-Member -MemberType ScriptMethod -Name "Color" -Force -Value {
    param (
        [System.Drawing.Color] $color
    )

    return "$ESC[42;2;$($color.R);$($color.G);$($color.B)m"    
}

$Ansi.Bg | Add-Member -MemberType ScriptMethod -Name "Hex" -Force -Value {
    param (
        [string] $hex
    )

    $color = [System.Drawing.ColorTranslator]::FromHtml($hex)
    $result = "$ESC[42;2;$($color.R);$($color.G);$($color.B)m"

    return $result
}

$Ansi.Bg | Add-Member -MemberType ScriptMethod -Name "Rgb" -Force -Value {
    param (
        [int] $r,
        [int] $g,
        [int] $b
    )

    return "$ESC[48;2;$($r);$($g);$($b)m"
}

function Get-Ansi {
    return $Ansi
}

Export-ModuleMember -Variable Ansi
Export-ModuleMember -Function Get-Ansi