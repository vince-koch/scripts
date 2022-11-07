param (
    [string] $machineName = $null,
    [switch] $fullscreen = $false,
    [switch] $multimon = $false
)

Import-Module $PSScriptRoot\Console.psm1 -DisableNameChecking -Force
$ErrorActionPreference = "Stop"

function ShowHelp() {
    Write-Host "rdp [machineName] [-fullscreen] [-multimon]"
}

class RdpOption
{
    [string] $Key;
    [string] $Type;
    [string] $Value;

    static [RdpOption] Parse([string] $line) {
        [string[]] $parts = $line.Split(":")

        if ($parts.Length -gt 2)
        {
            [RdpOption] $option = [RdpOption]::new()
            $option.Key = $parts[0]
            $option.Type = $parts[1]
            $option.Value = [String]::Join(":", $( $parts | Select -Skip 2 ))

            return $option
        }

        return $null
    }

    static [void] LaunchRdp([RdpOption[]] $options) {
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

    static [String] GetValue([RdpOption[]] $options, [string] $key) {
        foreach ($option in $options) {
            if ($option.Key -eq $key) {
                return $option.Value
            }
        }

        return $null
    }

    static [void] SetValue([RdpOption[]] $options, [string] $key, [string] $value) {
        foreach ($option in $options) {
            if ($option.Key -eq $key) {
                $option.Value = $value
                break
            }
        }
    }

    static [void] Debug([RdpOption[]] $options) {
        foreach ($option in $options) {
            Write-Host "$($option.Key) = $($option.Value)"
        }
    }

    static [RdpOption[]] LoadFromFile($path) {
        $lines = [System.IO.File]::ReadAllLines($path)
        $options = [RdpOption]::GetFromLines($lines)
        return $options
    }

    static [RdpOption[]] GetDefault() {
        [String[]] $lines = @(
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

        $options = [RdpOption]::GetFromLines($lines)
        return $options
    }

    static [RdpOption[]] GetFromLines([String[]] $lines) {
        [System.Collections.ArrayList] $options = [System.Collections.ArrayList]::new()

        foreach ($line in $lines) {
            [RdpOption] $option = [RdpOption]::Parse($line)
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

[RdpOption[]] $options = $null

# if they gave us a machine name, use default options and set full address
if ([System.String]::IsNullOrWhiteSpace($machineName) -eq $false) {
    $options = [RdpOption]::GetDefault()
    [RdpOption]::SetValue($options, "full address", $machineName)
}

# if we don't have options yet, see if they want to select a *.rdp file
if ($options -eq $null) {
    $documents = [Environment]::GetFolderPath("MyDocuments")
    $files = [System.IO.Directory]::GetFiles($documents, "*.rdp", "TopDirectoryOnly")
    if ($files.Length -gt 0) {
        $choice = Console-Menu -Items $files -ItemsProperty { param ($item) [System.IO.Path]::GetFileNameWithoutExtension($item) } -Title "Select RDP File"
        if ($choice -ne $null) {
            $options = [RdpOption]::LoadFromFile($choice)
        }
    }
}

# if we still don't have options then prompt them for a machine name
if ($options -eq $null) {
    #$machineName = Read-Host "machine name"
    Write-Host "Machine Name: " -ForegroundColor Cyan -NoNewLine
    $machineName = Read-Host

    if ([System.String]::IsNullOrWhiteSpace($machineName) -eq $false) {
        $options = [RdpOption]::GetDefault()
        [RdpOption]::SetValue($options, "full address", $machineName)
    }
}

# hopefully we have options by now
if ($options -eq $null) {
    Write-Host "User cancelled" -ForegroundColor Red
}
else {
    if ($fullscreen -eq $true) {
        [RdpOption]::SetValue($options, "screen mode id", "2")       
    }

    if ($multimon -eq $true) {
        [RdpOption]::SetValue($options, "use multimon", "1")
    }

    $fullAddress = [RdpOption]::GetValue($options, "full address")
    Write-Host "Connecting to " -NoNewLine
    Write-Host $fullAddress -ForegroundColor Cyan

    [RdpOption]::LaunchRdp($options)
}