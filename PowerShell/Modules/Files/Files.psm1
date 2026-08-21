function File-Search {
    param(
        [string] $Pattern = "*"
    )
    
    Get-ChildItem -Path (Get-Location) -Recurse -Filter $Pattern -File
}

function File-Touch {
    param (
        [string] $Path
    )

    # Create the file if it does not exist
    if (-Not (Test-Path $Path)) {
        New-Item -ItemType File -Name $Path
    }

    # Update the timestamps of the file
    $file = Get-Item $Path
    $file.LastWriteTime = Get-Date
    $file.LastAccessTime = Get-Date
}

Set-Alias -Name search -Value File-Search
Set-Alias -Name touch -Value File-Touch

Export-ModuleMember -Function File-Search, File-Touch -Alias search, touch
