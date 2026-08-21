#Requires -Module PwshSpectreConsole

<#
.SYNOPSIS
    Keeps the computer awake until a specified time.
.DESCRIPTION
    Displays a Spectre Console status spinner while preventing idle sleep until
    the requested hour and minute.
#>
param (
	[Parameter(Mandatory=$true, Position=0)]
	[ValidateRange(0, 23)]
    [int] $hour,
	
	[Parameter(Mandatory=$false, Position=1)]
	[ValidateRange(0, 59)]
	[int] $minute = 0
)

$encoding = New-Object System.Text.UTF8Encoding
$OutputEncoding = $encoding
[System.Console]::InputEncoding = $encoding
[System.Console]::OutputEncoding = $encoding

# calculate an actual date
$awakeUntil = [System.DateTime]::Today.AddHours($hour).AddMinutes($minute)
if ($awakeUntil -lt [System.DateTime]::Now) {
	$awakeUntil = $awakeUntil.AddDays(1)
}

$wsh = New-Object -ComObject WScript.Shell
$statusParameters = @{
    Spinner     = 'Material'
    Color       = 'Cyan1'
    Title       = "Staying awake until $($awakeUntil.ToString('g'))"
    ScriptBlock = {
        while ([System.DateTime]::Now -lt $awakeUntil) {
            $remaining = $awakeUntil - [System.DateTime]::Now
            $sleepSeconds = [Math]::Min(59, [Math]::Max(1, [Math]::Ceiling($remaining.TotalSeconds)))

            $wsh.SendKeys('+{F15}')
            Start-Sleep -Seconds $sleepSeconds
        }
    }
}

Invoke-SpectreCommandWithStatus @statusParameters

# Useful references:
#
# https://superuser.com/questions/992511/emulate-a-keyboard-button-via-the-command-line
# https://ss64.com/vb/sendkeys.html
# https://social.technet.microsoft.com/Forums/windowsserver/en-US/96b339e2-e9da-4802-a66d-be619aeb21ac/execute-function-one-time-in-every-10-mins-in-windows-powershell?forum=winserverpowershell
# https://learn-powershell.net/2013/02/08/powershell-and-events-object-events/
#
# Future enhancements - use events rather than an infinite loop

#$wsh = New-Object -ComObject WScript.Shell
#while (1) {
#  # Send Shift+F15 - this is the least intrusive key combination I can think of and is also used as default by:
#  # http://www.zhornsoftware.co.uk/caffeine/
#  # Unfortunately the above triggers a malware alert on Sophos so I needed to find a native solution - hence this script...
#  $wsh.SendKeys('+{F15}')
#  Start-Sleep -seconds 59
#}
