<#
.SYNOPSIS
    Opens a Jira ticket in the default browser.
.DESCRIPTION
    Accepts a ticket key and navigates to the corresponding Claris Health Jira issue.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string] $ticket
)

$url = "https://clarishealth.atlassian.net/browse/$ticket"

Start-Process $url
