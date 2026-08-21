<#
.SYNOPSIS
    Provides Windows light and dark theme controls.
#>

# Load the API used to broadcast theme changes.
if (-not ("Windows.Win32.PInvoke" -as [type])) {
    Add-Type -Namespace Windows.Win32 -Name PInvoke -MemberDefinition @"
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern IntPtr SendMessageW(IntPtr hWnd, int Msg, int wParam, string lParam);
"@
}

function Set-WindowsTheme {
    param (
        [ValidateSet("Light", "Dark", "Toggle")]
        [string] $Theme = "Toggle"
    )

    # Registry paths
    $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

    if ($Theme -eq "Toggle") {
        $current = Get-ItemProperty -Path $key -Name "AppsUseLightTheme"
        $Theme = if ($current.AppsUseLightTheme -eq 1) { "Dark" } else { "Light" }
    }

    $appsTheme   = if ($Theme -eq "Light") { 1 } else { 0 }
    $systemTheme = if ($Theme -eq "Light") { 1 } else { 0 }

    # Set values
    Set-ItemProperty -Path $key -Name "AppsUseLightTheme" -Value $appsTheme
    Set-ItemProperty -Path $key -Name "SystemUsesLightTheme" -Value $systemTheme

    # Broadcast setting change (optional, helps some apps update immediately)
    $code = 0x001A
    $HWND_BROADCAST = [intptr]0xffff
    $WM_SETTINGCHANGE = $code
    $null = [void] [Windows.Win32.PInvoke]::SendMessageW($HWND_BROADCAST, $WM_SETTINGCHANGE, 0, "ImmersiveColorSet")
}

Set-Alias theme Set-WindowsTheme
