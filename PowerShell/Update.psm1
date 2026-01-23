Try-Import-Module $PSScriptRoot\Git.psm1

function Update {
    # git will walk up and find the .git/ folder, so no
    # problem calling this from a subdirectory
    & pushd $PSScriptRoot
    & git remote update
    & git pull
    & popd
}

Export-ModuleMember -Function Update

Write-Host "(Enter " -ForegroundColor DarkGray -NoNewLine
Write-Host "Update" -ForegroundColor Gray -NoNewLine
Write-Host " to update profile scripts)" -ForegroundColor DarkGray