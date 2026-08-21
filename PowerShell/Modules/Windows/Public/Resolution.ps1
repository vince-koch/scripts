<#
.SYNOPSIS
    Provides interactive Windows display resolution controls.
.DESCRIPTION
    Defines Set-Resolution and its private display-selection helpers.
#>
$modulesRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $modulesRoot 'Linq\Linq.psm1') -DisableNameChecking -ErrorAction Stop

Add-Type -AssemblyName System.Windows.Forms

if (-not ('NativeMethods' -as [type])) {
    Add-Type @"
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Runtime.InteropServices;

    [StructLayout(LayoutKind.Sequential)]
    public struct DEVMODE1
    {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public short dmOrientation;
        public short dmPaperSize;
        public short dmPaperLength;
        public short dmPaperWidth;
        public short dmScale;
        public short dmCopies;
        public short dmDefaultSource;
        public short dmPrintQuality;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;

        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;
        public short dmLogPixels;
        public short dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
        public int dmICMMethod;
        public int dmICMIntent;
        public int dmMediaType;
        public int dmDitherType;
        public int dmReserved1;
        public int dmReserved2;
        public int dmPanningWidth;
        public int dmPanningHeight;
    }

    public struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    public class OperationResult
    {
        public bool WasSuccessful { get; set; }
        public string ErrorMessage { get; set; }
        
        public static OperationResult Success()
        {
            return new OperationResult { WasSuccessful = true };
        }

        public static OperationResult Error(string format, params object[] args)
        {
            return new OperationResult { WasSuccessful = false, ErrorMessage = string.Format(format, args) }; 
        }
    }

    public static class NativeMethods
    {
        public static RECT GetForegroundWindowRect()
        {
            var rect = new RECT();
            var hwnd = User32.GetForegroundWindow();
            User32.GetWindowRect(hwnd, out rect);
            return rect;
        }

        public static DEVMODE1 GetCurrentDisplayMode(string deviceName)
        {
            var dm = CreateDevMode1();
            if (User32.EnumDisplaySettings(deviceName, User32.ENUM_CURRENT_SETTINGS, ref dm) != 0)
            {
                return dm;
            }

            throw new Exception(string.Format("Unable to get current display mode for monitor {0}", deviceName));
        }

        public static OperationResult ApplyDisplayMode(DEVMODE1 dm)
        {
            var result = User32.ChangeDisplaySettings(ref dm, User32.CDS_TEST);
            if (result == User32.DISP_CHANGE_FAILED)
            {
                return OperationResult.Error("Failed to apply display mode");
            }

            result = User32.ChangeDisplaySettings(ref dm, User32.CDS_UPDATEREGISTRY); 
            switch (result)
            {
                case User32.DISP_CHANGE_SUCCESSFUL: 
                    return OperationResult.Success();

                case User32.DISP_CHANGE_RESTART: 
                    return OperationResult.Error("You need to reboot for the change to take effect"); 
            
                default:
                    return OperationResult.Error("Failed to apply display mode");
            }
        }

        public static DEVMODE1[] GetAllDisplayModes(string deviceName)
        {
            var index = 0;
            var list = new List<DEVMODE1>();

            var dm = CreateDevMode1();
            while (User32.EnumDisplaySettings(deviceName, index, ref dm) != 0)
            {
                list.Add(dm);
                index++;
                dm = CreateDevMode1();
            }

            return list.ToArray();
        }

        private static DEVMODE1 CreateDevMode1()
        {
            DEVMODE1 dm = new DEVMODE1();
            dm.dmDeviceName = new String(new char[32]);
            dm.dmFormName = new String(new char[32]);
            dm.dmSize = (short)Marshal.SizeOf(dm);
            return dm;
        }

        private static class User32
        {
            [DllImport("user32.dll")]
            public static extern IntPtr GetForegroundWindow();

            [DllImport("user32.dll")]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

            [DllImport("user32.dll")] 
            public static extern int ChangeDisplaySettings(ref DEVMODE1 devMode, int flags); 

            [DllImport("user32.dll")]
            public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE1 devMode);

            public const int ENUM_CURRENT_SETTINGS = -1; 
            public const int CDS_UPDATEREGISTRY = 0x01; 
            public const int CDS_TEST = 0x02; 
            public const int DISP_CHANGE_SUCCESSFUL = 0; 
            public const int DISP_CHANGE_RESTART = 1; 
            public const int DISP_CHANGE_FAILED = -1; 
        }
    }
