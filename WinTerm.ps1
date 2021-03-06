param (
    [string] $verb,
    [string] $arg0 = ""
)

Add-Type -Assembly System.Drawing

[string] $settingsPath = "$($env:LOCALAPPDATA)\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
[string] $colorSchemeToken = '"colorScheme":'

function Main
{
    switch ($verb)
    {
        "current" 
        {
            [object[]] $settings = ReadSettingsFile
            [string] $currentSchemeName = SelectCurrentSchemeName $settings
            Write-Host "Current Scheme: " -NoNewLine
            Write-Host $currentSchemeName -ForegroundColor Yellow
        }

        "prev"
        {
            [object[]] $settings = ReadSettingsFile
            [string] $prevSchemeName = SelectRelativeSchemeName $settings -1
            WriteCurrentSchemeNameToSettingsFile $prevSchemeName
            Write-Host "Current Scheme: " -NoNewLine
            Write-Host $prevSchemeName -ForegroundColor Yellow
        }

        "next" 
        {
            [object[]] $settings = ReadSettingsFile
            [string] $nextSchemeName = SelectRelativeSchemeName $settings 1
            WriteCurrentSchemeNameToSettingsFile $nextSchemeName
            Write-Host "Current Scheme: " -NoNewLine
            Write-Host $nextSchemeName -ForegroundColor Yellow
        }

        "list" 
        {
            [object[]] $settings = ReadSettingsFile
            [string[]] $list = SelectMatchingSchemeNames $settings $arg0
            
            Write-Host $list.Length -ForegroundColor Yellow -NoNewline
            if ($null -ne $arg0 -and $arg0.Length -gt 0)
            {
                Write-Host " items matching " -NoNewLine
                Write-Host $arg0 -ForegroundColor Yellow
            }
            else
            {
                Write-Host " Items"
            }

            Write-Host
            WriteItemsToHost $list
        }

        "set"
        {
            [object[]] $settings = ReadSettingsFile
            [string[]] $list = SelectMatchingSchemeNames $settings $arg0

            if ($list.Length -eq 1)
            {
                WriteCurrentSchemeNameToSettingsFile $list[0]
                Write-Host "Current Scheme: " -NoNewLine
                Write-Host $list[0] -ForegroundColor Yellow
            }
            else
            {
                Write-Host $list.Length -ForegroundColor Yellow -NoNewline
                Write-Host " items matching " -NoNewLine
                Write-Host $arg0 -ForegroundColor Yellow
                Write-Host
                WriteItemsToHost $list
            }
        }

        "table" 
        {
            Write-Host
            [System.ConsoleColor] $altForegroundColor = if ($null -eq $arg0 -or $arg0.Length -eq 0) { 7 } else { $arg0 }
            WriteColorTable $altForegroundColor
        }

        "colortable"
        {
            Write-Host
            [System.ConsoleColor] $altForegroundColor = if ($null -eq $arg0 -or $arg0.Length -eq 0) { 7 } else { $arg0 }
            WriteColorTable $altForegroundColor
        }

        "registry" 
        {
            SyncToRegistry
        }

        "interactive" { InteractiveMain }
        "help" { ShowHelp }
        default { ShowHelp }
    }

    Write-Host
}

function ShowHelp
{
    Write-Host
    Write-Host "current           displays the name of the current scheme"
    Write-Host "set [schemeName]  sets the specified scheme as the current scheme"
    Write-Host "list [filter]     displays an optionally filtered list of all installed schemes"
    Write-Host "next              sets the next scheme as the current scheme"
    Write-Host "prev              sets the prev scheme as the current scheme"
    Write-Host "table             displays a simple color table"
    Write-Host "interactive       enters an interactive mode for changing current scheme"
    Write-Host "registry          synchronize current color scheme to registry (cmd.exe and powershell.exe)"
    Write-Host "help              displays this help screen"
}

function InteractiveMain
{
    WriteColorTable
    Write-Host

    [object[]] $settings = ReadSettingsFile
    [string] $currentSchemeName = SelectCurrentSchemeName $settings

    [bool] $hasUpdated = $false
    [bool] $isExitRequested = $false
    while ($isExitRequested -eq $false)
    {
        Write-Host "`r[P]rev, [N]ext, e[X]it " -NoNewline
        Write-Host "$($currentSchemeName)                                        `b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b" -ForegroundColor Yellow -NoNewline

        $keyInfo = [Console]::ReadKey($true)
        if ($keyInfo.Key -eq "LeftArrow" `
            -or $keyInfo.Key -eq "P")
        {
            $settings = ReadSettingsFile
            $currentSchemeName = SelectRelativeSchemeName $settings -1
            WriteCurrentSchemeNameToSettingsFile $currentSchemeName
            $hasUpdated = $true
        }
        elseif ($keyInfo.Key -eq "RightArrow" `
            -or $keyInfo.Key -eq "N")
        {
            $settings = ReadSettingsFile
            $currentSchemeName = SelectRelativeSchemeName $settings 1
            WriteCurrentSchemeNameToSettingsFile $currentSchemeName
            $hasUpdated = $true
        }
        elseif ($keyInfo.Key -eq "Escape" `
            -or $keyInfo.Key -eq "Enter" `
            -or $keyInfo.Key -eq "X")
        {
            if ($hasUpdated -eq $true)
            {
                [bool] $hasAnsweredPrompt = $false

                Write-Host
                Write-Host "Settings have changed.  Would you like to synchronize your current settings to the registry [Y/n]? " -NoNewLine
                while ($hasAnsweredPrompt -eq $false)
                {
                    $keyInfo = [Console]::ReadKey($true)
                    if ($keyInfo.Key -eq "Y" -or $keyInfo.Key -eq "Enter")
                    {
                        Write-Host "y" -ForegroundColor Yellow
                        $hasAnsweredPrompt = $true                        
                        SyncToRegistry
                    }
                    elseif ($keyInfo.Key -eq "N" -or $keyInfo.Key -eq "Escape")
                    {
                        Write-Host "n" -ForegroundColor Yellow
                        $hasAnsweredPrompt = $true
                    }
                }
            }

            $isExitRequested = $true
        }
    }
}

