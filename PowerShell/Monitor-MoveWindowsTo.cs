// https://stackoverflow.com/questions/41208197/how-can-i-use-add-type-to-add-c-sharp-code-with-system-windows-forms-namespace

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

public static partial class Monitor
{
    public static void MoveWindowsTo(uint id)
    {
        MoveWindowsTo(Screen.AllScreens[id]);
    }

    internal static void MoveWindowsTo(Screen targetScreen)
    {
        Console.WriteLine("Moving all windows to {0}", targetScreen.DeviceName);

        var handles = GetTopLevelWindows();
        foreach (var handle in handles)
        {
            // find out where the window is currently
            var sourceScreen = Screen.FromHandle(handle);
            if (sourceScreen == targetScreen)
            {
                continue;
            }

            // calculate the scale factor
            float scaleX = (float)targetScreen.Bounds.Width / (float)sourceScreen.Bounds.Width;
            float scaleY = (float)targetScreen.Bounds.Height / (float)sourceScreen.Bounds.Height;

            // get the current location of the window
            RECT sourceRect;
            NativeMethods.GetWindowRect(handle, out sourceRect);

            // transform the current rectangle to target coordinates
            var targetRect = new RECT
            {
                Left = (int)((sourceRect.Left - sourceScreen.Bounds.Left) * scaleX) + targetScreen.Bounds.Left,
                Top = (int)((sourceRect.Top - sourceScreen.Bounds.Top) * scaleY) + targetScreen.Bounds.Top,
                Right = (int)((sourceRect.Right - sourceScreen.Bounds.Left) * scaleX) + targetScreen.Bounds.Left,
                Bottom = (int)((sourceRect.Bottom - sourceScreen.Bounds.Top) * scaleY) + targetScreen.Bounds.Top
            };

            // apply the target dimensions but don't change z order
            NativeMethods.SetWindowPos(
                handle,
                IntPtr.Zero,
                targetRect.Left,
                targetRect.Top,
                targetRect.Right - targetRect.Left,
                targetRect.Bottom - targetRect.Top,
                SWP_NOZORDER);
        }
    }

    private static string GetText(IntPtr handle)
    {
        int length = NativeMethods.GetWindowTextLength(handle);
        var builder = new StringBuilder(length + 1);
        NativeMethods.GetWindowText(handle, builder, builder.Capacity);

        return builder.ToString();
    }

    private static IntPtr[] GetTopLevelWindows()
    {
        var handles = new List<IntPtr>();

        NativeMethods.EnumWindows(
            (IntPtr handle, IntPtr lparam) =>
            {
                if (NativeMethods.IsWindowVisible(handle) && !string.IsNullOrWhiteSpace(GetText(handle)))
                {
                    handles.Add(handle);
                }

                return true;
            },
            IntPtr.Zero);

        return handles.ToArray();
    }

    public static partial class NativeMethods
    {
        public delegate bool EnumWindowsProc(IntPtr handle, IntPtr lparam);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lparam);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool IsWindowVisible(IntPtr hWnd);

        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern int GetWindowTextLength(IntPtr hWnd);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool GetWindowRect(IntPtr hwnd, out RECT lpRect);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, UInt32 uFlags);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
    }

    public const uint SWP_NOZORDER = 0x0004;

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
}
