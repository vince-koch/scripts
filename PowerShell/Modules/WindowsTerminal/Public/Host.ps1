function Is-WindowsTerminal {
    <#
    .SYNOPSIS
        Indicates whether the current shell is hosted by Windows Terminal.
    #>
    return -not [string]::IsNullOrWhiteSpace($env:WT_SESSION)
}

function Handle-WindowsTerminal {
    <#
    .SYNOPSIS
        Writes Windows Terminal host information when applicable.
    #>
    if (-not (Is-WindowsTerminal)) { return }

    Write-Host 'Windows Terminal' -ForegroundColor Green
    if ($env:WT_PROFILE_ID) {
        Write-Host "Profile: $env:WT_PROFILE_ID" -ForegroundColor DarkGray
    }
}
