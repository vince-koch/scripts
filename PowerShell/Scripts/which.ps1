<#
.SYNOPSIS
    Shows where a command comes from.
.DESCRIPTION
    Resolves a command through PowerShell and returns its source path or module.
.EXAMPLE
    which pwsh
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Name
)

(Get-Command -Name $Name -ErrorAction Stop).Source
