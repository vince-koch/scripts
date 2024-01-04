using System;
using System.Runtime.InteropServices;

public static partial class Monitor
{
    public static void Scale(uint scaling)
    {
        NativeMethods.SystemParametersInfo(
            NativeMethods.SPI_SETLOGICALDPIOVERRIDE,
            scaling,
            0,
            NativeMethods.SPIF_UPDATEINIFILE);
    }

    public static partial class NativeMethods
    {
        public const uint SPI_SETLOGICALDPIOVERRIDE = 0x009F;

        public const uint SPIF_NONE = 0;
        public const uint SPIF_UPDATEINIFILE = 1;
        public const uint SPIF_SENDCHANGE = 2;

        [DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
        public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);
    }
}