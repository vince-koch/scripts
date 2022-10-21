# USAGE
# Import-Module $PSScriptRoot\Console.psm1 -DisableNameChecking -Force
#
# This file is an updated version of the code found here
# https://github.com/chrisseroka/ps-menu/blob/master/ps-menu.psm1

function Console-Confirm {
    param (
        [string] $Prompt,
        [bool] $Default = $true,
        [System.ConsoleColor] $ActiveColor = [System.ConsoleColor]::Green
    )

    Write-Host $Prompt -NoNewLine

    $result = $null
    while ($result -eq $null)
    {
        $press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
        $vkeycode = $press.virtualkeycode

        if ($vkeycode -eq 13) { $result = $Default }
        if ($vkeycode -eq 27) { $result = $false }
        if ($press.Character -eq 'Y') { $result = $true }
        if ($press.Character -eq 'N') { $result = $false }
    }

    if ($result -eq $true)
    {
        Write-Host "Y" -ForegroundColor $ActiveColor
    }
    else
    {
        Write-Host "N" -ForegroundColor $ActiveColor
    }

    return $result
}

class Menu
{
    [string] $Title = $null

    [array] $Items
    #[string] $ItemsProperty = $null
    [scriptblock] $ItemsProperty = $null

    [boolean] $IgnoreEscape = $false
    [boolean] $IsMultiSelect = $false
    [boolean] $ReturnIndex = $false

    [int] $CurrentIndex = 0
    [array] $SelectedIndexes = @()
    [boolean] $WasExitRequested = $false

    [System.ConsoleColor] $TitleColor = [System.ConsoleColor]::Cyan
    [System.ConsoleColor] $ActiveColor = [System.ConsoleColor]::Green

    [array] Run()
    {
        if ($this.Items -eq $null -or $this.Items.Length -eq 0)
        {
            throw "Can not invoke Menu.Run() while Menu.Items is null or empty"
        }

        [System.Console]::CursorVisible = $false
        $this.CurrentIndex = [System.Math]::Max($this.CurrentIndex, 0)
        $this.SelectedIndexes = @()
        $this.WasExitRequested = $false

        $this.Draw($false)
        while ($this.WasExitRequested -eq $false)
        {
            $this.HandleKey()
            $this.Draw($true)
        }

        [System.Console]::CursorVisible = $true
        $result = $this.CalculateResult()
        return $result
    }

    [void] Draw([boolean] $resetCursorPosition)
    {
        # ansi codes
        $Esc = [char]27
        $ClearLine = "$Esc[2K"

        $titleLine = $( if ([string]::IsNullOrWhiteSpace($this.Title)) { 0 } else { 1 } )

        # calculate items to render and reset cursor position if requested to do so
        $renderCount = [System.Math]::Min($this.Items.Length + $titleLine, [System.Console]::WindowHeight - 1)
        if ($resetCursorPosition)
        {
            [System.Console]::CursorTop = [System.Console]::CursorTop - $renderCount
        }

        if ($titleLine -gt 0)
        {
            Write-Host $this.Title -ForegroundColor $this.TitleColor
            $renderCount -= $titleLine
        }

        # calculate the appropriate start start index
        $startIndex = 0
        if ($renderCount -lt $this.Items.Length)
        {
            $renderMid = [System.Math]::Floor($renderCount / 2)

            if ($this.CurrentIndex -lt $this.Items.Length - $renderMid)
            {
                $startIndex = [System.Math]::Max($this.CurrentIndex - $renderMid, 0)
            }
            else
            {
                $startIndex = $this.Items.Length - $renderCount
            }
        }

        $endIndex = $startIndex + $renderCount

        for ($i = $startIndex; $i -lt $endIndex; $i++)
        {
            if ($this.Items[$i] -ne $null)
            {
                if ($this.ItemsProperty -eq $null)
                {
                    $item = $this.Items[$i]
                }
                else
                {
                    $item = $this.ItemsProperty.Invoke( $this.Items[$i] )
                }

                if ($this.IsMultiSelect)
                {
                    if ($this.SelectedIndexes -contains $i)
                    {
                        $item = '[x] ' + $item
                    }
                    else
                    {
                        $item = '[ ] ' + $item
                    }
                }

                if ($i -eq $this.CurrentIndex)
                {
                    Write-Host "$($ClearLine)> $($item)" -ForegroundColor $this.ActiveColor
                }
                else
                {
                    Write-Host "$($ClearLine)  $($item)"
                }
            }
        }
    }

