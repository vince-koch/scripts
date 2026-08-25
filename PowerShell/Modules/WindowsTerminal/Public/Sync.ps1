function Sync-WindowsTerminalToRegistry {
    [CmdletBinding(SupportsShouldProcess)] param()
    Add-Type -AssemblyName System.Drawing
    $settings = Get-WindowsTerminalSettings
    $theme = $settings.schemes | Where-Object name -eq $settings.profiles.defaults.colorScheme | Select-Object -First 1
    if (-not $theme) { throw 'Current Windows Terminal theme was not found.' }
    $names = 'black','blue','green','cyan','red','purple','yellow','white','brightBlack','brightBlue','brightGreen','brightCyan','brightRed','brightPurple','brightYellow','brightWhite'
    if (-not $PSCmdlet.ShouldProcess('HKCU\Console', "Synchronize theme '$($theme.name)'")) { return }
    for ($index = 0; $index -lt $names.Count; $index++) {
        $rgb = [Drawing.ColorTranslator]::FromHtml($theme.($names[$index]))
        $value = [Drawing.Color]::FromArgb(0, $rgb.B, $rgb.G, $rgb.R).ToArgb()
        [Microsoft.Win32.Registry]::SetValue('HKEY_CURRENT_USER\Console', "ColorTable$($index.ToString('00'))", $value)
    }
    [Microsoft.Win32.Registry]::SetValue('HKEY_CURRENT_USER\Console', 'WindowSize', ((65536 * 50) + 120))
}
