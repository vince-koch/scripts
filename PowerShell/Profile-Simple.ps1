function Welcome {
    $edition = if ($PSVersionTable.PSEdition -eq "Desktop") { "Windows PowerShell" } else { "PowerShell Core" }
    Write-Host "$edition " -ForegroundColor Blue -NoNewLine
    Write-Host "$($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    Write-Host "$($PSScriptRoot)$([System.IO.Path]::DirectorySeparatorChar)" -ForegroundColor Blue -NoNewLine
    Write-Host "$([System.IO.Path]::GetFileName($PSCommandPath))" -ForegroundColor Cyan
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


#$env:Path += ";$PSScriptRoot"
#$env:Path += ";D:\ETL\Tools\aws\2.15.12"
Try-Import-Module $PSScriptRoot\Aws.psm1
Try-Import-Module $PSScriptRoot\Bookmark.psm1
Try-Import-Module $PSScriptRoot\Console.psm1
Try-Import-Module $PSScriptRoot\Environment.psm1
Try-Import-Module $PSScriptRoot\Notepad++.psm1


function CustomPsStyle {
    if ($isCore = $PSVersionTable.PSEdition -eq "Core") {
        # fix default directory coloring as best we can quickly and easily
        $PSStyle.FileInfo.Directory = "`e[94;3;4m"
    }
}


function global:Prompt {
    if ($?) { $lastExit = "[OK]" } else { $lastExit = "[ERR]" }
    if ($?) { $lastExitColor = "Green" } else { $lastExitColor = "Red" }
    Write-Host "$lastExit" -ForegroundColor $lastExitColor -NoNewLine                           # last exit code

    Write-Host " PS" -ForegroundColor Blue -NoNewLine                                           # powershell indicator
    Write-Host " $([System.Environment]::UserName)" -ForegroundColor Magenta -NoNewLine         # user name
    Write-Host " $([System.Environment]::MachineName)" -ForegroundColor DarkMagenta -NoNewLine  # machine name
    Write-Host " $((Get-Date).ToString("HH:mm"))" -ForegroundColor Gray -NoNewLine              # current time
    Write-Host " $((Get-Location).Path)" -ForegroundColor Cyan -NoNewLine                       # current folder
    Write-Host ">" -ForegroundColor White -NoNewLine                                             # prompt indicator

    Return " "
}


Welcome