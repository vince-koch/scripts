# Terminal-Icons
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module -Name Terminal-Icons
} 
else {
    if (Ps-IsCore) {
        # fix default directory coloring as best we can quickly and easily
        $PSStyle.FileInfo.Directory = "`e[94;3;4m"
    }

    Write-Host "Terminal-Icons module is not installed." -ForegroundColor Red
}