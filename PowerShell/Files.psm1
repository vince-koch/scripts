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

Export-ModuleMember -Function File-Search
Export-ModuleMember -Function File-Touch

Set-Alias search File-Search
Set-Alias touch File-Touch