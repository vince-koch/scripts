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

function Write-TerminalProgress {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('aesthetic','arc','arrow','arrow2','arrow3','balloon','balloon2','betaWave','bluePulse','bounce','bouncingBall','bouncingBar','boxBounce','boxBounce2','christmas','circle','circleHalves','circleQuarters','clock','dots','dots10','dots11','dots12','dots2','dots3','dots4','dots5','dots6','dots7','dots8','dots8Bit','dots9','dqpb','earth','fingerDance','fistBump','flip','grenade','growHorizontal','growVertical','hamburger','hearts','layer','line','line2','material','mindblown','monkey','moon','noise','orangeBluePulse','orangePulse','pipe','point','pong','runner','shark','simpleDots','simpleDotsScrolling','smiley','soccerHeader','speaker','squareCorners','squish','star','star2','timeTravel','toggle','toggle10','toggle11','toggle12','toggle13','toggle2','toggle3','toggle4','toggle5','toggle6','toggle7','toggle8','toggle9','triangle','weather')]
        $IconSet
    )
	
    $path = "$PSScriptRoot\spinners.json"
    $spinners = Get-Content $path | ConvertFrom-Json 
    $frameCount = $spinners.$IconSet.frames.count
    $frameLength = $spinners.$IconSet.frames[0].Length
    $frameInterval = $spinners.$IconSet.interval
    $e = "$([char]27)"
	
    1..30 | foreach -Begin { write-host "$($e)[s" -NoNewline } -Process { 
        $frame = $spinners.$IconSet.frames[$_ % $frameCount]
        Write-Host "$e[u$frame" -NoNewline
        Start-Sleep -Milliseconds $frameInterval
    }
	
	Write-Host "$e[u$($e)[$($frameLength)P" -NoNewline
}

# calculate an actual date
$awakeUntil = [System.DateTime]::Today.AddHours($hour).AddMinutes($minute)
if ($awakeUntil -lt [System.DateTime]::Now) {
	$awakeUntil = $awakeUntil.AddDays(1)
}

$wsh = New-Object -ComObject WScript.Shell
while ([System.DateTime]::Now -lt $awakeUntil) {
	$awakeTimeSpan = $awakeUntil - [System.DateTime]::Now
	[int] $minutes = $awakeTimeSpan.TotalMinutes
	Write-Host "`rStaying awake until $($awakeUntil.ToString()) ($minutes minutes) " -NoNewLine
	
	$wsh.SendKeys('+{F15}')
	#Start-Sleep -seconds 59
    Write-TerminalProgress material
}

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