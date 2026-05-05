#Requires -Version 5.1
<#
.SYNOPSIS
    Cleans build artifacts from .NET solutions and projects.

.DESCRIPTION
    Recursively searches from the current directory for .sln/.slnx and .csproj
    files, then removes associated build artifact folders.

    For solution files (*.sln, *.slnx):  removes .vs/, .vscode/, build/
    For project files  (*.csproj):        removes bin/, obj/
    For orphaned projects:                removes entire folder if it only contains
                                          empty bin/ and/or obj/ subdirectories

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

function Get-OrphanedProjectFolders {
    param(
        [string]$RootPath,
        [array]$AllItems
    )
    
    # Build a hashtable of parent paths to their children
    $childrenByParent = @{}
    
    foreach ($item in $AllItems) {
        $parent = $item.PSParentPath -replace '^.*::', ''
        if (-not $childrenByParent.ContainsKey($parent)) {
            $childrenByParent[$parent] = @()
        }
        $childrenByParent[$parent] += $item
    }
    
    # Helper function to check if a path is orphaned
    function Test-IsOrphaned {
        param([string]$DirPath)
        
        $children = $childrenByParent[$DirPath]
        
        # Must have exactly 2 children
        if (-not $children -or $children.Count -ne 2) { return $false }
        
        # Must have no files (all children must be directories)
        $files = @($children | Where-Object { -not $_.PSIsContainer })
        if ($files.Count -gt 0) { return $false }
        
        # Must have exactly bin and obj directories
        $dirs = @($children | Where-Object { $_.PSIsContainer })
        $dirNames = $dirs | ForEach-Object { $_.Name }
        
        return ($dirNames -contains 'bin' -and $dirNames -contains 'obj')
    }
    
    # Find directories that have no files and exactly bin + obj subdirectories
    $orphaned = @()
    
    # Check the root path itself first
    if (Test-IsOrphaned -DirPath $RootPath) {
        $orphaned += Get-Item -Path $RootPath
    }
    
    # Check all subdirectories
    foreach ($dir in ($AllItems | Where-Object { $_.PSIsContainer })) {
        # Skip if this is itself a bin or obj folder
        if ($dir.Name -in 'bin', 'obj') { continue }
        
        if (Test-IsOrphaned -DirPath $dir.FullName) {
            $orphaned += $dir
        }
    }
    
    return $orphaned
}

# ── Main ─────────────────────────────────────────────────────────────────────

if ($DryRun) {
    Write-Host "`n[DRY RUN MODE] No files will be deleted.`n" -ForegroundColor Yellow
}

Write-Host "Searching for .NET artifacts under: $Path" -ForegroundColor White

# ── Scan directories with progress ───────────────────────────────────────────

$topLevelDirs = @(Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue)
$allItems = @()
$allFiles = @()

if ($topLevelDirs.Count -eq 0) {
    # No subdirectories, just scan the root
    Write-Host "`nScanning root directory..." -ForegroundColor Gray
    $allItems = @(Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue)
    $allFiles = @($allItems | Where-Object { -not $_.PSIsContainer } | Where-Object { $_.Extension -in '.sln', '.slnx', '.csproj' })
} else {
    Write-Header "Scanning $($topLevelDirs.Count) top-level directories..."
    
    $counter = 0
    foreach ($dir in $topLevelDirs) {
        $counter++
        Write-Host "  [$counter/$($topLevelDirs.Count)] $($dir.Name)..." -ForegroundColor Gray -NoNewline
        
        # Add the top-level directory itself to allItems
        $allItems += $dir
        
        # Add its contents recursively
        $items = @(Get-ChildItem -Path $dir.FullName -Recurse -ErrorAction SilentlyContinue)
        $allItems += $items
        
        $files = @($items | Where-Object { -not $_.PSIsContainer } | Where-Object { $_.Extension -in '.sln', '.slnx', '.csproj' })
        $allFiles += $files
        
        Write-Host " done" -ForegroundColor Gray
    }
}

# ── Solution files ────────────────────────────────────────────────────────────

Write-Header "Searching for solution files..."

$solutionFolders = @('.vs', '.vscode', 'build')
$solutionFiles = @($allFiles | Where-Object { $_.Extension -in '.sln', '.slnx' })

if ($solutionFiles.Count -gt 0) {
    Write-Host "Solution files found: $($solutionFiles.Count)" -ForegroundColor White

    foreach ($file in $solutionFiles) {
        Write-Host "  $($file.FullName)" -ForegroundColor White
        foreach ($folder in $solutionFolders) {
            Remove-ArtifactFolder -ParentDir $file.DirectoryName -FolderName $folder
        }
    }
} else {
    Write-Host "No solution files found." -ForegroundColor DarkGray
}

# ── Project files ─────────────────────────────────────────────────────────────

Write-Header "Searching for project files..."

$projectFolders = @('bin', 'obj')
$projectFiles = @($allFiles | Where-Object { $_.Extension -eq '.csproj' })

if ($projectFiles.Count -gt 0) {
    Write-Host "Project files found: $($projectFiles.Count)" -ForegroundColor White

    foreach ($file in $projectFiles) {
        Write-Host "  $($file.FullName)" -ForegroundColor White
        foreach ($folder in $projectFolders) {
            Remove-ArtifactFolder -ParentDir $file.DirectoryName -FolderName $folder
        }
    }
} else {
    Write-Host "No project files found." -ForegroundColor DarkGray
}

# ── Orphaned project folders ──────────────────────────────────────────────────

Write-Header "Searching for orphaned project folders..."

# Use items already collected from the single scan
$orphanedFolders = @(Get-OrphanedProjectFolders -RootPath $Path -AllItems $allItems)

if ($orphanedFolders.Count -gt 0) {
    Write-Host "Orphaned project folders found: $($orphanedFolders.Count)" -ForegroundColor White
    
    foreach ($folder in $orphanedFolders) {
        Write-Host "  $($folder.FullName)" -ForegroundColor White -NoNewline
        
        if ($DryRun) {
            Write-Host "  [DRY RUN] Would remove entire folder" -ForegroundColor Yellow
        } else {
            try {
                Remove-Item -Recurse -Force -Path $folder.FullName
                Write-Host "  Removed entire folder" -ForegroundColor Green
            } catch {
                Write-Warning "  Failed to remove '$($folder.FullName)': $_"
            }
        }
    }
} else {
    Write-Host "No orphaned project folders found." -ForegroundColor DarkGray
}

Write-Host "`nDone.`n" -ForegroundColor Cyan