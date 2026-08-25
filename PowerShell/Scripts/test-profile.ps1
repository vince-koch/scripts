<#
.SYNOPSIS
    Checks profile startup time, command discovery, and lazy module loading.
.DESCRIPTION
    Loads Profile.ps1 in a clean PowerShell process and reports whether script
    commands are available, PATH entries remain unique, and Docker auto-loads.
#>

[CmdletBinding()]
param ()

$profilePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'Profile.ps1'
$engine = (Get-Process -Id $PID).Path
$probe = @'
$profilePath = $env:SCRIPTS_PROFILE_TEST_PATH
$watch = [System.Diagnostics.Stopwatch]::StartNew()
. $profilePath
$watch.Stop()

$moduleNames = @('Bookmark', 'Config', 'Docker', 'DotNet', 'Environment', 'Files', 'Git', 'Nvm', 'VisualStudio', 'Windows', 'WindowsTerminal')
$modulesLoadedAtStart = @($moduleNames | Where-Object { Get-Module -Name $_ })
$commands = @(
    'ccd'
    'config'
    'Docker-StartInteractive'
    'dotnet-clean'
    'dotnet-secrets'
    'env'
    'find-files'
    'find-modules'
    'Git-Zip'
    'git-change-branch'
    'git-delete-branches'
    'less'
    'nvm'
    'search'
    'tail'
    'touch'
    'unzip'
    'vs'
    'windows'
    'winterm'
)
$missingCommands = @($commands | Where-Object { -not (Get-Command $_ -ErrorAction Ignore) })
$modulesLoadedAfterLookup = @($moduleNames | Where-Object { Get-Module -Name $_ })
$separator = [System.IO.Path]::PathSeparator
$profileRoot = Split-Path $profilePath -Parent
$scriptRoot = Join-Path $profileRoot 'Scripts'

# A second load must not duplicate registered paths.
. $profilePath
$pathEntries = $env:Path -split [regex]::Escape($separator)

[pscustomobject]@{
    ElapsedMilliseconds = $watch.ElapsedMilliseconds
    CommandsFound       = $missingCommands.Count -eq 0
    MissingCommands     = $missingCommands -join ', '
    ModulesAtStartup    = $modulesLoadedAtStart.Count
    ModulesAfterLookup  = $modulesLoadedAfterLookup.Count
    ProfilePathCopies   = @($pathEntries | Where-Object { $_ -eq $profileRoot }).Count
    ScriptPathCopies    = @($pathEntries | Where-Object { $_ -eq $scriptRoot }).Count
} | ConvertTo-Json -Compress
'@

$previousTestPath = $env:SCRIPTS_PROFILE_TEST_PATH
try {
    $env:SCRIPTS_PROFILE_TEST_PATH = $profilePath
    $output = & $engine -NoLogo -NoProfile -NonInteractive -Command $probe
}
finally {
    $env:SCRIPTS_PROFILE_TEST_PATH = $previousTestPath
}
$result = $output | Select-Object -Last 1 | ConvertFrom-Json

$checks = [ordered]@{
    'Profile load'         = "$($result.ElapsedMilliseconds) ms"
    'Migrated commands'    = if ($result.CommandsFound) { 'all found' } else { "missing: $($result.MissingCommands)" }
    'Modules at startup'   = $result.ModulesAtStartup
    'Modules after lookup' = $result.ModulesAfterLookup
    'Profile PATH copies'  = $result.ProfilePathCopies
    'Scripts PATH copies'  = $result.ScriptPathCopies
}

$checks.GetEnumerator() | ForEach-Object {
    [pscustomobject]@{ Check = $_.Key; Result = $_.Value }
} | Format-Table -AutoSize

$passed = $result.CommandsFound -and
    ($result.ModulesAtStartup -eq 0) -and
    ($result.ModulesAfterLookup -eq 11) -and
    ($result.ProfilePathCopies -eq 1) -and
    ($result.ScriptPathCopies -eq 1)

if (-not $passed) {
    throw 'One or more profile checks failed.'
}
