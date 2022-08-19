# USAGE
# Import-Module $PSScriptRoot\Ansi.psm1 -DisableNameChecking -Force

# ANSI VT 100 Code Reference
# https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html#deletion

[string] $ESC                  = "$([char]27)" 

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
    
    Fg = [PsCustomObject] @{
        Black           = "$ESC[30m"
        Red             = "$ESC[31m"
        Green           = "$ESC[32m"
        Yellow          = "$ESC[33m"
        Blue            = "$ESC[34m"
        Magenta         = "$ESC[35m"
        Cyan            = "$ESC[36m"
        White           = "$ESC[37m"
        BrightBlack     = "$ESC[30;1m"
        BrightRed       = "$ESC[31;1m"
        BrightGreen     = "$ESC[32;1m"
        BrightYellow    = "$ESC[33;1m"
        BrightBlue      = "$ESC[34;1m"
        BrightMagenta   = "$ESC[35;1m"
        BrightCyan      = "$ESC[36;1m"
        BrightWhite     = "$ESC[37;1m"
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
        BrightBlack     = "$ESC[40;1m"
        BrightRed       = "$ESC[41;1m"
        BrightGreen     = "$ESC[42;1m"
        BrightYellow    = "$ESC[43;1m"
        BrightBlue      = "$ESC[44;1m"
        BrightMagenta   = "$ESC[45;1m"
        BrightCyan      = "$ESC[46;1m"
        BrightWhite     = "$ESC[47;1m"
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

function Get-Ansi {
    return $Ansi
}

Export-ModuleMember -Variable Ansi
Export-ModuleMember -Function Get-Ansi