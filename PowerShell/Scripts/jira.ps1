[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string] $ticket
)

$url = "https://clarishealth.atlassian.net/browse/$ticket"

Start-Process $url