function Open-WindowsTerminalSettings {
    <#
    .SYNOPSIS
        Opens the active Windows Terminal settings file in its registered editor.
    #>
    [CmdletBinding()]
    param()

    if (-not (Test-Path -LiteralPath $script:WindowsTerminalSettingsPath -PathType Leaf)) {
        throw "Windows Terminal settings not found: $script:WindowsTerminalSettingsPath"
    }

    Start-Process -FilePath $script:WindowsTerminalSettingsPath
}
