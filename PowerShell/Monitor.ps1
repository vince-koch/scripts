$ErrorActionPreference = "Stop"

Add-Type -Path "$PSScriptRoot\Monitor-*.cs" -ReferencedAssemblies System.Drawing, System.Windows.Forms

$screens = [System.Windows.Forms.Screen]::AllScreens
$monitorIndex = Console-Menu -Items $screens -ItemsProperty { param ($screen) "$($screen.DeviceName) [$($screen.Bounds.Width)x$($screen.Bounds.Height)]" } -Title "Select Monitor" -ReturnIndex

if ($monitorIndex -ne $null)
{
    [Monitor]::MoveWindowsTo($monitorIndex)
    [Monitor]::SetPrimary($monitorIndex)
}