    [void] HandleKey()
    {
        $breakAsInput = [System.Console]::TreatControlCAsInput
        [System.Console]::TreatControlCAsInput = $true
        $keyinfo = [System.Console]::ReadKey($true)
        [System.Console]::TreatControlCAsInput = $breakAsInput

        # ctrl+c
        if ($keyinfo.Modifiers -band [System.ConsoleModifiers]::Control -and $keyinfo.Key -eq [System.ConsoleKey]::C)
        {
            $this.CurrentIndex = -1
            $this.SelectedIndexes = $null
            $this.WasExitRequested = $true
        }

        # up arrow
        if ($keyinfo.Key -eq [System.ConsoleKey]::UpArrow)
        {
            $this.CurrentIndex = [System.Math]::Max($this.CurrentIndex - 1, 0)
        }

        # down arrow
        if ($keyinfo.Key -eq [System.ConsoleKey]::DownArrow) 
        {
            $this.CurrentIndex = [System.Math]::Min($this.CurrentIndex + 1, $this.Items.Length - 1)
        }

        # enter
        if ($keyinfo.Key -eq [System.ConsoleKey]::Enter)
        {
            $this.WasExitRequested = $true
        }

        # escape
        if ($this.IgnoreEscape -eq $false -and $keyinfo.Key -eq [System.ConsoleKey]::Escape)
        {
            $this.CurrentIndex = -1
            $this.SelectedIndexes = $null
            $this.WasExitRequested = $true
        }

        # space
        if ($this.IsMultiSelect -and $keyinfo.Key -eq [System.ConsoleKey]::Spacebar)
        {
            if ($this.SelectedIndexes  -contains $this.CurrentIndex)
            {
                $this.SelectedIndexes = $this.SelectedIndexes | Where { $_ -ne $this.CurrentIndex }
            }
            else
            {
                $this.SelectedIndexes += $this.CurrentIndex
            }
        }
    }

    [array] CalculateResult()
    {
        # escape was pressed, return null
        if ($this.CurrentIndex -eq -1)
        {
            return $null
        }

        # single select
        if ($this.IsMultiSelect -eq $false)
        {
            if ($this.ReturnIndex -eq $true)
            {
                return $this.CurrentIndex
            }
            else
            {
                return $this.Items[$this.CurrentIndex]
            }
        }

        # multi-select, convert selected indexes to selected items
        $ordered = @( $this.SelectedIndexes | Sort { $_ } )
        if ($this.ReturnIndex -eq $true)
        {
            return $ordered
        }
        else
        {
            $result = $this.Items[$ordered]
            return $result
        }
    }
}

function Console-Menu {
    param (
        [array] $Items,
        [ScriptBlock] $ItemsProperty = $null,
        [string] $Title = $null,
        [switch] $IsMultiSelect = $false,
        [switch] $IgnoreEscape = $false,
        [switch] $ReturnIndex = $false,
        [int] $CurrentIndex = -1,
        [System.ConsoleColor] $ActiveColor = [System.ConsoleColor]::Green,
        [System.ConsoleColor] $TitleColor = [System.ConsoleColor]::Cyan
    )

    $menu = [Menu]::new()
    $menu.Items = $Items
    $menu.ItemsProperty = $ItemsProperty
    $menu.Title = $Title
    $menu.IsMultiSelect = $IsMultiSelect
    $menu.IgnoreEscape = $IgnoreEscape
    $menu.ReturnIndex = $ReturnIndex
    $menu.CurrentIndex = $CurrentIndex
    $menu.ActiveColor = $ActiveColor
    $menu.TitleColor = $TitleColor

    $result = $menu.Run()

    return $result
}

function Console-CreateMenu {
    return [Menu]::new()
}

