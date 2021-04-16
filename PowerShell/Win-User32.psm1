# Import-Module $PSScriptRoot\Win-User32.psm1 -DisableNameChecking -Force

Add-Type -AssemblyName System.Drawing

Add-Type @"
    using System;
    using System.Runtime.InteropServices;

    public struct RECT
    {
        public int Left;   // x position of upper-left corner
        public int Top;    // y position of upper-left corner
        public int Right;  // x position of lower-right corner
        public int Bottom; // y position of lower-right corner
    }

    public static class User32
    {
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll")]
        public static extern IntPtr GetWindowLong(IntPtr hWnd, int nIndex);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool PostMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);

        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll", EntryPoint="SetWindowLong")]
        public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

        [DllImport("user32.dll")]
        public static extern void SetWindowPos(IntPtr hwnd, IntPtr hwndInsertAfter, int X, int Y, int width, int height, uint flags);

        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    }
"@

Import-Module $PSScriptRoot\Flags.psm1 -DisableNameChecking -Force

############################################################################################
# Get-ForegroundWindow
############################################################################################
function Get-ForegroundWindow {
    return [User32]::GetForegroundWindow()
}

############################################################################################
# Get-WindowLong
############################################################################################
function Get-WindowLong {
    param (
        [Parameter(Mandatory=$true)]
        [IntPtr] $Handle,

        [Parameter()]
        [int] $Code
    )

    return [User32]::GetWindowLong($Handle, $Code)
}

############################################################################################
# Get-WindowRect
############################################################################################
function Get-WindowRect {
    param (
        [Parameter(Mandatory=$true)]
        [IntPtr] $Handle
    )

    $rect = New-Object RECT
    $wasSuccessful = [User32]::GetWindowRect($Handle, [ref] $rect)
    if ($wasSuccessful -eq $false)
    {
        return [System.Drawing.Rectangle]::Empty
    }

    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top
    [System.Drawing.Rectangle] $result = New-Object System.Drawing.Rectangle @($rect.Left, $rect.Top, $width, $height)

    return $result
}

############################################################################################
# Post-Message
############################################################################################
function Post-Message {
    param (
        [Parameter(Mandatory=$true)]
        [IntPtr] $Handle,

        [Parameter(Mandatory=$true)]
        [IntPtr] $Msg,

        [Parameter(Mandatory=$true)]
        [IntPtr] $wParam,

        [Parameter(Mandatory=$true)]
        [IntPtr] $lParam
    )

    return [User32]::PostMessage($Handle, $Msg, $wParam, $lParam)
}

############################################################################################
# Set-ForegroundWindow
############################################################################################
function Set-ForegroundWindow {
    param (
        [Parameter(Mandatory=$true)]
        [IntPtr] $Handle
    )

    return [User32]::SetForegroundWindow($Handle)
}

############################################################################################
# Set-WindowLong
############################################################################################
function Set-WindowLong {
    param (
        [Parameter(Mandatory=$true)]
        [IntPtr] $Handle,

        [Parameter(Mandatory=$true)]
        [int] $Code,

        [Parameter(Mandatory=$true)]
        [int] $Value
    )

    return [User32]::SetWindowLong($Handle, $Code, $Value)
}

############################################################################################
# Set-WindowPos
############################################################################################
function Set-WindowPos {
    param (
        [Parameter()]
        [IntPtr] $Handle,
        
        [Parameter()]
        [IntPtr] $HandleInsertAfter,
        
        [Parameter()]
        [int] $X, 
        
        [Parameter()]
        [int] $Y, 
        
        [Parameter()]
        [int] $Width,
        
        [Parameter()]
        [int] $Height,

        [Parameter()]
        [int] $SetWindowPosFlags
    )

    [User32]::SetWindowPos($Handle, $HandleInsertAfter, $X, $Y, $Width, $Height, $SetWindowPosFlags)
}

############################################################################################
# EXAMPLE
#   (Get-Process -Name notepad).MainWindowHandle | foreach { Show-Window MAXIMIZE $_ }
############################################################################################
function Show-Window {
    param(
        [Parameter(Mandatory=$true)]
        $Handle,

        [Parameter()]
        [int] $ShowWindowFlags
    )

    write-host "show-window flags=$($SetWindowPosFlags)"
    return [User32]::ShowWindow($Handle, $SetWindowPosFlags)
}

