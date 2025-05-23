# Invoke-Expression (& { (Invoke-WebRequest -Uri https://raw.githubusercontent.com/vince-koch/scripts/refs/heads/main/PowerShell/Profile-Server.ps1 -UseBasicParsing).Content })

Write-Host "Checkpoint 1" -ForegroundColor Green


function Welcome {
    $edition = if ($PSVersionTable.PSEdition -eq "Desktop") { "Windows PowerShell" } else { "PowerShell Core" }
    Write-Host "$edition " -ForegroundColor Blue -NoNewLine
    Write-Host "$($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    Write-Host "$($PSScriptRoot)$([System.IO.Path]::DirectorySeparatorChar)" -ForegroundColor Blue -NoNewLine
    Write-Host "$([System.IO.Path]::GetFileName($PSCommandPath))" -ForegroundColor Cyan
}

Write-Host "Checkpoint 2" -ForegroundColor Green

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
        $rawUrl = "https://raw.githubusercontent.com/vince-koch/scripts/refs/heads/main/PowerShell/$($file)"
        $outputPath = [System.IO.Path]::Combine($Home, ".ps-env", $file)
        $outputDirectory = [System.IO.Path]::GetDirectoryName($outputPath)
        $null = [System.IO.Directory]::CreateDirectory($outputDirectory)
        Invoke-WebRequest -Uri $rawUrl -OutFile $outputPath -UseBasicParsing -ErrorAction Stop
    }

    # install modules
    Install-Module PSColors -Force -AllowClobber

    # create $profile
    $psEnvProfileFile = [System.IO.Path]::Combine($psEnvDirectory, $ProfileFile)
    $profileDirectory = [System.IO.Path]::GetDirectoryName($profile)
    $null = [System.IO.Directory]::CreateDirectory($profileDirectory)
    $null = [System.IO.File]::WriteAllText("$($profile)", ". $($psEnvProfileFile)")
}

Write-Host "Checkpoint 3" -ForegroundColor Green

function Try-Import-Module {
    param (
        [string] $ModulePath
    )

    $IsDebug = $false
    $ModuleName = [System.IO.Path]::GetFileNameWithoutExtension($ModulePath)
    
    #if (-not (Get-Module -Name $ModuleName)) {
    #    try {
    #        Import-Module -Name $ModulePath -DisableNameChecking -Force -ErrorAction Stop
    #        Write-Host "Loaded module " -ForegroundColor DarkGray -NoNewLine; Write-Host $ModuleName
    #    }
    #    catch {
    #        Write-Host "Failed to import module from path '$ModulePath': $_" -ForegroundColor Red
    #    }
    #}
}

Write-Host "Checkpoint 4" -ForegroundColor Green

function CustomPrompt {
	$lastExit = if ($?) { "✓" } else { "✗" }
    $lastExitColor = if ($?) { "Green" } else { "Red" }

    Write-Host "PS" -ForegroundColor Blue -NoNewLine                                            # powershell indicator
    Write-Host " $lastExit" -ForegroundColor $lastExitColor -NoNewLine                          # last exit code
    Write-Host " $([System.Environment]::UserName)" -ForegroundColor Magenta -NoNewLine         # user name
    Write-Host " $([System.Environment]::MachineName)" -ForegroundColor DarkMagenta -NoNewLine  # machine name
    Write-Host " $((Get-Date).ToString("HH:mm"))" -ForegroundColor DarkGray -NoNewLine          # current time
    Write-Host " $((Get-Location).Path)" -ForegroundColor Cyan -NoNewLine                       # current folder
    Write-Host ">" -ForegroundColor Blue -NoNewLine                                             # prompt indicator

    Return " "
}

Write-Host "Checkpoint 5" -ForegroundColor Green

if ($MyInvocation.MyCommand.Path -eq $null) {
    Write-Host "Checkpoint 6" -ForegroundColor Green

    Welcome
    
    Write-Host "Checkpoint 7" -ForegroundColor Green

    $files = @(
        "Aws.psm1",
        "Bookmark.psm1",
        "Console.psm1",
        "Notepad++.psm1",
        "Profile-Server.ps1"
    )

    Install-Files -Files $files -ProfileFile "Profile-Server.ps1"

    Write-Host "Checkpoint 8" -ForegroundColor Green

    . $profile

    Write-Host "Checkpoint 9" -ForegroundColor Green
}
else {
    Write-Host "Checkpoint 10" -ForegroundColor Green

    Welcome

    Write-Host "Checkpoint 11" -ForegroundColor Green

    Import-Module PSColors # https://mtreit.com/powershell/2019/02/11/ATouchOfColor.html

    Try-Import-Module $PSScriptRoot\Aws.psm1
    Try-Import-Module $PSScriptRoot\Bookmark.psm1
    Try-Import-Module $PSScriptRoot\Console.psm1
    Try-Import-Module $PSScriptRoot\Notepad++.psm1
    $env:Path += ";$PSScriptRoot"
    $env:Path += ";D:\ETL\Tools\aws\2.15.12"

    Write-Host "Checkpoint 12" -ForegroundColor Green

    function Prompt { CustomPrompt }

    Write-Host "Checkpoint 13" -ForegroundColor Green
}

Write-Host "Checkpoint 4" -ForegroundColor Green