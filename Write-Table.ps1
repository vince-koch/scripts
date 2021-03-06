function Write-Table
{
    param ([array] $items)
    Write-Host ($items | Format-Table | Out-String).Trim()
}

function Write-Objects
{
    param ($items)
    Write-Host ($items | Out-String).Trim()
}