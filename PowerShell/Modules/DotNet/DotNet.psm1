<#
.SYNOPSIS
    Provides local .NET development utilities.
.DESCRIPTION
    Loads the public .NET artifact-cleanup and user-secrets commands.
#>

$publicRoot = Join-Path $PSScriptRoot 'Public'
. (Join-Path $publicRoot 'Clean.ps1')
. (Join-Path $publicRoot 'Secrets.ps1')

Set-Alias -Name dotnet-clean -Value Clear-DotNetArtifacts
Set-Alias -Name dotnet-secrets -Value Open-DotNetSecrets

Export-ModuleMember `
    -Function Clear-DotNetArtifacts, Open-DotNetSecrets `
    -Alias dotnet-clean, dotnet-secrets
