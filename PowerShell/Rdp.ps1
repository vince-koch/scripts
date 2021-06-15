param (
    [string] $machineName = $null,
    [switch] $fullscreen = $false,
    [switch] $multimon = $false
)

function ShowHelp() {
    Write-Host "rdp [machineName] [-fullscreen] [-multimon]"
}

class Option
{
    [string] $Key;
    [string] $Type;
    [string] $Value;

    static [Option] Parse([string] $line) {
        [string[]] $parts = $line.Split(":")

        if ($parts.Length -eq 3)
        {
            [Option] $option = [Option]::new()
            $option.Key = $parts[0]
            $option.Type = $parts[1]
            $option.Value = $parts[2]

            return $option
        }

        return $null
    }

    static [void] LaunchRdp([Option[]] $options) {
        [System.IO.StringWriter] $writer = [System.IO.StringWriter]::new()
        foreach ($option in $options) {
            $writer.Write($option.Key)
            $writer.Write(":")
            $writer.Write($option.Type)
            $writer.Write(":")
            $writer.Write($option.Value)
            $writer.WriteLine()
        }

        [string] $content = $writer.ToString()
        [string] $path = [System.IO.Path]::Combine($PSScriptRoot, "rdp.rdp")
        [System.IO.File]::WriteAllText($path, $content)

        Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList "$path"

        Start-Sleep -Second 3
        Remove-Item -Path $path
    }

    static [void] SetValue([Option[]] $options, [string] $key, [string] $value) {
        foreach ($option in $options) {
            if ($option.Key -eq $key) {
                $option.Value = $value
                break
            }
        }
    }

    static [Option[]] GetAll() {
        [System.Collections.ArrayList] $options = [System.Collections.ArrayList]::new()

        [array] $template = @(
            "full address:s:",
            "screen mode id:i:1",
            "use multimon:i:0",
            "desktopwidth:i:1680",
            "desktopheight:i:1050",
            "session bpp:i:32",
            "winposstr:s:0,1,826,285,2522,1374",
            "compression:i:1",
            "keyboardhook:i:2",
            "audiocapturemode:i:0",
            "videoplaybackmode:i:1",
            "connection type:i:7",
            "networkautodetect:i:1",
            "bandwidthautodetect:i:1",
            "displayconnectionbar:i:1",
            "enableworkspacereconnect:i:0",
            "disable wallpaper:i:0",
            "allow font smoothing:i:0",
            "allow desktop composition:i:0",
            "disable full window drag:i:1",
            "disable menu anims:i:1",
            "disable themes:i:0",
            "disable cursor setting:i:0",
            "bitmapcachepersistenable:i:1",
            "audiomode:i:0",
            "redirectprinters:i:1",
            "redirectcomports:i:0",
            "redirectsmartcards:i:1",
            "redirectclipboard:i:1",
            "redirectposdevices:i:0",
            "autoreconnection enabled:i:1",
            "authentication level:i:2",
            "prompt for credentials:i:0",
            "negotiate security layer:i:1",
            "remoteapplicationmode:i:0",
            "alternate shell:s:",
            "shell working directory:s:",
            "gatewayhostname:s:",
            "gatewayusagemethod:i:4",
            "gatewaycredentialssource:i:4",
            "gatewayprofileusagemethod:i:0",
            "promptcredentialonce:i:0",
            "gatewaybrokeringtype:i:0",
            "use redirection server name:i:0",
            "rdgiskdcproxy:i:0",
            "kdcproxyname:s:"
        )

        foreach ($line in $template) {
            [Option] $option = [Option]::Parse($line)
            if ($option -ne $null) {
                $options.Add($option)
            }
        }

        return $options
    }
}

if ($machineName -eq "help" -or $machineName -eq "--help" -or $machineName -eq "/help" -or $machineName -eq "?") {
    ShowHelp
    exit
}

if ([System.String]::IsNullOrWhiteSpace($machineName)) {
    $machineName = Read-Host "machine name"
}

if ([System.String]::IsNullOrWhiteSpace($machineName) -eq $false) {
    [Option[]] $options = [Option]::GetAll()
    [Option]::SetValue($options, "full address", $machineName)

    if ($fullscreen -eq $true) {
        [Option]::SetValue($options, "screen mode id", "2")       
    }

    if ($multimon -eq $true) {
        [Option]::SetValue($options, "use multimon", "1")
    }

    [Option]::LaunchRdp($options)
}