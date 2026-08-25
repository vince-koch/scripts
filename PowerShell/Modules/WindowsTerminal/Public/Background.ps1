function Get-WindowsTerminalBackgrounds {
    <#
    .SYNOPSIS
        Lists background images bundled with the WindowsTerminal module.
    #>
    Get-ChildItem -LiteralPath $script:WindowsTerminalBackgroundsPath -File -ErrorAction SilentlyContinue |
        Where-Object Extension -in '.jpg', '.jpeg', '.png', '.gif' |
        Sort-Object BaseName |
        Select-Object @{ Name = 'Name'; Expression = { $_.BaseName } }, FullName, Extension
}

function Set-WindowsTerminalBackground {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Path,
        [ValidateRange(0.0, 1.0)][double]$Opacity = 0.2,
        [ValidateSet('none','fill','uniform','uniformToFill')][string]$StretchMode = 'uniformToFill',
        [ValidateSet('center','left','top','right','bottom','topLeft','topRight','bottomLeft','bottomRight')][string]$Alignment = 'center'
    )

    if ($Path -ne 'desktopWallpaper') {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            $matches = @(Get-WindowsTerminalBackgrounds | Where-Object { $_.Name -eq $Path -or [IO.Path]::GetFileName($_.FullName) -eq $Path })
            if ($matches.Count -ne 1) { throw "Background image not found: $Path" }
            $Path = $matches[0].FullName
        }
        else {
            $Path = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
        }
    }
    Update-WindowsTerminalDefaultProperties -Set @{
        backgroundImage = $Path
        backgroundImageOpacity = $Opacity
        backgroundImageStretchMode = $StretchMode
        backgroundImageAlignment = $Alignment
    }
    Write-Host 'Windows Terminal background set: ' -NoNewline
    Write-Host $Path -ForegroundColor Cyan
}

function Remove-WindowsTerminalBackground {
    [CmdletBinding(SupportsShouldProcess)] param()
    if ($PSCmdlet.ShouldProcess('profiles.defaults', 'Remove Windows Terminal background settings')) {
        Update-WindowsTerminalDefaultProperties -Remove @('backgroundImage','backgroundImageOpacity','backgroundImageStretchMode','backgroundImageAlignment')
        Write-Host 'Windows Terminal background removed.' -ForegroundColor Green
    }
}

function Toggle-WindowsTerminalBackground {
    <#
    .SYNOPSIS
        Toggles the default Windows Terminal background image off and on.
    .DESCRIPTION
        Uses backgroundImageOpacity so the selected image, alignment, and stretch
        settings remain intact. The last visible opacity is persisted per user.
    #>
    [CmdletBinding()]
    param([switch]$Quiet)

    $defaults = (Get-WindowsTerminalSettings).profiles.defaults
    if (-not $defaults.backgroundImage) {
        if (-not $Quiet) { Write-Warning 'No default Windows Terminal background is configured.' }
        return
    }

    $stateDirectory = Join-Path $env:LOCALAPPDATA 'PowerShell\WindowsTerminal'
    $statePath = Join-Path $stateDirectory 'state.json'
    $currentOpacity = if ($null -eq $defaults.backgroundImageOpacity) { 1.0 } else { [double]$defaults.backgroundImageOpacity }

    if ($currentOpacity -gt 0) {
        if (-not (Test-Path -LiteralPath $stateDirectory)) {
            New-Item -ItemType Directory -Path $stateDirectory -Force | Out-Null
        }
        @{ BackgroundImageOpacity = $currentOpacity } |
            ConvertTo-Json |
            Set-Content -LiteralPath $statePath
        Update-WindowsTerminalDefaultProperties -Set @{ backgroundImageOpacity = 0.0 }
        if (-not $Quiet) { Write-Host 'Windows Terminal background: off' -ForegroundColor DarkGray }
    }
    else {
        $opacity = 0.2
        if (Test-Path -LiteralPath $statePath -PathType Leaf) {
            $savedOpacity = (Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json).BackgroundImageOpacity
            if ($null -ne $savedOpacity -and [double]$savedOpacity -gt 0 -and [double]$savedOpacity -le 1) {
                $opacity = [double]$savedOpacity
            }
        }
        Update-WindowsTerminalDefaultProperties -Set @{ backgroundImageOpacity = $opacity }
        if (-not $Quiet) { Write-Host "Windows Terminal background: on ($opacity)" -ForegroundColor Green }
    }
}
