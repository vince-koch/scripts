# USAGE
# Import-Module $PSScriptRoot\Colors.psm1 -DisableNameChecking -Force

Add-Type -AssemblyName System.Drawing

$BootstrapBlue = [System.Drawing.ColorTranslator]::FromHtml("#0d6efd")
$BootstrapIndigo = [System.Drawing.ColorTranslator]::FromHtml("#6610f2")
$BootstrapPurple = [System.Drawing.ColorTranslator]::FromHtml("#6f42c1")
$BootstrapPink = [System.Drawing.ColorTranslator]::FromHtml("#d63384")
$BootstrapRed = [System.Drawing.ColorTranslator]::FromHtml("#dc3545")
$BootstrapOrange = [System.Drawing.ColorTranslator]::FromHtml("#fd7e14")
$BootstrapYellow = [System.Drawing.ColorTranslator]::FromHtml("#ffc107")
$BootstrapTeal = [System.Drawing.ColorTranslator]::FromHtml("#20c997")
$BootstrapGreen = [System.Drawing.ColorTranslator]::FromHtml("#198754")
$BootstrapCyan = [System.Drawing.ColorTranslator]::FromHtml("#0dcaf0")
$BootstrapGray = [System.Drawing.ColorTranslator]::FromHtml("#adb5bd")
$BootstrapBlack = [System.Drawing.ColorTranslator]::FromHtml("#000000")
$BootstrapWhite = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")


function AdjustColorBrightness {
    param (
        [System.Drawing.Color] $color,
        [float] $correctionFactor
    )

    if ($correctionFactor -lt -1 -or $correctionFactor -gt 1)
    {
        throw "$correctionFactor must be between -1 and 1"
    }
    
    [float] $red = $color.R
    [float] $green = $color.G
    [float] $blue = $color.B

    if ($correctionFactor -lt 0)
    {
        $correctionFactor = 1 + $correctionFactor
        $red = $red * $correctionFactor
        $green = $green * $correctionFactor
        $blue = $blue * $correctionFactor
    }
    else
    {
        $red = (255 - $red) * $correctionFactor + $red
        $green = (255 - $green) * $correctionFactor + $green
        $blue = (255 - $blue) * $correctionFactor + $blue
    }

    return [System.Drawing.Color]::FromArgb([int]$red, [int]$green, [int]$blue)
}

