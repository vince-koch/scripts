function Write-Colors {
    Write-Host "Black" -ForegroundColor Black
    Write-Host "Blue" -ForegroundColor Blue
    Write-Host "Cyan" -ForegroundColor Cyan
    Write-Host "DarkBlue" -ForegroundColor DarkBlue
    Write-Host "DarkCyan" -ForegroundColor DarkCyan
    Write-Host "DarkGray" -ForegroundColor DarkGray
    Write-Host "DarkGreen" -ForegroundColor DarkGreen
    Write-Host "DarkMagenta" -ForegroundColor DarkMagenta
    Write-Host "DarkRed" -ForegroundColor DarkRed
    Write-Host "DarkYellow" -ForegroundColor DarkYellow
    Write-Host "Gray" -ForegroundColor Gray
    Write-Host "Green" -ForegroundColor Green
    Write-Host "Magenta" -ForegroundColor Magenta
    Write-Host "Red" -ForegroundColor Red
    Write-Host "White" -ForegroundColor White
    Write-Host "Yellow" -ForegroundColor Yellow
}

Set-Alias -Name unzip -Value Expand-Archive

Import-Module $PSScriptRoot\Git.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Notepad++.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Prompt-Default.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Shebang.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\TabsToSpaces.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Console.psm1 -DisableNameChecking -Force

# add $PSScriptRoot to the path, and some aliases for loose ps1 files
$env:Path += ";$PSScriptRoot"
Set-Alias -Name move-windows -Value Move-WindowsToScreen
Set-Alias -Name move-to-screen -Value Move-WindowsToScreen

function Which {
    param ([string] $command)
    (get-command $command).Path
}

# set prompt
function Global:Prompt {
	return Prompt-Default
}

# welcome message
try {
    Write-Host "PowerShell Version $($Host.Version.ToString())" -ForegroundColor DarkGray

    Push-Location $PSScriptRoot
    Write-Host "$([System.IO.Path]::GetFileName($PSCommandPath))" -NoNewLine

    $branch = Git-GetBranchName
    if ($branch) {
        Write-Host " / " -ForegroundColor DarkGray -NoNewLine
        Write-Host "$branch" -ForegroundColor Cyan -NoNewLine

        $commitDate = Git-GetCommitDate
        Write-Host " / " -ForegroundColor DarkGray -NoNewLine
        Write-Host "$commitDate" -ForegroundColor Blue -NoNewLine
    }
}
finally {
    Write-Host ""
    Pop-Location
}

$p = Get-Process -Id $PID
If ($p.Parent.Name -eq $p.Name -and !($p.MainWindowTitle))
{
    Stop-Process -Id $p.Parent.Id -Force
}