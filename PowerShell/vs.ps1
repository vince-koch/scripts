param (
    [string] $requestedVersion = $null
)

Import-Module $PSScriptRoot\Linq.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Console.psm1 -DisableNameChecking -Force

function Main
{
    [string] $solutionPath = GetSolutionPath
    Write-Host "    Solution Path: " -ForegroundColor DarkGray -NoNewLine
    Write-Host "$($solutionPath)"

    [string] $solutionVersion = GetVersionFromSolution $solutionPath
    Write-Host " Solution Version: " -ForegroundColor DarkGray -NoNewLine
    Write-Host "$($solutionVersion)"

    if ([string]::IsNullOrWhiteSpace($requestedVersion) -eq $false)
    {
        Write-Host "Requested Version: " -ForegroundColor DarkGray -NoNewline
        Write-Host "$($requestedVersion)"
    }

    $devEnvPath = FindMatchingDevEnvPath  $solutionPath $requestedVersion $solutionVersion
    
    LaunchVisualStudioCode $solutionPath
    LaunchVisualStudio $devEnvPath $solutionPath
}

function LaunchVisualStudioCode {
    param ([string] $solutionPath)

    # look for spa project
    [string] $solutionDir = [System.IO.Path]::GetDirectoryName($solutionPath)
    [string[]] $directories = [System.IO.Directory]::GetDirectories($solutionDir, "*.Spa", [System.IO.SearchOption]::TopDirectoryOnly)
    if ($directories.Length -eq 1)
    {
        Write-Host
        $projectName = [System.IO.Path]::GetFileName($directories[0])
        $result = Console-Confirm "Open '$($projectName)' with vscode? [Y/n] "
        if ($result -eq $true)
        {
            vscode "$($directories[0])"
        }
    }
}

function LaunchVisualStudio {
    param ([string] $devEnvPath, [string] $solutionPath)

    Start-Process $devEnvPath "$($solutionPath)"
}

function GetSolutionPath
{
    [string] $currentDirectory = Get-Location

    [string[]] $searchPaths = (
        $currentDirectory,
        [System.IO.Path]::Combine($currentDirectory, "src"),
        [System.IO.Path]::Combine($currentDirectory, "source")
    )

    foreach ($searchPath in $searchPaths)
    {
        if ([System.IO.Directory]::Exists($searchPath))
        {
            [string[]] $files = [System.IO.Directory]::GetFiles($searchPath, "*.sln", [System.IO.SearchOption]::TopDirectoryOnly)
            if ($files.Length -eq 1)
            {
                [string] $file = [System.Linq.Enumerable]::Single($files)
                return $file
            }
            elseif ($files.Length -gt 1)
            {
                [string] $file = Console-Menu $files
                if ([string]::IsNullOrWhiteSpace($file) -eq $false)
                {
                    return $file
                }
            }
        }
    }

    throw "Unable to locate solution file"
}

function GetVersionFromSolution
{
    param ( [string] $solutionPath )

    try
    {
        [string] $VisualStudioLine = "# Visual Studio ";

        [string] $version = [System.IO.File]::ReadAllLines($solutionPath) `
            | Where-Object {$_.StartsWith($VisualStudioLine)} `
            | Linq-Select {$_.Substring($_.LastIndexOf(' ')).Trim()} `
            | Linq-Single
		
        $versionYearLookup = @{}
        $versionYearLookup.Add("16", "2019")
        $versionYearLookup.Add("15", "2017")

        $year = $versionYearLookup[$version]

        return $year
    }
    catch
    {
        throw "Unable to determine version from solution file [$_]"
    }
}

function FindMatchingDevEnvPath {
    param ([string] $solutionPath, [string] $requestedVersion, [string] $solutionVersion)

    [string[]] $years = (
        $requestedVersion,
        $solutionVersion,
        "2019",
        "2017"
    )

    $devEnvPath = GetDevEnvPath $years
    Write-Host "   VS DevEnv Path: " -ForegroundColor DarkGray -NoNewline
    Write-Host "$($devEnvPath)"

    return $devEnvPath
}

function GetDevEnvPath
{
    param ( [string[]] $years )

    [string[]] $programFiles = (    
        [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFilesX86),
        [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)
    )
    
    [string[]] $editions = (
        "Professional",
        "Community"
    )
    
    foreach ($year in $years)
    {
        if ([string]::IsNullOrWhiteSpace($year))
        {
            continue
        }

        foreach ($programFile in $programFiles)
        {
            foreach ($edition in $editions)
            {
                [string] $searchPath = [string]::Format(
                    "{0}\Microsoft Visual Studio\{1}\{2}\Common7\IDE\devenv.exe",
                    $programFile,
                    $year,
                    $edition)

                [bool] $exists = [System.IO.File]::Exists($searchPath)
                if ($exists -eq $true)
                {
                    return $searchPath;
                }                    
            }
        }
    }

    throw "Unable to locate installation of Visual Studio"
}


Main