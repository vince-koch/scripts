param (
    [IntPtr] $Handle,
    [switch] $IsFullScreen)

Add-Type -AssemblyName System.Windows.Forms
Import-Module $PSScriptRoot\Win-User32.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Flags.psm1 -DisableNameChecking -Force

# find remote desktop windows and select its primary screen
$processes = Get-Process mstsc
$process = $processes[0]
$rect = Get-WindowRect $process.MainWindowHandle 
$screen = Get-ScreenFromRectangle $rect

# force the remote desktop window into fullscreen mode
[Hashtable] $Flags = Get-Flags
$style = Get-WindowLong $process.MainWindowHandle $Flags.GWL.GWL_STYLE

write-host "IsFullScreen = $($IsFullScreen)"
if ($IsFullScreen -eq $true)
{
    $fullScreenStyle = Flags-Remove $style $Flags.WS.WS_OVERLAPPEDWINDOW
    $swpFlags = $Flags.SWP.SWP_NOOWNERZORDER -bor $Flags.SWP.SWP_FRAMECHANGED
    [IntPtr] $SC_MAXIMIZE = $Flags.SC.SC_MAXIMIZE
    [IntPtr] $ZERO = 0
    write-host "style=$($style)   fullScreenStyle=$($fullScreenStyle)"
    #$null = Set-WindowLong $process.MainWindowHandle $Flags.GWL.GWL_STYLE $fullScreenStyle 
    #$null = Set-WindowPos $process.MainWindowHandle $Flags.HWND.HWND_NOTOPMOST $screen.Bounds.Left $screen.Bounds.Top $screen.Bounds.Width $screen.Bounds.Height $swpFlags
    #$null = Post-Message $process.MainWindowHandle $Flags.WM.WM_COMMAND 0 
    $null = Post-Message $process.MainWindowHandle $Flags.WM.WM_SYSCOMMAND $SC_MAXIMIZE $ZERO

    #$null = Set-ForegroundWindow $process.MainWindowHandle 
    #$null = Set-WindowPos $process.MainWindowHandle $Flags.HWND_NOTOPMOST $screen.Bounds.Left $screen.Bounds.Top $screen.Bounds.Width $screen.Bounds.Height $Flags.SWP_SHOWWINDOW
    #$null = Show-Window $process.MainWindowHandle $Flags.SW_SHOWMAXIMIZED    
}
else
{
    [int] $normalStyle = Flags-Add $style $Flags.WS.WS_OVERLAPPEDWINDOW
    [IntPtr] $handleInsertAfter = 0
    [int] $swpFlags = $Flags.SWP.SWP_NOMOVE -bor $Flags.SWP.SWP_NOSIZE -bor $Flags.SWP.SWP_NOZORDER -bor $Flags.SWP.SWP_NOOWNERZORDER -bor $Flags.SWP.SWP_FRAMECHANGED
    write-host "style=$($style)   normalStyle=$($normalStyle)"
    $null = Set-WindowLong $process.MainWindowHandle $Flags.GWL.GWL_STYLE $normalStyle
    #SetWindowPlacement(hwnd, &g_wpPrev);
    $null = Set-WindowPos $process.MainWindowHandle $handleInsertAfter 0 0 0 0 $swpFlags           
}




# void FullscreenHandler::SetFullscreenImpl(bool fullscreen, bool for_metro) {
#   ScopedFullscreenVisibility visibility(hwnd_);

#   // Save current window state if not already fullscreen.
#   if (!fullscreen_) {
#     // Save current window information.  We force the window into restored mode
#     // before going fullscreen because Windows doesn't seem to hide the
#     // taskbar if the window is in the maximized state.
#     saved_window_info_.maximized = !!::IsZoomed(hwnd_);
#     if (saved_window_info_.maximized)
#       ::SendMessage(hwnd_, WM_SYSCOMMAND, SC_RESTORE, 0);
#     saved_window_info_.style = GetWindowLong(hwnd_, GWL_STYLE);
#     saved_window_info_.ex_style = GetWindowLong(hwnd_, GWL_EXSTYLE);
#     GetWindowRect(hwnd_, &saved_window_info_.window_rect);
#   }

#   fullscreen_ = fullscreen;

#   if (fullscreen_) {
#     // Set new window style and size.
#     SetWindowLong(hwnd_, GWL_STYLE,
#                   saved_window_info_.style & ~(WS_CAPTION | WS_THICKFRAME));
#     SetWindowLong(hwnd_, GWL_EXSTYLE,
#                   saved_window_info_.ex_style & ~(WS_EX_DLGMODALFRAME |
#                   WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE | WS_EX_STATICEDGE));

#     // On expand, if we're given a window_rect, grow to it, otherwise do
#     // not resize.
#     if (!for_metro) {
#       MONITORINFO monitor_info;
#       monitor_info.cbSize = sizeof(monitor_info);
#       GetMonitorInfo(MonitorFromWindow(hwnd_, MONITOR_DEFAULTTONEAREST),
#                      &monitor_info);
#       gfx::Rect window_rect(monitor_info.rcMonitor);
#       SetWindowPos(hwnd_, NULL, window_rect.x(), window_rect.y(),
#                    window_rect.width(), window_rect.height(),
#                    SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
#     }
#   } else {
#     // Reset original window style and size.  The multiple window size/moves
#     // here are ugly, but if SetWindowPos() doesn't redraw, the taskbar won't be
#     // repainted.  Better-looking methods welcome.
#     SetWindowLong(hwnd_, GWL_STYLE, saved_window_info_.style);
#     SetWindowLong(hwnd_, GWL_EXSTYLE, saved_window_info_.ex_style);

#     if (!for_metro) {
#       // On restore, resize to the previous saved rect size.
#       gfx::Rect new_rect(saved_window_info_.window_rect);
#       SetWindowPos(hwnd_, NULL, new_rect.x(), new_rect.y(),
#                    new_rect.width(), new_rect.height(),
#                    SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
#     }
#     if (saved_window_info_.maximized)
#       ::SendMessage(hwnd_, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
#   }
# }