[PsCustomObject] $Colors = [PsCustomObject] @{
    Bootstrap = [PsCustomObject] @{
        Blue = $BootstrapBlue
        Blue100 = AdjustColorBrightness $BootstrapBlue .8
        Blue200 = AdjustColorBrightness $BootstrapBlue .6
        Blue300 = AdjustColorBrightness $BootstrapBlue .4
        Blue400 = AdjustColorBrightness $BootstrapBlue .2
        Blue500 = $BootstrapBlue
        Blue600 = AdjustColorBrightness $BootstrapBlue -.2
        Blue700 = AdjustColorBrightness $BootstrapBlue -.4
        Blue800 = AdjustColorBrightness $BootstrapBlue -.6
        Blue900 = AdjustColorBrightness $BootstrapBlue -.8

        Indigo = $BootstrapIndigo
        Indigo100 = AdjustColorBrightness $BootstrapIndigo .8
        Indigo200 = AdjustColorBrightness $BootstrapIndigo .6
        Indigo300 = AdjustColorBrightness $BootstrapIndigo .4
        Indigo400 = AdjustColorBrightness $BootstrapIndigo .2
        Indigo500 = $BootstrapIndigo
        Indigo600 = AdjustColorBrightness $BootstrapIndigo -.2
        Indigo700 = AdjustColorBrightness $BootstrapIndigo -.4
        Indigo800 = AdjustColorBrightness $BootstrapIndigo -.6
        Indigo900 = AdjustColorBrightness $BootstrapIndigo -.8

        Purple = $BootstrapPurple
        Purple100 = AdjustColorBrightness $BootstrapPurple .8
        Purple200 = AdjustColorBrightness $BootstrapPurple .6
        Purple300 = AdjustColorBrightness $BootstrapPurple .4
        Purple400 = AdjustColorBrightness $BootstrapPurple .2
        Purple500 = $BootstrapPurple
        Purple600 = AdjustColorBrightness $BootstrapPurple -.2
        Purple700 = AdjustColorBrightness $BootstrapPurple -.4
        Purple800 = AdjustColorBrightness $BootstrapPurple -.6
        Purple900 = AdjustColorBrightness $BootstrapPurple -.8
            
        Pink = $BootstrapPink
        Pink100 = AdjustColorBrightness $BootstrapPink .8
        Pink200 = AdjustColorBrightness $BootstrapPink .6
        Pink300 = AdjustColorBrightness $BootstrapPink .4
        Pink400 = AdjustColorBrightness $BootstrapPink .2
        Pink500 = $BootstrapPink
        Pink600 = AdjustColorBrightness $BootstrapPink -.2
        Pink700 = AdjustColorBrightness $BootstrapPink -.4
        Pink800 = AdjustColorBrightness $BootstrapPink -.6
        Pink900 = AdjustColorBrightness $BootstrapPink -.8

        Red = $BootstrapRed
        Red100 = AdjustColorBrightness $BootstrapRed .8
        Red200 = AdjustColorBrightness $BootstrapRed .6
        Red300 = AdjustColorBrightness $BootstrapRed .4
        Red400 = AdjustColorBrightness $BootstrapRed .2
        Red500 = $BootstrapRed
        Red600 = AdjustColorBrightness $BootstrapRed -.2
        Red700 = AdjustColorBrightness $BootstrapRed -.4
        Red800 = AdjustColorBrightness $BootstrapRed -.6
        Red900 = AdjustColorBrightness $BootstrapRed -.8

        Orange = $BootstrapOrange
        Orange100 = AdjustColorBrightness $BootstrapOrange .8
        Orange200 = AdjustColorBrightness $BootstrapOrange .6
        Orange300 = AdjustColorBrightness $BootstrapOrange .4
        Orange400 = AdjustColorBrightness $BootstrapOrange .2
        Orange500 = $BootstrapOrange
        Orange600 = AdjustColorBrightness $BootstrapOrange -.2
        Orange700 = AdjustColorBrightness $BootstrapOrange -.4
        Orange800 = AdjustColorBrightness $BootstrapOrange -.6
        Orange900 = AdjustColorBrightness $BootstrapOrange -.8

        Yellow = $BootstrapYellow
        Yellow100 = AdjustColorBrightness $BootstrapYellow .8
        Yellow200 = AdjustColorBrightness $BootstrapYellow .6
        Yellow300 = AdjustColorBrightness $BootstrapYellow .4
        Yellow400 = AdjustColorBrightness $BootstrapYellow .2
        Yellow500 = $BootstrapYellow
        Yellow600 = AdjustColorBrightness $BootstrapYellow -.2
        Yellow700 = AdjustColorBrightness $BootstrapYellow -.4
        Yellow800 = AdjustColorBrightness $BootstrapYellow -.6
        Yellow900 = AdjustColorBrightness $BootstrapYellow -.8

        Green = $BootstrapGreen
        Green100 = AdjustColorBrightness $BootstrapGreen .8
        Green200 = AdjustColorBrightness $BootstrapGreen .6
        Green300 = AdjustColorBrightness $BootstrapGreen .4
        Green400 = AdjustColorBrightness $BootstrapGreen .2
        Green500 = $BootstrapGreen
        Green600 = AdjustColorBrightness $BootstrapGreen -.2
        Green700 = AdjustColorBrightness $BootstrapGreen -.4
        Green800 = AdjustColorBrightness $BootstrapGreen -.6
        Green900 = AdjustColorBrightness $BootstrapGreen -.8

        Teal = $BootstrapTeal
        Teal100 = AdjustColorBrightness $BootstrapTeal .8
        Teal200 = AdjustColorBrightness $BootstrapTeal .6
        Teal300 = AdjustColorBrightness $BootstrapTeal .4
        Teal400 = AdjustColorBrightness $BootstrapTeal .2
        Teal500 = $BootstrapTeal
        Teal600 = AdjustColorBrightness $BootstrapTeal -.2
        Teal700 = AdjustColorBrightness $BootstrapTeal -.4
        Teal800 = AdjustColorBrightness $BootstrapTeal -.6
        Teal900 = AdjustColorBrightness $BootstrapTeal -.8

        Cyan = $BootstrapCyan
        Cyan100 = AdjustColorBrightness $BootstrapCyan .8
        Cyan200 = AdjustColorBrightness $BootstrapCyan .6
        Cyan300 = AdjustColorBrightness $BootstrapCyan .4
        Cyan400 = AdjustColorBrightness $BootstrapCyan .2
        Cyan500 = $BootstrapCyan
        Cyan600 = AdjustColorBrightness $BootstrapCyan -.2
        Cyan700 = AdjustColorBrightness $BootstrapCyan -.4
        Cyan800 = AdjustColorBrightness $BootstrapCyan -.6
        Cyan900 = AdjustColorBrightness $BootstrapCyan -.8

        Gray = $BootstrapGray
        Gray100 = AdjustColorBrightness $BootstrapGray .8
        Gray200 = AdjustColorBrightness $BootstrapGray .6
        Gray300 = AdjustColorBrightness $BootstrapGray .4
        Gray400 = AdjustColorBrightness $BootstrapGray .2
        Gray500 = $BootstrapGray
        Gray600 = AdjustColorBrightness $BootstrapGray -.2
        Gray700 = AdjustColorBrightness $BootstrapGray -.4
        Gray800 = AdjustColorBrightness $BootstrapGray -.6
        Gray900 = AdjustColorBrightness $BootstrapGray -.8

        Black = $BootstrapBlack
        White = $BootstrapWhite

        Primary = $BootstrapBlue
        Secondary = $BootstrapGray
        Success = $BootstrapGreen
        Danger = $BootstrapRed
        Warning = $BootstrapYellow
        Info = $BootstrapCyan
        Light = $BootstrapWhite
        Dark = $BootstrapBlack
    }

    Dracula = [PsCustomObject] @{
        Background = [System.Drawing.ColorTranslator]::FromHtml("#282a36")
        CurrentLine = [System.Drawing.ColorTranslator]::FromHtml("#44475a")
        Foreground = [System.Drawing.ColorTranslator]::FromHtml("#f8f8f2")
        Comment = [System.Drawing.ColorTranslator]::FromHtml("#6272a4")
        Cyan = [System.Drawing.ColorTranslator]::FromHtml("#8be9fd")
        Green = [System.Drawing.ColorTranslator]::FromHtml("#50fa7b")
        Orange = [System.Drawing.ColorTranslator]::FromHtml("#ffb86c")
        Pink = [System.Drawing.ColorTranslator]::FromHtml("#ff79c6")
        Purple = [System.Drawing.ColorTranslator]::FromHtml("#bd93f9")
        Red = [System.Drawing.ColorTranslator]::FromHtml("#ff5555")
        Yellow = [System.Drawing.ColorTranslator]::FromHtml("#f1fa8c")
    }
}

function Get-Colors {
    return $Colors
}

Export-ModuleMember -Function AdjustColorBrightness
Export-ModuleMember -Variable Colors
Export-ModuleMember -Function Get-Colors
