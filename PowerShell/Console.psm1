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

function Console-Menu {
    param (
        [array] $menuItems,
        [switch] $ReturnIndex = $false,
        [switch] $MultiSelect = $false,
        [System.ConsoleColor] $ActiveColor = [System.ConsoleColor]::Green,
        [int] $Index = 0
    )

    $selection = @()

    # prevent cursor flickering
    [console]::CursorVisible=$false

    if ($menuItems.Length -gt 0)
    {
        # initial draw of the menu, and calculation of the top
        Console-MenuDraw $menuItems $Index $MultiSelect $selection $ActiveColor
        $cur_pos = [System.Console]::CursorTop - $menuItems.Length

        # loop
        $vkeycode = 0
        while ($vkeycode -ne 13 -and $vkeycode -ne 27)
        {
            $press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
            $vkeycode = $press.virtualkeycode

            # up down and toggle select
            if ($vkeycode -eq 38) { $Index-- }
            if ($vkeycode -eq 40) { $Index++ }
            if ($press.Character -eq ' ') { $selection = Console-MenuToggleSelection $Index $selection }

            # constrain to top and bottom
            if ($Index -lt 0) { $Index = 0 }
            if ($Index -ge $menuItems.length) { $Index = $menuItems.length -1 }

            # escape
            if ($vkeycode -eq 27)
            {
                $Index = -1
                $selection = $null
            }

            # retdraw menu
            if ($vkeycode -ne 27)
            {
                [System.Console]::SetCursorPosition(0, $cur_pos)
                Console-MenuDraw $menuItems $Index $MultiSelect $selection $ActiveColor
            }
        }
    }
    else
    {
        $Index = $null
    }

    [console]::CursorVisible=$true

    if ($ReturnIndex -eq $false -and $Index -ne -1)
    {
        if ($MultiSelect)
        {
            return $menuItems[$selection]
        }
        else
        {
            return $menuItems[$Index]
        }
    }
    else
    {
        if ($MultiSelect)
        {
            return $selection
        }
        else
        {
            return $Index
        }
    }
}

function Console-MenuDraw {
    param ($menuItems, $menuPosition, $MultiSelect, $selection, $ActiveColor)

    $l = $menuItems.length
    for ($i = 0; $i -le $l;$i++)
    {
        if ($menuItems[$i] -ne $null)
        {
            $item = $menuItems[$i]
            if ($MultiSelect)
            {
                if ($selection -contains $i)
                {
                    $item = '[x] ' + $item
                }
                else
                {
                    $item = '[ ] ' + $item
                }
            }

            if ($i -eq $menuPosition)
            {
                Write-Host "> $($item)" -ForegroundColor $ActiveColor
            }
            else
            {
                Write-Host "  $($item)"
            }
        }
    }
}

function Console-MenuToggleSelection {
    param ($pos, [array] $selection)

    if ($selection -contains $pos)
    {
        [string[]] $result = $selection | where {$_ -ne $pos}
    }
    else
    {
        $selection += $pos
        [string[]] $result = $selection
    }

    return $result
}

Export-ModuleMember -Function Console-Confirm
Export-ModuleMember -Function Console-Menu