function Console-RunTests {
    $wasExitRequested = $false
    while ($wasExitRequested -eq $false) {
        Write-Host ""

        $mainMenuResult = Console-Menu -Title "Main Menu" -Items @("Confirm", "Menu", "Menu (Multi-Select)", "Menu (Ignore Escape)", "Exit")

        $subMenuTitle = "Select Fruit:  [$mainMenuResult]"
        $subMenuItems = $( "apple", "apricot", "banana", "blackberry", "cantelope", "cherry", "dragonfruit", "grape", "grapefruit", "kiwi", "lime", "mango", "orange", "peach", "pear", "pineapple", "raspberry", "strawberry", "tomatoe" )

        switch ($mainMenuResult) {
            "Confirm" {

            }

            "Menu" {
                $result = Console-Menu -Title $subMenuTitle -Items $subMenuItems
                Write-Host "Selected: $($result)" -ForegroundColor Yellow
            }

            "Menu (Multi-Select)" {
                $result = Console-Menu -Title $subMenuTitle -Items $subMenuItems -IsMultiSelect -TitleColor DarkMagenta
                Write-Host "Selected: $($result)" -ForegroundColor Yellow
            }

            "Menu (Ignore Escape)" {
                $result = Console-Menu -Title $subMenuTitle -Items $subMenuItems -IsMultiSelect -IgnoreEscape
                Write-Host "Selected: $($result)" -ForegroundColor Yellow
            }

            "Exit" {
                $wasExitRequested = $true
            }

            $null { # ESC
                $wasExitRequested = $true
            }

            default {
                Write-Host "MainMenu unrecognized selection [$mainMenuResult]" -ForegroundColor Red
            }
        }
    }
}

function Console-WriteColor {
	# cribbed from:  https://github.com/EvotecIT/PSWriteColor/blob/master/Public/Write-Color.ps1
	param (
		[alias ('T')] [String[]] $Text,
		[alias ('F', 'FG', 'C', 'Color')] [ConsoleColor[]] $ForegroundColor = [ConsoleColor]::White,
		[alias ('B', 'BG')] [ConsoleColor[]] $BackGroundColor = $null,
		[alias('DateFormat', 'TimeFormat')] [string] $DateTimeFormat = 'yyyy-MM-dd HH:mm:ss',
		[switch] $NoNewLine,
		[switch] $ShowTime
	)
	
	$DefaultColor = $ForegroundColor[0]
	
	if ($ShowTime) { Write-Host -Object "[$([datetime]::Now.ToString($DateTimeFormat))] " -NoNewline } # Add Time before output
	
    if ($Text.Count -ne 0) {
        if ($ForegroundColor.Count -ge $Text.Count) {
            # the real deal coloring
            if ($null -eq $BackGroundColor) {
                for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $ForegroundColor[$i] -NoNewline }
            }
			else {
                for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $ForegroundColor[$i] -BackgroundColor $BackGroundColor[$i] -NoNewline }
            }
        }
		else {
            if ($null -eq $BackGroundColor) {
                for ($i = 0; $i -lt $ForegroundColor.Length ; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $ForegroundColor[$i] -NoNewline }
                for ($i = $ForegroundColor.Length; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $DefaultColor -NoNewline }
            }
			else {
                for ($i = 0; $i -lt $ForegroundColor.Length ; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $ForegroundColor[$i] -BackgroundColor $BackGroundColor[$i] -NoNewline }
                for ($i = $ForegroundColor.Length; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $DefaultColor -BackgroundColor $BackGroundColor[0] -NoNewline }
            }
        }
    }
	
	if ($NoNewLine -eq $true) { Write-Host -NoNewline } else { Write-Host } # Support for no new line
}

function Console-WriteHR {
    param (
        [AllowNull()] [Nullable[ConsoleColor]] $ForegroundColor = $null
    )

    if ($ForegroundColor.HasValue -ne $null) {
        $ForegroundColor = DarkGray
    }
   
    $BoxDrawingsLightHorizontal = [string][char]0x2500
    $BoxDrawingsDoubleHorizontal = [string][char]0x2550
    $HR = $BoxDrawingsLightHorizontal
    Write-Host $($HR * ([Console]::WindowWidth - 1)) -ForegroundColor $ForegroundColor
}

Export-ModuleMember -Function Console-Confirm
Export-ModuleMember -Function Console-Menu
Export-ModuleMember -Function Console-CreateMenu
Export-ModuleMember -Function Console-RunTests
Export-ModuleMember -Function Console-WriteColor
Export-ModuleMember -Function Console-WriteHR