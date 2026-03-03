function Prompt-ConfirmWithTimeout {
    param (
        [string]$Message,
        [string]$Default = 'Y',  # Default choice
        [int]$Timeout = 10
    )

    $defaultText = if ($Default -eq 'Y') { "(Y/N)" } else { "(y/n)" }
    $timeoutTime = [System.DateTime]::Now.AddSeconds($Timeout)

    while ([System.DateTime]::Now -lt $timeoutTime) {
        Start-Sleep -Milliseconds 1001

        $remainingTime = $timeoutTime - [System.DateTime]::Now
        $remainingSeconds = [math]::Ceiling($remainingTime.TotalSeconds)
        Write-Host "`r$Message $defaultText $remainingSeconds " -NoNewline

        if ([Console]::KeyAvailable) {
            $keyPress = [System.Console]::ReadKey($true)
            if ($keyPress.Key -eq [ConsoleKey]::Y) {
                Write-Host "Y" -ForegroundColor Green
                return $true
            } elseif ($keyPress.Key -eq [ConsoleKey]::N) {
                Write-Host "N" -ForegroundColor Red
                return $false
            }
        }
    }

    # Timeout occurred, use the default value
    Write-Host "$Default (timeout)" -ForegroundColor Yellow
    return $Default -eq 'Y'
}

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "Detected Windows PowerShell version $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    $launch = Prompt-ConfirmWithTimeout -Message "Would you like to launch PowerShell Core instead?" -Default 'Y' -Timeout 10
    if ($launch) {
        Write-Host "Launching PowerShell Core..." -ForegroundColor Green
        & pwsh
        Write-Host "Resuming PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
        exit
    }
}

function Welcome {
    $edition = if ($PSVersionTable.PSEdition -eq "Desktop") { "Windows PowerShell" } else { "PowerShell Core" }
    Write-Host "$edition " -ForegroundColor Blue -NoNewLine
    Write-Host "$($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    Write-Host "$($PSScriptRoot)$([System.IO.Path]::DirectorySeparatorChar)" -ForegroundColor Blue -NoNewLine
    Write-Host "$([System.IO.Path]::GetFileName($PSCommandPath))" -ForegroundColor Cyan
}

# startup welcome screen
Welcome

function Start-Profile-Timer($Name) {
    if (-not $global:ProfileTimers) { $global:ProfileTimers = @{} }
    $global:ProfileTimers[$Name] = [System.Diagnostics.Stopwatch]::StartNew()
}

function Stop-Profile-Timer($Name) {
    if ($global:ProfileTimers.ContainsKey($Name)) {
        $global:ProfileTimers[$Name].Stop()
    }
}

function Print-Profile-Timers {
    foreach ($key in $global:ProfileTimers.Keys) {
        $timer = $global:ProfileTimers[$key]
        Write-Host "$key took $($timer.Elapsed)"
    }
}


function Try-Import-Module {
    param (
        [Parameter(Mandatory)]
        [string] $ModulePath
    )

    Start-Profile-Timer -Name "Try-Import-Module $ModulePath"

    try {
        $IsDebug = $false
        $resolvedPath = [System.IO.Path]::GetFullPath($ModulePath)

        # Check if module with that path is already loaded
        $alreadyLoaded = Get-Module | Where-Object {
            $_.Path -and ($_.Path -eq $resolvedPath)
        }

        if (-not $alreadyLoaded) {
            try {
                Import-Module -Name $resolvedPath -DisableNameChecking -Force -ErrorAction Stop
                if ($IsDebug) {
                    Write-Host "Loaded module $([System.IO.Path]::GetFileNameWithoutExtension($resolvedPath))" -ForegroundColor DarkGray
                }
            }
            catch {
                Write-Host "Failed to import module from path '$resolvedPath': $_" -ForegroundColor Red
            }
        }
        elseif ($IsDebug) {
            Write-Host "Skipped already-loaded module: $resolvedPath" -ForegroundColor DarkGray
        }
    }
    finally {
        Stop-Profile-Timer -Name "Try-Import-Module $ModulePath"
    }
}


# random variables, functions, and aliases

$aws_config_path = [System.IO.Path]::Combine($env:USERPROFILE, ".aws", "config")
$nuget_config_path = [System.IO.Path]::Combine($env:APPDATA, "Nuget", "Nuget.config")
function Aws-Config { npp $aws_config }
function Nuget-Config { npp $nuget_config }

function Less {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        Write-Host "File not found: $Path" -ForegroundColor Red
        return
    }

    Get-Content -Path $Path | Out-Host -Paging
}

function UnZip {
    param (
        [string]$ZipFile,
        [string]$Destination = "."
    )
    Expand-Archive -Path $ZipFile -DestinationPath $Destination -Force @Args
}

function Which {
    param([string]$name)
    (Get-Command $name).Source
}

function Write-Colors {
    $colors = [Enum]::GetValues([System.ConsoleColor])

    foreach ($color in $colors) {
        Write-Host ("{0,-15}" -f $color) -ForegroundColor $color -NoNewLine
        Write-Host ("{0,-15}" -f $color)
    }
}


# load modules
Try-Import-Module $PSScriptRoot\Alias.psm1
Try-Import-Module $PSScriptRoot\Aws.psm1
Try-Import-Module $PSScriptRoot\Bookmark.psm1
Try-Import-Module $PSScriptRoot\Console.psm1
Try-Import-Module $PSScriptRoot\Config.psm1
Try-Import-Module $PSScriptRoot\Docker.psm1
Try-Import-Module $PSScriptRoot\Environment.psm1
Try-Import-Module $PSScriptRoot\Files.psm1
Try-Import-Module $PSScriptRoot\Git.psm1
Try-Import-Module $PSScriptRoot\Jira.psm1
Try-Import-Module $PSScriptRoot\Mongo.psm1
Try-Import-Module $PSScriptRoot\Notepad++.psm1
Try-Import-Module $PSScriptRoot\Ps.psm1
Try-Import-Module $PSScriptRoot\Shebang.psm1
Try-Import-Module $PSScriptRoot\Studio3T.psm1
Try-Import-Module $PSScriptRoot\TabsToSpaces.psm1
Try-Import-Module $PSScriptRoot\Update.psm1
Try-Import-Module $PSScriptRoot\VisualStudio.psm1
Try-Import-Module $PSScriptRoot\Windows.psm1

Start-Profile-Timer -Name "TerminalIcons"
. $PSScriptRoot\Profile-TerminalIcons.ps1
Stop-Profile-Timer -Name "TerminalIcons"

# add $PSScriptRoot to the path
$env:Path += ";$PSScriptRoot"