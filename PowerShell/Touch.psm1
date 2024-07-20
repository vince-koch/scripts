function Touch-File {
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

Export-ModuleMember -Function Touch-File

Set-Alias touch Touch-File