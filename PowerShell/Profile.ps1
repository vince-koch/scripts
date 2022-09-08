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

function Global:Prompt {
	return Prompt-Default
}

try {
    Push-Location $PSScriptRoot
    Write-Host "Running " -ForegroundColor DarkGray -NoNewLine
    Write-Host "$([System.IO.Path]::GetFileName($PSCommandPath))" -ForegroundColor Magenta -NoNewLine

    $branch = Git-GetBranchName
    if ($branch) {
        Write-Host " branch " -ForegroundColor DarkGray -NoNewLine
        Write-Host "$branch" -ForegroundColor Cyan -NoNewLine

        $commitDate = Git-GetCommitDate
        Write-Host " updated " -ForegroundColor DarkGray -NoNewLine
        Write-Host "$commitDate" -ForegroundColor Blue -NoNewLine
    }
}
finally {
    Write-Host ""
    Pop-Location
}