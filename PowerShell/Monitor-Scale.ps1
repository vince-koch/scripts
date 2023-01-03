# scales all connected monitors to the specified scaling step from recommended
#
# $scaling = 0 : recommended scaling
# $scaling = 1 : recommended scaling + 1 step
# $scaling = 2 : recommended scaling + 2 steps
# $scaling = 3 : recommended scaling + 3 step
param($scaling = 0)
$source = @’
[DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
public static extern bool SystemParametersInfo(
                uint uiAction,
                uint uiParam,
                uint pvParam,
                uint fWinIni);
‘@

$apicall = Add-Type -MemberDefinition $source -Name WinAPICall -Namespace SystemParamInfo –PassThru

$SPI_SETLOGICALDPIOVERRIDE = 0x009F
$SPIF_NONE = 0
$SPIF_UPDATEINIFILE = 1
$SPIF_SENDCHANGE = 2
$apicall::SystemParametersInfo($SPI_SETLOGICALDPIOVERRIDE, $scaling, $null, $SPIF_UPDATEINIFILE) | Out-Null