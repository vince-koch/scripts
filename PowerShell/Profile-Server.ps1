# Invoke-Expression (& { (Invoke-WebRequest -Uri https://raw.githubusercontent.com/vince-koch/scripts/refs/heads/main/PowerShell/Profile-Server.ps1 -UseBasicParsing).Content })


function Welcome {
    $edition = if ($PSVersionTable.PSEdition -eq "Desktop") { "Windows PowerShell" } else { "PowerShell Core" }
    Write-Host "$edition " -ForegroundColor Blue -NoNewLine
    Write-Host "$($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    Write-Host "$($PSScriptRoot)$([System.IO.Path]::DirectorySeparatorChar)" -ForegroundColor Blue -NoNewLine
    Write-Host "$([System.IO.Path]::GetFileName($PSCommandPath))" -ForegroundColor Cyan
}


function Install-Files {
    param (
        [Parameter(Mandatory = $True)] [array] $Files,
        [Parameter(Mandatory = $True)] [string] $ProfileFile
    )

    # make sure $home/.ps-env/ folder exists
    $psEnvDirectory = [System.IO.Path]::Combine($Home, ".ps-env")
    $null = [System.IO.Directory]::CreateDirectory($psEnvDirectory)

    # download files
    foreach ($file in $Files) {
        Write-Host "Downloading $($file)"
        $rawUrl = "https://raw.githubusercontent.com/vince-koch/scripts/refs/heads/main/PowerShell/$($file)"
        $outputPath = [System.IO.Path]::Combine($Home, ".ps-env", $file)
        $outputDirectory = [System.IO.Path]::GetDirectoryName($outputPath)
        $null = [System.IO.Directory]::CreateDirectory($outputDirectory)
        $response = Invoke-WebRequest -Uri $rawUrl -UseBasicParsing -ErrorAction Stop
        [System.IO.File]::WriteAllText($outputPath, $response.Content, [System.Text.Encoding]::UTF8)
    }

    # create $profile
    Write-Host "Creating `$profile"
    $psEnvProfileFile = [System.IO.Path]::Combine($psEnvDirectory, $ProfileFile)
    $profileDirectory = [System.IO.Path]::GetDirectoryName($profile)
    $null = [System.IO.Directory]::CreateDirectory($profileDirectory)
    $null = [System.IO.File]::WriteAllText("$($profile)", ". $($psEnvProfileFile)")
}


function Try-Import-Module {
    param (
        [Parameter(Mandatory)]
        [string] $ModulePath
    )

    $IsDebug = $false
    $resolvedPath = [System.IO.Path]::GetFullPath($ModulePath)

    # Check if module with that path is already loaded
    $alreadyLoaded = Get-Module | Where-Object {
        $_.Path -and ($_.Path -eq $resolvedPath)
    }

    if (-not $alreadyLoaded) {
        try {
            Import-Module -Name $resolvedPath -DisableNameChecking -Force -ErrorAction Stop
            Write-Host "Loaded module $([System.IO.Path]::GetFileNameWithoutExtension($resolvedPath))"
        }
        catch {
            Write-Host "Failed to import module from path '$resolvedPath': $_" -ForegroundColor Red
        }
    }
    elseif ($IsDebug) {
        Write-Host "Skipped already-loaded module: $resolvedPath" -ForegroundColor DarkGray
    }
}


function Write-Colors {
    $colors = [Enum]::GetValues([System.ConsoleColor])

    foreach ($color in $colors) {
        Write-Host ("{0,-15}" -f $color) -ForegroundColor $color -NoNewLine
        Write-Host ("{0,-15}" -f $color)
    }
}


function CustomPrompt {
    if ($?) { $lastExit = "✓" } else { $lastExit = "✗" }
    if ($?) { $lastExitColor = "Green" } else { $lastExitColor = "Red" }

    Write-Host "PS" -ForegroundColor Blue -NoNewLine                                            # powershell indicator
    Write-Host " $lastExit" -ForegroundColor $lastExitColor -NoNewLine                          # last exit code
    Write-Host " $([System.Environment]::UserName)" -ForegroundColor Magenta -NoNewLine         # user name
    Write-Host " $([System.Environment]::MachineName)" -ForegroundColor DarkMagenta -NoNewLine  # machine name
    Write-Host " $((Get-Date).ToString("HH:mm"))" -ForegroundColor Gray -NoNewLine              # current time
    Write-Host " $((Get-Location).Path)" -ForegroundColor Cyan -NoNewLine                       # current folder
    Write-Host ">" -ForegroundColor Blue -NoNewLine                                             # prompt indicator

    Return " "
}


function CustomPsStyle {
    if ($isCore = $PSVersionTable.PSEdition -eq "Core") {
        # fix default directory coloring as best we can quickly and easily
        $PSStyle.FileInfo.Directory = "`e[94;3;4m"
    }
}


if ($MyInvocation.MyCommand.Path -eq $null) {
    Welcome
    
    Install-Files -ProfileFile "Profile-Server.ps1" -Files @(
        "Aws.psm1",
        "Bookmark.psm1",
        "Console.psm1",
        "Notepad++.psm1",
        "Profile-Server.ps1"
    )

    . $profile
}
else {
    Welcome

    Try-Import-Module $PSScriptRoot\Aws.psm1
    Try-Import-Module $PSScriptRoot\Bookmark.psm1
    Try-Import-Module $PSScriptRoot\Console.psm1
    Try-Import-Module $PSScriptRoot\Notepad++.psm1

    $env:Path += ";$PSScriptRoot"
    $env:Path += ";D:\ETL\Tools\aws\2.15.12"

    CustomPsStyle
    function Prompt { CustomPrompt }
}