############################################################################################
# CUSTOM FUNCTIONS
############################################################################################
function Get-ScreenFromRectangle {
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

############################################################################################
# FLAGS
############################################################################################
function Get-Flags {
    [Hashtable] $GetWindowLongFlags = @{
        GWL_EXSTYLE = -20   # Retrieves the extended window styles.
        GWL_HINSTANCE = -6  # Retrieves a handle to the application instance.
        GWL_HWNDPARENT = -8 # Retrieves a handle to the parent window, if any.
        GWL_ID = -12        # Retrieves the identifier of the window.
        GWL_STYLE = -16     # Retrieves the window styles.
        GWL_USERDATA = -21  # Retrieves the user data associated with the window. This data is intended for use by the application that created the window. Its value is initially zero.
        GWL_WNDPROC = -4    # Retrieves the address of the window procedure, or a handle representing the address of the window procedure. You must use the CallWindowProc function to call the window procedure.         
    }

    [Hashtable] $HwndFlags = @{
        HWND_BOTTOM = [IntPtr]1     # Places the window at the bottom of the Z order. If the hWnd parameter identifies a topmost window, the window loses its topmost status and is placed at the bottom of all other windows.
        HWND_NOTOPMOST = [IntPtr]-2 # Places the window above all non-topmost windows (that is, behind all topmost windows). This flag has no effect if the window is already a non-topmost window.
        HWND_TOP = [IntPtr]0        # Places the window at the top of the Z order.
        HWND_TOPMOST = [IntPtr]-1   # Places the window above all non-topmost windows. The window maintains its topmost position even when it is deactivated.
    }

    [Hashtable] $SystemCommandFlags = @{
        SC_CLOSE = 0xF060 # Closes the window.
        SC_CONTEXTHELP = 0xF180 # Changes the cursor to a question mark with a pointer. If the user then clicks a control in the dialog box, the control receives a WM_HELP message.
        SC_DEFAULT = 0xF160 # Selects the default item; the user double-clicked the window menu.
        SC_HOTKEY = 0xF150 # Activates the window associated with the application-specified hot key. The lParam parameter identifies the window to activate.
        SC_HSCROLL = 0xF080 # Scrolls horizontally.
        SCF_ISSECURE = 0x00000001 # Indicates whether the screen saver is secure.
        SC_KEYMENU = 0xF100 # Retrieves the window menu as a result of a keystroke. For more information, see the Remarks section.
        SC_MAXIMIZE = 0xF030 # Maximizes the window.
        SC_MINIMIZE = 0xF020 # Minimizes the window.
        SC_MONITORPOWER = 0xF170 # Sets the state of the display. This command supports devices that have power-saving features, such as a battery-powered personal computer. The lParam parameter can have the following values: -1 (the display is powering on) 1 (the display is going to low power) 2 (the display is being shut off)
        SC_MOUSEMENU = 0xF090 # Retrieves the window menu as a result of a mouse click.
        SC_MOVE = 0xF010 # Moves the window.
        SC_NEXTWINDOW = 0xF040 # Moves to the next window.
        SC_PREVWINDOW = 0xF050 # Moves to the previous window.
        SC_RESTORE = 0xF120 # Restores the window to its normal position and size.
        SC_SCREENSAVE = 0xF140 # Executes the screen saver application specified in the [boot] section of the System.ini file.
        SC_SIZE = 0xF000 # Sizes the window.
        SC_TASKLIST = 0xF130 # Activates the Start menu.
        SC_VSCROLL = 0xF070 # Scrolls vertically.
    }

    [Hashtable] $ShowWindowFlags = @{
        SW_FORCEMINIMIZE = 11   # Minimizes a window, even if the thread that owns the window is not responding. This flag should only be used when minimizing windows from a different thread.
        SW_HIDE = 0             # Hides the window and activates another window.
        SW_MAXIMIZE = 3         # Maximizes the specified window.
        SW_MINIMIZE = 6         # Minimizes the specified window and activates the next top-level window in the Z order.
        SW_RESTORE = 9          # Activates and displays the window. If the window is minimized or maximized, the system restores it to its original size and position. An application should specify this flag when restoring a minimized window.
        SW_SHOW = 5             # Activates the window and displays it in its current size and position.
        SW_SHOWDEFAULT = 10     # Sets the show state based on the SW_ value specified in the STARTUPINFO structure passed to the CreateProcess function by the program that started the application.
        SW_SHOWMAXIMIZED = 3    # Activates the window and displays it as a maximized window.
        SW_SHOWMINIMIZED = 2    # Activates the window and displays it as a minimized window.
        SW_SHOWMINNOACTIVE = 7  # Displays the window as a minimized window. This value is similar to SW_SHOWMINIMIZED, except the window is not activated.
        SW_SHOWNA = 8           # Displays the window in its current size and position. This value is similar to SW_SHOW, except that the window is not activated.
        SW_SHOWNOACTIVATE = 4   # Displays a window in its most recent size and position. This value is similar to SW_SHOWNORMAL, except that the window is not activated.
        SW_SHOWNORMAL = 1       # Activates and displays a window. If the window is minimized or maximized, the system restores it to its original size and position. An application should specify this flag when displaying the window for the first time.    
    }

    [Hashtable] $SetWindowPosFlags = @{
        SWP_ASYNCWINDOWPOS = 0x4000 # If the calling thread and the thread that owns the window are attached to different input queues, the system posts the request to the thread that owns the window. This prevents the calling thread from blocking its execution while other threads process the request.
        SWP_DEFERERASE = 0x2000     # Prevents generation of the WM_SYNCPAINT message.
        SWP_DRAWFRAME = 0x0020      # Draws a frame (defined in the window's class description) around the window.
        SWP_FRAMECHANGED = 0x0020   # Applies new frame styles set using the SetWindowLong function. Sends a WM_NCCALCSIZE message to the window, even if the window's size is not being changed. If this flag is not specified, WM_NCCALCSIZE is sent only when the window's size is being changed.
        SWP_HIDEWINDOW = 0x0080     # Hides the window.
        SWP_NOACTIVATE = 0x0010     # Does not activate the window. If this flag is not set, the window is activated and moved to the top of either the topmost or non-topmost group (depending on the setting of the hWndInsertAfter parameter).
        SWP_NOCOPYBITS = 0x0100     # Discards the entire contents of the client area. If this flag is not specified, the valid contents of the client area are saved and copied back into the client area after the window is sized or repositioned.
        SWP_NOMOVE = 0x0002         # Retains the current position (ignores X and Y parameters).
        SWP_NOOWNERZORDER = 0x0200  # Does not change the owner window's position in the Z order.
        SWP_NOREDRAW = 0x0008       # Does not redraw changes. If this flag is set, no repainting of any kind occurs. This applies to the client area, the nonclient area (including the title bar and scroll bars), and any part of the parent window uncovered as a result of the window being moved. When this flag is set, the application must explicitly invalidate or redraw any parts of the window and parent window that need redrawing.
        SWP_NOREPOSITION = 0x0200   # Same as the SWP_NOOWNERZORDER flag.
        SWP_NOSENDCHANGING = 0x0400 # Prevents the window from receiving the WM_WINDOWPOSCHANGING message.
        SWP_NOSIZE = 0x0001         # Retains the current size (ignores the cx and cy parameters).
        SWP_NOZORDER = 0x0004       # Retains the current Z order (ignores the hWndInsertAfter parameter).
        SWP_SHOWWINDOW = 0x0040     # Displays the window.
    }

    [Hashtable] $WindowMessageConstants = @{
        WM_COMMAND = 0x0111
        WM_SYSCOMMAND = 0x0112
    }

    [Hashtable] $WindowStyleFlags = @{
        WS_BORDER = 0x00800000L # The window has a thin-line border.
        WS_CAPTION = 0x00C00000L # The window has a title bar (includes the WS_BORDER style).
        WS_CHILD = 0x40000000L # The window is a child window. A window with this style cannot have a menu bar. This style cannot be used with the WS_POPUP style.
        WS_CHILDWINDOW = 0x40000000L # Same as the WS_CHILD style.
        WS_CLIPCHILDREN = 0x02000000L # Excludes the area occupied by child windows when drawing occurs within the parent window. This style is used when creating the parent window.
        WS_CLIPSIBLINGS = 0x04000000L # Clips child windows relative to each other; that is, when a particular child window receives a WM_PAINT message, the WS_CLIPSIBLINGS style clips all other overlapping child windows out of the region of the child window to be updated. If WS_CLIPSIBLINGS is not specified and child windows overlap, it is possible, when drawing within the client area of a child window, to draw within the client area of a neighboring child window.
        WS_DISABLED = 0x08000000L # The window is initially disabled. A disabled window cannot receive input from the user. To change this after a window has been created, use the EnableWindow function.
        WS_DLGFRAME = 0x00400000L # The window has a border of a style typically used with dialog boxes. A window with this style cannot have a title bar.
        WS_GROUP = 0x00020000L # The window is the first control of a group of controls. The group consists of this first control and all controls defined after it, up to the next control with the WS_GROUP style. The first control in each group usually has the WS_TABSTOP style so that the user can move from group to group. The user can subsequently change the keyboard focus from one control in the group to the next control in the group by using the direction keys.  You can turn this style on and off to change dialog box navigation. To change this style after a window has been created, use the SetWindowLong function.
        WS_HSCROLL = 0x00100000L # The window has a horizontal scroll bar.
        WS_ICONIC = 0x20000000L # The window is initially minimized. Same as the WS_MINIMIZE style.
        WS_MAXIMIZE = 0x01000000L # The window is initially maximized.
        WS_MAXIMIZEBOX = 0x00010000L # The window has a maximize button. Cannot be combined with the WS_EX_CONTEXTHELP style. The WS_SYSMENU style must also be specified.
        WS_MINIMIZE = 0x20000000L # The window is initially minimized. Same as the WS_ICONIC style.
        WS_MINIMIZEBOX = 0x00020000L # The window has a minimize button. Cannot be combined with the WS_EX_CONTEXTHELP style. The WS_SYSMENU style must also be specified.
        WS_OVERLAPPED = 0x00000000L # The window is an overlapped window. An overlapped window has a title bar and a border. Same as the WS_TILED style.
        WS_POPUP = 0x80000000L # The window is a pop-up window. This style cannot be used with the WS_CHILD style.
        WS_SIZEBOX = 0x00040000L # The window has a sizing border. Same as the WS_THICKFRAME style.
        WS_SYSMENU = 0x00080000L # The window has a window menu on its title bar. The WS_CAPTION style must also be specified.
        WS_TABSTOP = 0x00010000L # The window is a control that can receive the keyboard focus when the user presses the TAB key. Pressing the TAB key changes the keyboard focus to the next control with the WS_TABSTOP style. You can turn this style on and off to change dialog box navigation. To change this style after a window has been created, use the SetWindowLong function. For user-created windows and modeless dialogs to work with tab stops, alter the message loop to call the IsDialogMessage function.
        WS_THICKFRAME = 0x00040000L # The window has a sizing border. Same as the WS_SIZEBOX style.
        WS_TILED = 0x00000000L # The window is an overlapped window. An overlapped window has a title bar and a border. Same as the WS_OVERLAPPED style.
        WS_VISIBLE = 0x10000000L # The window is initially visible. This style can be turned on and off by using the ShowWindow or SetWindowPos function.
        WS_VSCROLL = 0x00200000L # The window has a vertical scroll bar.
    }

    $WindowStyleFlags.WS_OVERLAPPEDWINDOW = $WindowStyleFlags.WS_OVERLAPPED -bor $WindowStyleFlags.WS_CAPTION -bor $WindowStyleFlags.WS_SYSMENU -bor $WindowStyleFlags.WS_THICKFRAME -bor $WindowStyleFlags.WS_MINIMIZEBOX -bor $WindowStyleFlags.WS_MAXIMIZEBOX # The window is an overlapped window. Same as the WS_TILEDWINDOW style.
    $WindowStyleFlags.WS_POPUPWINDOW = $WindowStyleFlags.WS_POPUP -bor $WindowStyleFlags.WS_BORDER -bor $WindowStyleFlags.WS_SYSMENU # The window is a pop-up window. The WS_CAPTION and WS_POPUPWINDOW styles must be combined to make the window menu visible.
    $WindowStyleFlags.WS_TILEDWINDOW = $WindowStyleFlags.WS_OVERLAPPED -bor $WindowStyleFlags.WS_CAPTION -bor $WindowStyleFlags.WS_SYSMENU -bor $WindowStyleFlags.WS_THICKFRAME -bor $WindowStyleFlags.WS_MINIMIZEBOX -bor $WindowStyleFlags.WS_MAXIMIZEBOX

    [Hashtable] $WindowStyleExFlags = @{
        WS_EX_ACCEPTFILES = 0x00000010L # The window accepts drag-drop files.
        WS_EX_APPWINDOW = 0x00040000L # Forces a top-level window onto the taskbar when the window is visible.
        WS_EX_CLIENTEDGE = 0x00000200L # The window has a border with a sunken edge.
        WS_EX_COMPOSITED = 0x02000000L # Paints all descendants of a window in bottom-to-top painting order using double-buffering. Bottom-to-top painting order allows a descendent window to have translucency (alpha) and transparency (color-key) effects, but only if the descendent window also has the WS_EX_TRANSPARENT bit set. Double-buffering allows the window and its descendents to be painted without flicker. This cannot be used if the window has a class style of either CS_OWNDC or CS_CLASSDC. Windows 2000: This style is not supported.
        WS_EX_CONTEXTHELP = 0x00000400L # The title bar of the window includes a question mark. When the user clicks the question mark, the cursor changes to a question mark with a pointer. If the user then clicks a child window, the child receives a WM_HELP message. The child window should pass the message to the parent window procedure, which should call the WinHelp function using the HELP_WM_HELP command. The Help application displays a pop-up window that typically contains help for the child window. WS_EX_CONTEXTHELP cannot be used with the WS_MAXIMIZEBOX or WS_MINIMIZEBOX styles.
        WS_EX_CONTROLPARENT = 0x00010000L # The window itself contains child windows that should take part in dialog box navigation. If this style is specified, the dialog manager recurses into children of this window when performing navigation operations such as handling the TAB key, an arrow key, or a keyboard mnemonic.
        WS_EX_DLGMODALFRAME = 0x00000001L # The window has a double border; the window can, optionally, be created with a title bar by specifying the WS_CAPTION style in the dwStyle parameter.
        WS_EX_LAYERED = 0x00080000 # The window is a layered window. This style cannot be used if the window has a class style of either CS_OWNDC or CS_CLASSDC. Windows 8: The WS_EX_LAYERED style is supported for top-level windows and child windows. Previous Windows versions support WS_EX_LAYERED only for top-level windows.
        WS_EX_LAYOUTRTL = 0x00400000L # If the shell language is Hebrew, Arabic, or another language that supports reading order alignment, the horizontal origin of the window is on the right edge. Increasing horizontal values advance to the left.
        WS_EX_LEFT = 0x00000000L # The window has generic left-aligned properties. This is the default.
        WS_EX_LEFTSCROLLBAR = 0x00004000L # If the shell language is Hebrew, Arabic, or another language that supports reading order alignment, the vertical scroll bar (if present) is to the left of the client area. For other languages, the style is ignored.
        WS_EX_LTRREADING = 0x00000000L # The window text is displayed using left-to-right reading-order properties. This is the default.
        WS_EX_MDICHILD = 0x00000040L # The window is a MDI child window.
        WS_EX_NOACTIVATE = 0x08000000L # A top-level window created with this style does not become the foreground window when the user clicks it. The system does not bring this window to the foreground when the user minimizes or closes the foreground window. The window should not be activated through programmatic access or via keyboard navigation by accessible technology, such as Narrator. To activate the window, use the SetActiveWindow or SetForegroundWindow function. The window does not appear on the taskbar by default. To force the window to appear on the taskbar, use the WS_EX_APPWINDOW style.
        WS_EX_NOINHERITLAYOUT = 0x00100000L # The window does not pass its window layout to its child windows.
        WS_EX_NOPARENTNOTIFY = 0x00000004L # The child window created with this style does not send the WM_PARENTNOTIFY message to its parent window when it is created or destroyed.
        WS_EX_NOREDIRECTIONBITMAP = 0x00200000L # The window does not render to a redirection surface. This is for windows that do not have visible content or that use mechanisms other than surfaces to provide their visual.
        WS_EX_RIGHT = 0x00001000L # The window has generic "right-aligned" properties. This depends on the window class. This style has an effect only if the shell language is Hebrew, Arabic, or another language that supports reading-order alignment; otherwise, the style is ignored. Using the WS_EX_RIGHT style for static or edit controls has the same effect as using the SS_RIGHT or ES_RIGHT style, respectively. Using this style with button controls has the same effect as using BS_RIGHT and BS_RIGHTBUTTON styles.
        WS_EX_RIGHTSCROLLBAR = 0x00000000L # The vertical scroll bar (if present) is to the right of the client area. This is the default.
        WS_EX_RTLREADING = 0x00002000L # If the shell language is Hebrew, Arabic, or another language that supports reading-order alignment, the window text is displayed using right-to-left reading-order properties. For other languages, the style is ignored.
        WS_EX_STATICEDGE = 0x00020000L # The window has a three-dimensional border style intended to be used for items that do not accept user input.
        WS_EX_TOOLWINDOW = 0x00000080L # The window is intended to be used as a floating toolbar. A tool window has a title bar that is shorter than a normal title bar, and the window title is drawn using a smaller font. A tool window does not appear in the taskbar or in the dialog that appears when the user presses ALT+TAB. If a tool window has a system menu, its icon is not displayed on the title bar. However, you can display the system menu by right-clicking or by typing ALT+SPACE.
        WS_EX_TOPMOST = 0x00000008L # The window should be placed above all non-topmost windows and should stay above them, even when the window is deactivated. To add or remove this style, use the SetWindowPos function.
        WS_EX_TRANSPARENT = 0x00000020L # The window should not be painted until siblings beneath the window (that were created by the same thread) have been painted. The window appears transparent because the bits of underlying sibling windows have already been painted. To achieve transparency without these restrictions, use the SetWindowRgn function.
        WS_EX_WINDOWEDGE = 0x00000100L # The window has a border with a raised edge.
    }

    $WindowStyleExFlags.WS_EX_OVERLAPPEDWINDOW = $WindowStyleExFlags.WS_EX_WINDOWEDGE -bor $WindowStyleExFlags.WS_EX_CLIENTEDGE # The window is an overlapped window.
    $WindowStyleExFlags.WS_EX_PALETTEWINDOW = $WindowStyleExFlags.WS_EX_WINDOWEDGE -bor $WindowStyleExFlags.WS_EX_TOOLWINDOW -bor $WindowStyleExFlags.WS_EX_TOPMOST # The window is palette window, which is a modeless dialog box that presents an array of commands.

    #[Hashtable[]] $tables = @($GetWindowLongFlags, $HwndFlags, $ShowWindowFlags, $SetWindowPosFlags, $WindowStyleFlags, $WindowStyleExFlags)
    #write-host $tables.Length
    #[Hashtable] $Flags = Merge-Hashtables $tables
    [Hashtable] $Flags = @{
        GWL = $GetWindowLongFlags
        Hwnd = $HwndFlags
        SC = $SystemCommandFlags
        SW = $ShowWindowFlags
        SWP = $SetWindowPosFlags
        WM = $WindowMessageConstants
        WS = $WindowStyleFlags
        WS_EX = $WindowStyleExFlags
    }

    return $Flags
}

############################################################################################
# EXPORTS
############################################################################################

# WinApi Functions
Export-ModuleMember -Function Get-ForegroundWindow
Export-ModuleMember -Function Get-WindowLong
Export-ModuleMember -Function Get-WindowRect
Export-ModuleMember -Function Set-ForegroundWindow
Export-ModuleMember -Function Set-WindowLong
Export-ModuleMember -Function Set-WindowPos
Export-ModuleMember -Function Show-Window

# Custom Functions
Export-ModuleMember -Function Get-ScreenFromRectangle

# Flags
Export-ModuleMember -Function Get-Flags