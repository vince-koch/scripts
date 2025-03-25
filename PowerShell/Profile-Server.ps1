# Load modules

function Try-Import-Module {
    param (
        [string] $ModulePath
    )

    $IsDebug = $false
    $ModuleName = [System.IO.Path]::GetFileNameWithoutExtension($ModulePath)
    
    if (-not (Get-Module -Name $ModuleName)) {
        try {
            Import-Module -Name $ModulePath -DisableNameChecking -Force -ErrorAction Stop
            Write-Host "Loaded module '$ModuleName'" -ForegroundColor DarkGray
        }
        catch {
            Write-Host "Failed to import module from path '$ModulePath': $_" -ForegroundColor Red
        }
    }
}

$env:Path += ";$PSScriptRoot"
$env:Path += ";D:\ETL\Tools\aws\2.15.12"
Try-Import-Module $PSScriptRoot\Aws.psm1
Try-Import-Module $PSScriptRoot\Console.psm1

# Welcome and prompt

function Welcome {
    $edition = if ($PSVersionTable.PSEdition -eq "Desktop") { "Windows PowerShell" } else { "PowerShell Core" }
    Write-Host "$edition " -ForegroundColor Blue -NoNewLine
    Write-Host "$($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    Write-Host "$($PSScriptRoot)$([System.IO.Path]::DirectorySeparatorChar)" -ForegroundColor Blue -NoNewLine
    Write-Host "$([System.IO.Path]::GetFileName($PSCommandPath))" -ForegroundColor Cyan
}

function Prompt {
    Write-Host "PS " -ForegroundColor Blue -NoNewLine
    Write-Host "$((Get-Location).Path)" -ForegroundColor Cyan -NoNewLine
    Write-Host ">" -ForegroundColor Blue -NoNewLine
    Return " "
}

Welcome