function ReadSettingsFile
{
    $lines = Get-Content $settingsPath | Where-Object {!$_.TrimStart().StartsWith("//")}
    $json = [String]::Join("", $lines)
    $settings = ConvertFrom-Json $json
    return $settings
}

function WriteCurrentSchemeNameToSettingsFile
{
    param (
        [string] $schemeName
    )

    if ($null -eq $schemeName -or $schemeName.Length -lt 1)
    {
        Write-Host "ERROR: can not set current scheme to empty" -ForegroundColor Red
        exit
    }

    # read lines from file
    [string[]] $lines = Get-Content $settingsPath
    
    # update the appropriate lines
    [int] $lineIndex = -1
    foreach ($line in $lines)
    {
        $lineIndex++
        $index = $line.IndexOf($colorSchemeToken)
        if ($index -gt -1)
        {
            [string] $key = $line.SubString(0, $index + $colorSchemeToken.Length)
            [string] $lineEnding = ""
            if ($line[$line.Length - 1] -eq ",")
            {
                $lineEnding = ","
            }

            [string] $newLine = "$($key) `"$($schemeName)`"$($lineEnding)"
            #Write-Host "Replacing line $($lineIndex): $($line.Trim()) ==> $($newLine.Trim())"
            $lines[$lineIndex] = $newLine
        }
    }

    # write lines back to file
    $content = [string]::Join("`n", $lines)
    Set-Content -Path $settingsPath -NoNewline $content
}

function WriteItemsToHost
{
    param (
        [object[]] $list
    )

    foreach ($item in $list)
    {
        Write-Host $item
    }
}

function SelectCurrentSchemeName
{
    param ( [object[]] $settings )

    [string] $currentSchemeName = $settings.profiles.defaults.colorScheme
    return $currentSchemeName
}

function SelectCurrentScheme
{
    param ( [object[]] $settings )

    [string] $currentSchemeName = $settings.profiles.defaults.colorScheme
    [object] $currentScheme = $settings.schemes | Where-Object {$_.name -eq $currentSchemeName}
    
    return $currentScheme
}

function SelectAllSchemeNames
{
    param ( [object[]] $settings )

    $schemeNames = $settings.schemes `
        | Sort-Object name `
        | Select-Object -ExpandProperty name

    return $schemeNames
}

function SelectMatchingSchemeNames
{
    param (
        [object[]] $settings,
        [string] $filter
    )

    $schemeNames = SelectAllSchemeNames $settings

    # first check for an exact match
    $matchingNames = $schemeNames -eq $filter
    if ($matchingNames.Length -eq 0)
    {
        # if we can't find an exact match, see what we can do with wildcards
        $schemeNames -like "*$($filter)*"
    }

    return $matchingNames
}

function SetScheme
{
    param (
        [object[]] $settings,
        [string] $schemeName
    )

    [string[]] $schemeNames = SelectMatchingSchemeNames $settings $schemeName
    if ($schemeNames.Count -eq 1)
    {
        $schemeName = $schemeNames[0]
        #Write-Host "Setting scheme to $($schemeName)"
        WriteCurrentScheme $schemeName
        return $schemeName
    }
    else
    {
        Write-Host "$($schemeNames.Length) matches found for $($schemeName)"
        foreach ($item in $schemeNames)
        {
            Write-Host $item
        }
    }

    return $null
}

function SelectRelativeSchemeName
{
    param (
        [object[]] $settings,
        [int] $delta = 1
    )

    [object[]] $schemeNames = SelectAllSchemeNames $settings
    [object] $currentSchemeName = SelectCurrentSchemeName $settings

    [int] $index = $schemeNames.IndexOf($currentSchemeName) + $delta
    if ($index -ge $schemeNames.Length) { $index = 0 }
    elseIf ($index -lt 0) { $index = $schemeNames.Length - 1 }

    [string] $nextSchemeName = $schemeNames[$index]
    return $nextSchemeName
}

function WriteColorTable
{
    param (
        [System.ConsoleColor] $altForegroundColor = 7
    )

    Write-Host "   By Ordinal                       By Matched Color"
    Write-Host "-----------------------------    -----------------------------"
    WriteColors Black Black $altForegroundColor
    WriteColors DarkBlue    DarkGray    $altForegroundColor
    WriteColors DarkGreen   Gray        $altForegroundColor
    WriteColors DarkCyan    White       $altForegroundColor
    WriteColors DarkRed     DarkBlue    $altForegroundColor
    WriteColors DarkMagenta Blue        $altForegroundColor
    WriteColors DarkYellow  DarkGreen   $altForegroundColor
    WriteColors Gray        Green       $altForegroundColor
    WriteColors DarkGray    DarkCyan    $altForegroundColor
    WriteColors Blue        Cyan        $altForegroundColor
    WriteColors Green       DarkRed     $altForegroundColor
    WriteColors Cyan        Red         $altForegroundColor
    WriteColors Red         DarkMagenta $altForegroundColor
    WriteColors Magenta     Magenta     $altForegroundColor
    WriteColors Yellow      DarkYellow  $altForegroundColor
    WriteColors White       Yellow      $altForegroundColor
}

function WriteColors
{
    param (
        [System.ConsoleColor] $base16,
        [System.ConsoleColor] $colorMatched,
        [System.ConsoleColor] $labelColor = 15
    )

    Write-Host ([int]$base16).ToString().PadLeft(2, ' ') -ForegroundColor $labelColor -NoNewline
    Write-Host " " -NoNewline
    Write-Host $base16.ToString().PadRight(15, ' ') -ForegroundColor $labelColor -NoNewline
    Write-Host $base16.ToString().PadRight(15, ' ') -ForegroundColor $base16 -NoNewline

    Write-Host ([int]$colorMatched).ToString().PadLeft(2, ' ') -ForegroundColor $labelColor -NoNewline
    Write-Host " " -NoNewline
    Write-Host $colorMatched.ToString().PadRight(15, ' ') -ForegroundColor $labelColor -NoNewline
    Write-Host $colorMatched.ToString().PadRight(15, ' ') -ForegroundColor $colorMatched
}

function SyncToRegistry
{
    [string] $ConsoleRegistryKey = "HKEY_CURRENT_USER\Console"
    [object[]] $settings = ReadSettingsFile
    [object] $currentScheme = SelectCurrentScheme $settings

    # match the color table to the current color scheme
    SetRegistryColor "ColorTable00" $currentScheme.black
    SetRegistryColor "ColorTable01" $currentScheme.blue
    SetRegistryColor "ColorTable02" $currentScheme.green
    SetRegistryColor "ColorTable03" $currentScheme.cyan
    SetRegistryColor "ColorTable04" $currentScheme.red
    SetRegistryColor "ColorTable05" $currentScheme.purple
    SetRegistryColor "ColorTable06" $currentScheme.yellow
    SetRegistryColor "ColorTable07" $currentScheme.white
    SetRegistryColor "ColorTable08" $currentScheme.brightBlack
    SetRegistryColor "ColorTable09" $currentScheme.brightBlue
    SetRegistryColor "ColorTable10" $currentScheme.brightGreen
    SetRegistryColor "ColorTable11" $currentScheme.brightCyan
    SetRegistryColor "ColorTable12" $currentScheme.brightRed
    SetRegistryColor "ColorTable13" $currentScheme.brightPurple
    SetRegistryColor "ColorTable14" $currentScheme.brightYellow
    SetRegistryColor "ColorTable15" $currentScheme.brightWhite

    # match the opacity to the acrylic opacity of the default profile
    if ($settings.profiles.defaults.useAcrylic -eq $true)
    {
        [decimal] $multiplier = [decimal] $settings.profiles.defaults.acrylicOpacity
        [int] $windowAlpha = 255 * $multiplier
        
        [Microsoft.Win32.Registry]::SetValue($ConsoleRegistryKey, "WindowAlpha", $windowAlpha)
    }

    # just set some more sensible defaults for window size
    SetRegistrySize "WindowSize" 120 50
}

function SetRegistrySize
{
    param (
        [string] $valueName,
        [int] $width,
        [int] $height)

    [int] $size = (65536 * $height) + $width

    [string] $ConsoleRegistryKey = "HKEY_CURRENT_USER\Console"
    [Microsoft.Win32.Registry]::SetValue($ConsoleRegistryKey, $valueName, $size)

    return $result;
}

function SetRegistryColor
{
    param (
        [string] $valueName,
        [string] $colorValue
    )

    # parse the color, swap the red and blue values while applying an alpha of 0, and convert the result to an int
    [System.Drawing.Color] $rgb = [System.Drawing.ColorTranslator]::FromHtml($colorValue)
    [System.Drawing.Color] $bgr = [System.Drawing.Color]::FromArgb(0, $rgb.B, $rgb.G, $rgb.R)
    [int] $color = $bgr.ToArgb()
    
    [string] $ConsoleRegistryKey = "HKEY_CURRENT_USER\Console"
    [Microsoft.Win32.Registry]::SetValue($ConsoleRegistryKey, $valueName, $color)

    return $converted
}

Main