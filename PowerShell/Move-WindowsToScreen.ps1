# https://stackoverflow.com/questions/41208197/how-can-i-use-add-type-to-add-c-sharp-code-with-system-windows-forms-namespace

Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

namespace MoveWindows
{
    public class Program
    {
        internal class NativeMethods
        {
            internal class PInvoke
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

                [StructLayout(LayoutKind.Sequential)]
                public struct RECT
                {
                    public int Left;
                    public int Top;
                    public int Right;
                    public int Bottom;
                }

                [DllImport("user32.dll", SetLastError = true)]
                public static extern bool GetWindowRect(IntPtr hwnd, out RECT lpRect);

                public const uint SWP_NOZORDER = 0x0004;

                [DllImport("user32.dll", SetLastError = true)]
                public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, UInt32 uFlags);

                [DllImport("user32.dll", SetLastError = true)]
                public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

                [DllImport("kernel32.dll")]
                public static extern IntPtr GetConsoleWindow();
            }

            private static string GetText(IntPtr handle)
            {
                int length = PInvoke.GetWindowTextLength(handle);
                var builder = new StringBuilder(length + 1);
                PInvoke.GetWindowText(handle, builder, builder.Capacity);

                return builder.ToString();
            }

            private static IntPtr[] GetTopLevelWindows()
            {
                var handles = new List<IntPtr>();

                PInvoke.EnumWindows(
                    (IntPtr handle, IntPtr lparam) =>
                    {
                        if (PInvoke.IsWindowVisible(handle) && !string.IsNullOrWhiteSpace(GetText(handle)))
                        {
                            handles.Add(handle);
                        }

                        return true;
                    },
                    IntPtr.Zero);

                return handles.ToArray();
            }

            internal static void MoveWindowsToScreen(Screen targetScreen)
            {
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
                    PInvoke.RECT sourceRect;
                    PInvoke.GetWindowRect(handle, out sourceRect);

                    // transform the current rectangle to target coordinates
                    var targetRect = new PInvoke.RECT
                    {
                        Left = (int)((sourceRect.Left - sourceScreen.Bounds.Left) * scaleX) + targetScreen.Bounds.Left,
                        Top = (int)((sourceRect.Top - sourceScreen.Bounds.Top) * scaleY) + targetScreen.Bounds.Top,
                        Right = (int)((sourceRect.Right - sourceScreen.Bounds.Left) * scaleX) + targetScreen.Bounds.Left,
                        Bottom = (int)((sourceRect.Bottom - sourceScreen.Bounds.Top) * scaleY) + targetScreen.Bounds.Top
                    };

                    // apply the target dimensions but don't change z order
                    PInvoke.SetWindowPos(
                        handle, 
                        IntPtr.Zero, 
                        targetRect.Left, 
                        targetRect.Top, 
                        targetRect.Right - targetRect.Left, 
                        targetRect.Bottom - targetRect.Top, 
                        PInvoke.SWP_NOZORDER);
                }
            }
        }

        private static Screen SelectScreenFromInput(string input)
        {
            int result;
            if (int.TryParse(input, out result)
                && result > 0
                && result <= Screen.AllScreens.Length)
            {
                return Screen.AllScreens[result - 1];
            }

            return null;
        }

        private static Screen SelectScreen()
        {
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("Select Screen: ");
            Console.ResetColor();

            for (var i = 0; i < Screen.AllScreens.Length; i++)
            {
                var screen = Screen.AllScreens[i];
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.Write(string.Format("    {0}", i + 1));
                Console.ResetColor();
                Console.WriteLine(": {0} {1} {2}", screen.DeviceName, screen.Bounds, screen.Primary ? "Primary" : string.Empty);
            }

            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.Write("Choice> ");
            Console.ResetColor();

            while (true)
            {
                Console.TreatControlCAsInput = true;
                var keyInfo = Console.ReadKey(true);

                if (keyInfo.Key == ConsoleKey.Escape
                    || (keyInfo.Key == ConsoleKey.C && (keyInfo.Modifiers & ConsoleModifiers.Control) != 0))
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("Cancelled");
                    Console.ResetColor();
                    return null;
                }

                var screen = SelectScreenFromInput(keyInfo.KeyChar.ToString());
                if (screen != null)
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine(screen.DeviceName);
                    Console.ResetColor();
                    return screen;
                }

                Console.Beep();
            }
        }

        [STAThread]
        public static void Main(string[] args)
        {
            Screen screen = null;

            if (Screen.AllScreens.Length < 2)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("ERROR: You do not have multiple monitors attached?");
                Console.ResetColor();
                return;
            }

            if (args.Length == 1)
            {
                screen = SelectScreenFromInput(args[0]);
            }

            if (screen == null)
            {
                screen = SelectScreen();
            }
            
            if (screen != null)
            {
                NativeMethods.MoveWindowsToScreen(screen);
            }
        }
    }
}
"@ -ReferencedAssemblies System.Drawing, System.Windows.Forms

[MoveWindows.Program]::Main($args)