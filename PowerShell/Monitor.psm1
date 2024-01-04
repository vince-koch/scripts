[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

Add-Type -Path "$PSScriptRoot\Monitor-*.cs" -ReferencedAssemblies System.Collections, System.Console, System.Drawing, System.Drawing.Primitives, System.Windows.Forms

function Monitor-Select {
    param (
        [string] $identifier = $null
    )

    $screens = [System.Windows.Forms.Screen]::AllScreens

    [int] $index = 0
    [bool] $result = [int]::TryParse($identifier, [ref]$index)
    if ($result -eq $true) {
        $index = $index - 1
        if ($index -ge 0 -and $index -lt $screens.Length) {
            return $screens[$index]
        }
    }

    # run a menu to select a monitor
    Write-Host ""
    $monitorIndex = Console-Menu `
        -ReturnIndex `
        -Title "Select Monitor" `
        -Items $screens `
        -ItemsProperty { param ($screen) "$($screen.DeviceName) [$($screen.Bounds.Width)x$($screen.Bounds.Height)]" }
    
    return $screens[$monitorIndex]
}

# monitor primary identifier
function Monitor-MoveWindowsTo {
    param (
        [string] $identifier = $null
    )

    $screen = Monitor-Select $identifier
    if ($screen -eq $null) {
        return
    }

    Write-Host ""
    Write-Host "Moving windows to monitor " -NoNewLine
    Write-Host "$($screen.DeviceName)" -ForegroundColor Cyan
    [Monitor]::MoveWindowsTo($screen)
}

# monitor scale identifier scaleFactor
function Monitor-Scale {
    $scalingItems = @(
        [System.Tuple]::Create("Recommended", "0") 
        [System.Tuple]::Create("Recommended +1 step", "1") 
        [System.Tuple]::Create("Recommended +2 steps", "2") 
        [System.Tuple]::Create("Recommended +3 steps", "3") 
    )

    Write-Host ""
    $scaling = Console-Menu `
        -Title "Select Scaling" `
        -Items $scalingItems `
        -ItemsProperty { param ($item) "$($item.Item1)" }

    [int] $scaleFactor = [int]::Parse($scaling.Item2)

    Write-Host ""
    Write-Host "Scaling monitors to " -NoNewLine
    Write-Host "$scaleFactor" -ForegroundColor Cyan
    [Monitor]::Scale($scaleFactor)
}

# monitor primary identifier
function Monitor-SetPrimary {
    param (
        [string] $identifier = $null
    )

    $screen = Monitor-Select $identifier
    if ($screen -eq $null) {
        return
    }

    Write-Host ""
    Write-Host "Setting primary monitor to " -NoNewLine
    Write-Host "$($screen.DeviceName)" -ForegroundColor Cyan
    
    [Monitor]::SetPrimary($monitorIndex)
}

function Monitor-Main {
    param (
        [string] $command  = $null,
        [string] $identifier = $null
    )

    switch ($command) {
        "move"              { Monitor-MoveWindowsTo $identifier }
        "move-to"           { Monitor-MoveWindowsTo $identifier }
        "move-windows-to"   { Monitor-MoveWindowsTo $identifier }
        "moveTo"            { Monitor-MoveWindowsTo $identifier }
        "moveWindowsTo"     { Monitor-MoveWindowsTo $identifier }

        "scale"             { Monitor-Scale }
        
        "primary"           { Monitor-SetPrimary $identifier }
        "set-primary"       { Monitor-SetPrimary $identifier }
        "setPrimary"        { Monitor-SetPrimary $identifier }

        default {
            Write-Host ""
            $command = Console-Menu `
                -Title "Select Command" `
                -Items @("moveTo", "scale", "primary") `

            switch ($command) {
                "moveTo"    { Monitor-MoveWindowsTo $identifier }
                "scale"     { Monitor-Scale }
                "primary"   { Monitor-SetPrimary $identifier }
                default     {  Write-Host "Cancelled [${command}]" -ForegroundColor Red }
            }
        }
    }
}

Set-Alias -Name monitor -Value Monitor-Main

Export-ModuleMember -Function Monitor-Main -Alias monitor