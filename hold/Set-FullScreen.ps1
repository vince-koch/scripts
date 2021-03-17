
# public class WinApi
# {
#     [DllImport("user32.dll", EntryPoint = "GetSystemMetrics")] public static extern int GetSystemMetrics(int which);

#     [DllImport("user32.dll")] public static extern void SetWindowPos(IntPtr hwnd, IntPtr hwndInsertAfter, int X, int Y, int width, int height, uint flags);        

#     private const int SM_CXSCREEN = 0;
#     private const int SM_CYSCREEN = 1;
#     private static IntPtr HWND_TOP = IntPtr.Zero;
#     private const int SWP_SHOWWINDOW = 64; // 0×0040

#     public static int ScreenX
#     {
#         get { return GetSystemMetrics(SM_CXSCREEN);}
#     }

#     public static int ScreenY
#     {
#         get { return GetSystemMetrics(SM_CYSCREEN);}
#     }

#     public static void SetWinFullScreen(IntPtr hwnd)
#     {
#         SetWindowPos(hwnd, HWND_TOP, 0, 0, ScreenX, ScreenY, SWP_SHOWWINDOW);
#     }
# }

# [IntPtr] $HWND_TOP = [IntPtr]::Zero
# [int] $SWP_SHOWWINDOW = 64

# Set-WindowPos $hWnd $HWND_TOP 0 0 ? ? $SWP_SHOWWINDOW

Add-Type -AssemblyName System.Windows.Forms
Import-Module $PSScriptRoot\Win-User32.psm1 -DisableNameChecking -Force

function Get-Screen {
    param (
        [System.Drawing.Rectangle] $rect
    )

    [double] $maxOverlapArea = -1
    [System.Windows.Forms.Screen] $maxOverlapScreen = $null

    foreach ($screen in [System.Windows.Forms.Screen]::AllScreens)
    {
        [System.Drawing.Rectangle] $overlap = [System.Drawing.Rectangle]::Intersect($screen.Bounds, $rect)
        [double] $area = $overlap.Width * $overlap.Height

        if ($area -gt $maxOverlapArea)
        {
            $maxOverlapArea = $area
            $maxOverlapScreen = $screen
        }
    }

    return $maxOverlapScreen
}

$processes = Get-Process mstsc
$process = $processes[0]

$rect = Get-WindowRect $process.MainWindowHandle 
$screen = Get-Screen $rect
$null = Set-ForegroundWindow $process.MainWindowHandle 
$null = Set-WindowPos $process.MainWindowHandle "HWND_NOTOPMOST" $screen.Bounds.Left $screen.Bounds.Top $screen.Bounds.Width $screen.Bounds.Height "SWP_SHOWWINDOW"
$null = Show-Window $process.MainWindowHandle [ShowWindowFlags]::SW_SHOWMAXIMIZED

$style = Get-WindowLong $process.MainWindowHandle "GWL_STYLE"

## make fullscreen window
    #   SetWindowLong(hwnd, GWL_STYLE,
    #                 dwStyle & ~WS_OVERLAPPEDWINDOW);
    #   SetWindowPos(hwnd, HWND_TOP,
    #                mi.rcMonitor.left, mi.rcMonitor.top,
    #                mi.rcMonitor.right - mi.rcMonitor.left,
    #                mi.rcMonitor.bottom - mi.rcMonitor.top,
    #                SWP_NOOWNERZORDER | SWP_FRAMECHANGED);

## unmake fullscreen
    # SetWindowLong(hwnd, GWL_STYLE,
    #               dwStyle | WS_OVERLAPPEDWINDOW);
    # SetWindowPlacement(hwnd, &g_wpPrev);
    # SetWindowPos(hwnd, NULL, 0, 0, 0, 0,
    #              SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER |
    #              SWP_NOOWNERZORDER | SWP_FRAMECHANGED);