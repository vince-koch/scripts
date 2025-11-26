param (
    [string] $requestedVersion = $null
)

if (-not (Get-Module -Name Linq)) {
    Import-Module $PSScriptRoot\Linq.psm1 -DisableNameChecking -Force
}

if (-not (Get-Module -Name Console)) {
    Import-Module $PSScriptRoot\Console.psm1 -DisableNameChecking -Force
}

class VsVersion {
    [string]$Version
    [string]$Year
    [string]$PathPart

    VsVersion([string]$version, [string]$year, [string]$pathPart) {
        $this.Version = $version
        $this.Year = $year
        $this.PathPart = $pathPart
    }
}

$Versions = @(
    [VsVersion]::new("18", "2026", "18"),
    [VsVersion]::new("17", "2022", "2022"),
    [VsVersion]::new("16", "2019", "2019"),
    [VsVersion]::new("15", "2017", "2017")
)


function Main
{
    [string] $solutionPath = GetSolutionPath
    Write-Host "    Solution Path: " -ForegroundColor DarkGray -NoNewLine
    Write-Host "$($solutionPath)"

    [VsVersion] $solutionVersion = GetVersionFromSolution $solutionPath
    Write-Host " Solution Version: " -ForegroundColor DarkGray -NoNewLine
    Write-Host "$($solutionVersion)"

    [VsVersion] $requestedMatch = $null
    if ([string]::IsNullOrWhiteSpace($requestedVersion) -eq $false)
    {
        $requestedMatch = $Versions |
            Where-Object { $_.Version -eq $requestedVersion -or $_.Year -eq $requestedVersion } |
            Select-Object -First 1

        Write-Host "Requested Version: " -ForegroundColor DarkGray -NoNewline
        Write-Host "$($requestedVersion)"
    }

    $devEnvPath = FindMatchingDevEnvPath $requestedMatch $solutionVersion
    
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
            [string[]] $slnFiles = [System.IO.Directory]::GetFiles($searchPath, "*.sln", [System.IO.SearchOption]::TopDirectoryOnly)
            [string[]] $slnxFiles = [System.IO.Directory]::GetFiles($searchPath, "*.slnx", [System.IO.SearchOption]::TopDirectoryOnly)
            [string[]] $files = $slnFiles + $slnxFiles

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



function GetVersionFromSolution{
    param ( [string] $solutionPath )

    try
    {
        if ([System.IO.Path]::GetExtension($solutionPath) -ieq ".slnx")
        {
            $first = $Versions | Select-Object -First 1
            return $first
        }

        [string] $VisualStudioLine = "# Visual Studio ";

        [string] $version = [System.IO.File]::ReadAllLines($solutionPath) `
            | Where-Object {$_.StartsWith($VisualStudioLine)} `
            | Linq-Select {$_.Substring($_.LastIndexOf(' ')).Trim()} `
            | Linq-Single
		
        $year = $Versions | Where-Object { $_.Version -eq $version } | Select-Object -First 1

        return $year
    }
    catch
    {
        throw "Unable to determine version from solution file [$_]"
    }
}

function FindMatchingDevEnvPath {
    param ([VsVersion] $requestedVersion, [VsVersion] $solutionVersion)

    [VsVersion[]] $allVersions = @(
        $requestedVersion,
        $solutionVersion
    ) + $Versions

    $allVersions = $allVersions | Where-Object { $_ -ne $null }

    $devEnvPath = GetDevEnvPath $allVersions
    Write-Host "   VS DevEnv Path: " -ForegroundColor DarkGray -NoNewline
    Write-Host "$($devEnvPath)"

    return $devEnvPath
}

function GetDevEnvPath {
    param ( [VsVersion[]] $allVersions )

    [string[]] $programFiles = (    
        [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFilesX86),
        [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)
    )
    
    [string[]] $editions = (
        "Enterprise",
        "Professional",
        "Community"
    )
    
    foreach ($item in $allVersions)
    {
        if ([string]::IsNullOrWhiteSpace($item.PathPart))
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
                    $item.PathPart,
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