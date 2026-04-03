[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$File
)

if ($File) {
    start $File
    return
}

$solutionFiles = Get-ChildItem -Path '.\*' -Include '*.sln', '*.slnx' -File

if ($solutionFiles.Count -eq 1) {
    start $solutionFiles[0].FullName
    return
} elseif ($solutionFiles.Count -gt 1) {
    Write-Warning "Multiple solution files found. Please specify a file."
    return
}

$projectFiles = Get-ChildItem -Path '.\*' -Filter '*.csproj' -File

if ($projectFiles.Count -eq 1) {
    start $projectFiles[0].FullName
    return
} elseif ($projectFiles.Count -gt 1) {
    Write-Warning "Multiple project files found. Please specify a file."
    return
} else {
    Write-Warning "No solution or project files found in the current directory."
}
