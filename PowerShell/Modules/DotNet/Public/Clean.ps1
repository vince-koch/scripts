function Clear-DotNetArtifacts {
    <#
    .SYNOPSIS
        Removes build artifacts from .NET solutions and projects.
    .DESCRIPTION
        Removes .vs, .vscode, and build directories beside solutions; bin and
        obj directories beside projects; and orphan folders containing only bin
        and obj. Use -DryRun to report targets without removing them.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$DryRun,

        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path
    )

    $rootPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    $items = @(Get-ChildItem -LiteralPath $rootPath -Recurse -Force -ErrorAction SilentlyContinue)
    $projectFiles = @($items | Where-Object { -not $_.PSIsContainer -and $_.Extension -eq '.csproj' })
    $solutionFiles = @($items | Where-Object { -not $_.PSIsContainer -and $_.Extension -in '.sln', '.slnx' })
    $targets = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($file in $solutionFiles) {
        foreach ($name in '.vs', '.vscode', 'build') {
            $candidate = Join-Path $file.DirectoryName $name
            if ([System.IO.Directory]::Exists($candidate)) { [void]$targets.Add($candidate) }
        }
    }
    foreach ($file in $projectFiles) {
        foreach ($name in 'bin', 'obj') {
            $candidate = Join-Path $file.DirectoryName $name
            if ([System.IO.Directory]::Exists($candidate)) { [void]$targets.Add($candidate) }
        }
    }

    $directories = @(
        Get-Item -LiteralPath $rootPath
        $items | Where-Object PSIsContainer
    )
    foreach ($directory in $directories) {
        if ($directory.Name -in 'bin', 'obj') { continue }
        if ($directory.Attributes -band [System.IO.FileAttributes]::ReparsePoint) { continue }
        $children = @(Get-ChildItem -LiteralPath $directory.FullName -Force -ErrorAction SilentlyContinue)
        $childNames = @($children | ForEach-Object Name | Sort-Object)
        if ($children.Count -eq 2 -and
            -not ($children | Where-Object { -not $_.PSIsContainer }) -and
            $childNames[0] -eq 'bin' -and $childNames[1] -eq 'obj') {
            [void]$targets.Add($directory.FullName)
        }
    }

    if ($targets.Count -eq 0) {
        Write-Host 'No .NET build artifacts found.' -ForegroundColor DarkGray
        return
    }

    foreach ($target in $targets | Sort-Object { $_.Length } -Descending) {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would remove: $target" -ForegroundColor Yellow
        }
        elseif ($PSCmdlet.ShouldProcess($target, 'Remove .NET build artifacts')) {
            Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop
            Write-Host "Removed: $target" -ForegroundColor Green
        }
    }
}
