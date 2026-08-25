function Install-WindowsTerminalHotkeys {
    <#
    .SYNOPSIS
        Installs PSReadLine shortcuts for Windows Terminal tools.
    #>
    [CmdletBinding()]
    param()

    if (-not (Is-WindowsTerminal)) { return }
    if (-not (Get-Command Set-PSReadLineKeyHandler -ErrorAction Ignore)) { return }

    Set-PSReadLineKeyHandler `
        -Chord 'Ctrl+Alt+w' `
        -BriefDescription 'ToggleTerminalBackground' `
        -LongDescription 'Toggle the Windows Terminal background image' `
        -ScriptBlock {
            param($key, $arg)
            Toggle-WindowsTerminalBackground -Quiet
        }

    Set-PSReadLineKeyHandler `
        -Chord 'Ctrl+Alt+Shift+w' `
        -BriefDescription 'WindowsTerminalMenu' `
        -LongDescription 'Open the Windows Terminal tools menu' `
        -ScriptBlock {
            param($key, $arg)

            $escape = [char]27

            try {
                Write-Host "$escape[?1049h$escape[2J$escape[H" -NoNewline
                $null = winterm
            }
            finally {
                Write-Host "$escape[?1049l" -NoNewline
            }
        }
}
