#Requires -Version 5.1
<#
.SYNOPSIS
    Cleans build artifacts from .NET solutions and projects.

.DESCRIPTION
    Recursively searches from the current directory for .sln/.slnx and .csproj
    files, then removes associated build artifact folders.

    For solution files (*.sln, *.slnx):  removes .vs/, .vscode/, build/
    For project files  (*.csproj):        removes bin/, obj/

.PARAMETER DryRun
    When specified, shows what would be deleted without actually deleting anything.

.PARAMETER Path
    The root path to start searching from. Defaults to the current directory.

.EXAMPLE
    .\dotnet-clean.ps1

.EXAMPLE
    .\dotnet-clean.ps1 -DryRun

.EXAMPLE
    .\dotnet-clean.ps1 -Path C:\Projects
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [switch]$DryRun,
    [string]$Path = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Header {
    param([string]$Message)
    Write-Host "`n$Message" -ForegroundColor Cyan
}

function Remove-ArtifactFolder {
    param(
        [string]$ParentDir,
        [string]$FolderName
    )

    $target = Join-Path $ParentDir $FolderName

    if (-not (Test-Path $target)) { return }

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would remove: $target" -ForegroundColor Yellow
    } else {
        try {
            Remove-Item -Recurse -Force -Path $target
            Write-Host "  Removed: $target" -ForegroundColor Green
        } catch {
            Write-Warning "  Failed to remove '$target': $_"
        }
    }
}

# ── Main ─────────────────────────────────────────────────────────────────────

if ($DryRun) {
    Write-Host "`n[DRY RUN MODE] No files will be deleted.`n" -ForegroundColor Yellow
}

Write-Host "Searching for .NET artifacts under: $Path" -ForegroundColor White

# ── Solution files ────────────────────────────────────────────────────────────

$solutionFolders = @('.vs', '.vscode', 'build')

$solutionFiles = Get-ChildItem -Path $Path -Recurse -Include '*.sln', '*.slnx' -File -ErrorAction SilentlyContinue

if ($solutionFiles.Count -gt 0) {
    Write-Header "Solution files found: $($solutionFiles.Count)"
    foreach ($file in $solutionFiles) {
        Write-Host "`n  $($file.FullName)" -ForegroundColor White
        foreach ($folder in $solutionFolders) {
            Remove-ArtifactFolder -ParentDir $file.DirectoryName -FolderName $folder
        }
    }
} else {
    Write-Host "`nNo solution files found." -ForegroundColor DarkGray
}

# ── Project files ─────────────────────────────────────────────────────────────

$projectFolders = @('bin', 'obj')

$projectFiles = Get-ChildItem -Path $Path -Recurse -Include '*.csproj' -File -ErrorAction SilentlyContinue

if ($projectFiles.Count -gt 0) {
    Write-Header "Project files found: $($projectFiles.Count)"
    foreach ($file in $projectFiles) {
        Write-Host "`n  $($file.FullName)" -ForegroundColor White
        foreach ($folder in $projectFolders) {
            Remove-ArtifactFolder -ParentDir $file.DirectoryName -FolderName $folder
        }
    }
} else {
    Write-Host "`nNo project files found." -ForegroundColor DarkGray
}

Write-Host "`nDone.`n" -ForegroundColor Cyan