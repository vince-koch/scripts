function Show-WindowsTerminalThemeMenu {
    while ($true) {
        Write-WindowsTerminalCycleLine -Label 'Theme' -Name (Get-WindowsTerminalTheme)
        $key = [Console]::ReadKey($true).Key
        switch ($key) {
            { $_ -in 'P', 'LeftArrow' } { Move-WindowsTerminalTheme Previous 6>$null }
            { $_ -in 'N', 'RightArrow' } { Move-WindowsTerminalTheme Next 6>$null }
            { $_ -in 'X', 'Escape', 'Enter' } { Write-Host; return }
        }
    }
}

function Show-WindowsTerminalBackgroundMenu {
    $backgrounds = @(Get-WindowsTerminalBackgrounds)
    if ($backgrounds.Count -eq 0) {
        Write-Warning 'No bundled Windows Terminal backgrounds are available.'
        return
    }

    while ($true) {
        $currentPath = [string](Get-WindowsTerminalSettings).profiles.defaults.backgroundImage
        $currentIndex = [array]::FindIndex($backgrounds, [Predicate[object]] { param($item) $item.FullName -eq $currentPath })
        $currentName = if ($currentIndex -ge 0) { $backgrounds[$currentIndex].Name } elseif ($currentPath -eq 'desktopWallpaper') { 'desktop wallpaper' } elseif ($currentPath) { [IO.Path]::GetFileNameWithoutExtension($currentPath) } else { 'none' }
        Write-WindowsTerminalCycleLine -Label 'Background' -Name $currentName

        $key = [Console]::ReadKey($true).Key
        switch ($key) {
            { $_ -in 'P', 'LeftArrow' } {
                $currentIndex--; if ($currentIndex -lt 0) { $currentIndex = $backgrounds.Count - 1 }
                Set-WindowsTerminalBackground $backgrounds[$currentIndex].FullName 6>$null
            }
            { $_ -in 'N', 'RightArrow' } {
                $currentIndex++; if ($currentIndex -ge $backgrounds.Count) { $currentIndex = 0 }
                Set-WindowsTerminalBackground $backgrounds[$currentIndex].FullName 6>$null
            }
            { $_ -in 'X', 'Escape', 'Enter' } { Write-Host; return }
        }
    }
}

function Write-WindowsTerminalCycleLine {
    param(
        [string]$Label,
        [string]$Name
    )

    Write-Host "`r`e[2K" -NoNewline
    Write-Host $Label -ForegroundColor Magenta -NoNewline
    Write-Host '  •  ' -ForegroundColor DarkGray -NoNewline
    Write-Host '[P]' -ForegroundColor Cyan -NoNewline
    Write-Host ' Previous  ' -ForegroundColor DarkGray -NoNewline
    Write-Host '[N]' -ForegroundColor Cyan -NoNewline
    Write-Host ' Next  ' -ForegroundColor DarkGray -NoNewline
    Write-Host '[X]' -ForegroundColor Cyan -NoNewline
    Write-Host ' Exit  •  ' -ForegroundColor DarkGray -NoNewline
    Write-Host $Name -ForegroundColor Yellow -NoNewline
}

function Show-WindowsTerminalMenu {
    Import-Module PwshSpectreConsole -ErrorAction Stop
    while ($true) {
        $action = Read-SpectreSelection -Message 'Windows Terminal' -Choices @('Theme','Background','Color table','Open settings','Sync to registry','Exit') -Color Cyan1
        if (-not $action) { return }
        switch ($action) {
            'Theme' { Show-WindowsTerminalThemeMenu }
            'Background' { Show-WindowsTerminalBackgroundMenu }
            'Color table' { Write-WindowsTerminalColorTable }
            'Open settings' { Open-WindowsTerminalSettings }
            'Sync to registry' { if (Read-SpectreConfirm -Message 'Synchronize the current theme to HKCU\Console?' -DefaultAnswer n) { Sync-WindowsTerminalToRegistry } }
            'Exit' { return }
        }
    }
}
