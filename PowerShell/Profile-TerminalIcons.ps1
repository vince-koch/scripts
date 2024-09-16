Try-Import-Module $PSScriptRoot\Console.psm1

# Terminal-Icons
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module -Name Terminal-Icons
} 
else {
    Write-Host "Terminal-Icons module is not installed." -ForegroundColor Red
    $installNow = Console-Confirm -Prompt "Would you like to install it now? [Y/n] "
    if ($installNow -eq $true) {
        Install-Module -Name Terminal-Icons -Repository PSGallery -Scope CurrentUser -Force
        Import-Module -Name Terminal-Icons
    }
    elseif (Ps-IsCore) {
        # fix default directory coloring as best we can quickly and easily
        $PSStyle.FileInfo.Directory = "`e[94;3;4m"
    }
}