"@
}

function Screen-ContainsRect
{
    param ($screen, [RECT] $rect)

    [bool] $l = $rect.Left -gt $screen.Bounds.X
    [bool] $t = $rect.Top -gt $screen.Bounds.Y
    [bool] $r = $rect.Right -lt $screen.Bounds.X + $screen.Bounds.Width
    [bool] $b = $rect.Bottom -lt $screen.Bounds.Y + $screen.Bounds.Height
    [bool] $isOnScreen = $l -and $t -and $r -and $b
    # Write-Host "isOnScreen = $($l) $($t) $($r) $($b) = $($isOnScreen)"

    return $isOnScreen
}

function Screen-Select
{
    param ([RECT] $rect)

    $screens = [System.Windows.Forms.Screen]::AllScreens
    if ($screens.Length -eq 1)
    {
        return $screens[0]
    }

    $undetermined = ""
    $currentScreen = $screens | Where-Object { Screen-ContainsRect $_ $rect } | Select-Object -First 1
    if ($null -eq $currentScreen)
    {
        $undetermined = "(Unable to determine current screen)"
    }    

    $message = "Select a display $undetermined".Trim()
    $selectedScreen = Read-SpectreSelection `
        -Message $message `
        -Choices $screens `
        -ChoiceLabelProperty {
            "$($_.DeviceName.TrimStart('\', '.')) [$($_.Bounds.Width)x$($_.Bounds.Height)]"
        } `
        -Color 'Cyan1'

    if ($null -eq $selectedScreen)
    {
        Write-Host "No screen selected" -ForegroundColor Red
        return $null
    }

    return $selectedScreen
}

function Screen-WriteMode
{
    param ([DEVMODE1] $mode, [string] $label = $null)
    Write-Host "$($label)$(Screen-DescribeMode $mode)"
}

function Screen-DescribeMode
{
    param ([DEVMODE1] $mode)
    return "$($mode.dmPelsWidth)x$($mode.dmPelsHeight) @$($mode.dmDisplayFrequency)Hz $($mode.dmBitsPerPel)bpp"
}

function Screen-SelectResolution
{
    param ($screen)

    $currentMode = [NativeMethods]::GetCurrentDisplayMode($screen.DeviceName)
    $allModes = [NativeMethods]::GetAllDisplayModes($screen.DeviceName)
    $uniqueModes = $allModes `
        | Where-Object {$_.dmDisplayFrequency -eq $currentMode.dmDisplayFrequency} `
        | Where-Object {$_.dmBitsPerPel -eq $currentMode.dmBitsPerPel} `
        | Linq-DistinctBy {Screen-DescribeMode $_}

    $uniqueModes = $uniqueModes | Sort-Object {$_.dmPelsWidth} -Descending
    $selectedMode = Read-SpectreSelection `
        -Message 'Select a resolution' `
        -Choices $uniqueModes `
        -ChoiceLabelProperty { Screen-DescribeMode $_ } `
        -Color 'Cyan1'

    if ($null -ne $selectedMode)
    {
        return $selectedMode
    }

    Write-Host "No resolution selected" -ForegroundColor Red
    return $null
}

function Set-Resolution {
    Import-Module PwshSpectreConsole -ErrorAction Stop

    $rect = [NativeMethods]::GetForegroundWindowRect()
    $screen = Screen-Select $rect
    if ($null -eq $screen) { return }

    $mode = Screen-SelectResolution $screen
    if ($null -eq $mode) { return }

    $result = [NativeMethods]::ApplyDisplayMode($mode)
    if ($result.WasSuccessful -eq $true)
    {
        Write-Host
        Write-Host "Resolution updated" -ForegroundColor Green
    }
    else
    {
        Write-Host
        Write-Host "$($result.ErrorMessage)" -ForegroundColor Red
    }
}
