# USAGE
# Import-Module $PSScriptRoot\Jira.psm1 -DisableNameChecking -Force

function Jira {
    param (
        [Parameter(Mandatory = $true)]
        [string] $ticket
    )
	
	$url = "https://clarishealth.atlassian.net/browse/$ticket"
	
	Start-Process $url
}

function Poker {
	Start-Process "https://clarishealth.atlassian.net/projects/DF?selectedItem=com.atlassian.plugins.atlassian-connect-plugin:com.spartez.jira.plugins.jiraplanningpoker__poker-project-page#!/board/171"
}

Export-ModuleMember -Function Jira
Export-ModuleMember -Function Poker