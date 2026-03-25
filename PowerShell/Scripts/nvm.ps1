# nvm.ps1 - Node Version Manager for Windows (no admin required)
# Manages NVM_HOME, NVM_CURRENT, and PATH at the user environment level

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────

function Get-UserEnv($name) {
    [System.Environment]::GetEnvironmentVariable($name, "User")
}

function Set-UserEnv($name, $value) {
    [System.Environment]::SetEnvironmentVariable($name, $value, "User")
    # Also update the current session
    Set-Item -Path "Env:$name" -Value $value
}

function Get-NvmHome {
    $nvmHomeDir = Get-UserEnv "NVM_HOME"
    if (-not $nvmHomeDir) {
        Write-Host ""
        Write-Host "NVM_HOME is not set." -ForegroundColor Yellow
        $nvmHomeDir = Read-Host "Enter the path where Node versions should be stored (e.g. C:\Users\You\nvm)"
        $nvmHomeDir = $nvmHomeDir.Trim().TrimEnd('\')
        if (-not $nvmHomeDir) {
            Write-Error "No path provided. Aborting."
        }
        if (-not (Test-Path $nvmHomeDir)) {
            $create = Read-Host "Directory '$nvmHomeDir' does not exist. Create it? [Y/n]"
            if ($create -eq '' -or $create -match '^[Yy]') {
                New-Item -ItemType Directory -Path $nvmHomeDir -Force | Out-Null
                Write-Host "Created: $nvmHomeDir" -ForegroundColor Green
            } else {
                Write-Error "Directory not created. Aborting."
            }
        }
        Set-UserEnv "NVM_HOME" $nvmHomeDir
        Write-Host "NVM_HOME set to: $nvmHomeDir" -ForegroundColor Green
    }
    return $nvmHomeDir
}

function Get-Arch {
    if ([System.Environment]::Is64BitOperatingSystem) { return "x64" }
    else { return "x86" }
}

function Get-NodeZipName($version, $arch) {
    # e.g. node-v20.11.0-win-x64.zip
    $v = $version.TrimStart('v')
    return "node-v$v-win-$arch.zip"
}

function Get-NodeDownloadUrl($version, $arch) {
    $zip = Get-NodeZipName $version $arch
    return "https://nodejs.org/dist/v$($version.TrimStart('v'))/$zip"
}

function Get-InstalledVersions($nvmHome) {
    if (-not (Test-Path $nvmHome)) { return @() }
    @(Get-ChildItem -Path $nvmHome -Directory |
        Where-Object { $_.Name -match '^v?\d+\.\d+\.\d+$' } |
        Select-Object -ExpandProperty Name |
        Sort-Object { [Version]($_ -replace '^v','') } -Descending)
}

function Normalize-Version($version) {
    # Accept "18", "18.20", "18.20.4", with or without leading "v"
    $v = $version.TrimStart('v')
    $parts = $v -split '\.'
    switch ($parts.Count) {
        1 { return "v$($parts[0]).x.x" }   # partial – used for search
        2 { return "v$($parts[0]).$($parts[1]).x" }
        3 { return "v$v" }
        default { Write-Error "Invalid version format: $version" }
    }
}

function Exact-Version($version) {
    $v = $version.TrimStart('v')
    $parts = $v -split '\.'
    return ($parts.Count -eq 3)
}

# ─────────────────────────────────────────────
#  PATH helpers
# ─────────────────────────────────────────────

function Update-PathForNode($nvmHome, $versionFolder) {
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $entries  = $userPath -split ';' | Where-Object { $_ -ne '' }

    # Remove any entries that live under NVM_HOME
    $nvmHomeNorm = $nvmHome.TrimEnd('\').ToLower()
    $cleaned = $entries | Where-Object {
        -not $_.ToLower().StartsWith($nvmHomeNorm)
    }

    # Prepend the new version
    $newPath = (@($versionFolder) + $cleaned) -join ';'
    Set-UserEnv "PATH" $newPath

    # Also patch the current session's PATH
    $syspath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $env:PATH = "$versionFolder;$syspath"
}

# ─────────────────────────────────────────────
#  Commands
# ─────────────────────────────────────────────

function Cmd-Home($args) {
    if ($args.Count -eq 0) {
        $h = Get-UserEnv "NVM_HOME"
        if ($h) { Write-Host $h }
        else    { Write-Host "(NVM_HOME is not set)" -ForegroundColor Yellow }
    } else {
        $path = $args[0].Trim().TrimEnd('\')
        if (-not (Test-Path $path)) {
            $create = Read-Host "Directory '$path' does not exist. Create it? [Y/n]"
            if ($create -eq '' -or $create -match '^[Yy]') {
                New-Item -ItemType Directory -Path $path -Force | Out-Null
                Write-Host "Created: $path" -ForegroundColor Green
            } else {
                Write-Host "Aborted." -ForegroundColor Yellow
                return
            }
        }
        Set-UserEnv "NVM_HOME" $path
        Write-Host "NVM_HOME set to: $path" -ForegroundColor Green
    }
}

function Cmd-Install($version) {
    if (-not $version) { Write-Host "Usage: nvm install <version>" -ForegroundColor Red; return }

    if (-not (Exact-Version $version)) {
        Write-Host "Please supply a full version number, e.g. 20.11.0" -ForegroundColor Red
        return
    }

    $nvmHome = Get-NvmHome
    $arch    = Get-Arch
    $ver     = "v$($version.TrimStart('v'))"
    $dest    = Join-Path $nvmHome $ver

    if (Test-Path $dest) {
        Write-Host "Node $ver is already installed at $dest" -ForegroundColor Yellow
        return
    }

    $zipName = Get-NodeZipName $version $arch
    $url     = Get-NodeDownloadUrl $version $arch
    $tmp     = Join-Path $env:TEMP $zipName

    Write-Host "Downloading $url ..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
    } catch {
        Write-Host "Download failed. Check the version number and your internet connection." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkRed
        return
    }

    Write-Host "Extracting to $nvmHome ..." -ForegroundColor Cyan
    $extractDir = Join-Path $env:TEMP "nvm_extract_$ver"
    if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
    Expand-Archive -Path $tmp -DestinationPath $extractDir -Force

    # The zip contains a single top-level folder like node-v20.11.0-win-x64
    $inner = Get-ChildItem $extractDir -Directory | Select-Object -First 1
    if (-not $inner) {
        Write-Host "Unexpected archive structure. Aborting." -ForegroundColor Red
        return
    }

    Move-Item $inner.FullName $dest
    Remove-Item $extractDir -Recurse -Force
    Remove-Item $tmp -Force

    Write-Host "Installed Node $ver -> $dest" -ForegroundColor Green
    Write-Host "Run 'nvm use $ver' to activate it." -ForegroundColor DarkGray
}

function Cmd-Uninstall($version) {
    if (-not $version) { Write-Host "Usage: nvm uninstall <version>" -ForegroundColor Red; return }

    $nvmHome = Get-NvmHome
    $ver     = "v$($version.TrimStart('v'))"
    $dest    = Join-Path $nvmHome $ver

    if (-not (Test-Path $dest)) {
        Write-Host "Node $ver is not installed." -ForegroundColor Yellow
        return
    }

    # Warn if it's the active version
    $current = Get-UserEnv "NVM_CURRENT"
    if ($current -and ($current.ToLower() -eq $dest.ToLower())) {
        Write-Host "Warning: $ver is the currently active version." -ForegroundColor Yellow
        $confirm = Read-Host "Uninstall anyway? [y/N]"
        if ($confirm -notmatch '^[Yy]') { Write-Host "Aborted."; return }

        # Remove from PATH and clear NVM_CURRENT
        $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        $nvmHomeNorm = $nvmHome.TrimEnd('\').ToLower()
        $cleaned = ($userPath -split ';') | Where-Object {
            -not $_.ToLower().StartsWith($nvmHomeNorm)
        }
        Set-UserEnv "PATH" ($cleaned -join ';')
        Set-UserEnv "NVM_CURRENT" ""
        Write-Host "Removed $ver from PATH and cleared NVM_CURRENT." -ForegroundColor DarkGray
    }

    Remove-Item $dest -Recurse -Force
    Write-Host "Uninstalled Node $ver." -ForegroundColor Green
}

function Cmd-Use($version) {
    if (-not $version) { Write-Host "Usage: nvm use <version>" -ForegroundColor Red; return }

    $nvmHome = Get-NvmHome
    $ver     = "v$($version.TrimStart('v'))"
    $dest    = Join-Path $nvmHome $ver

    if (-not (Test-Path $dest)) {
        Write-Host "Node $ver is not installed. Run: nvm install $ver" -ForegroundColor Red
        return
    }

    Set-UserEnv "NVM_CURRENT" $dest
    Update-PathForNode $nvmHome $dest

    Write-Host "Now using Node $ver" -ForegroundColor Green
    Write-Host "(Restart your shell or open a new terminal for PATH changes to take full effect.)" -ForegroundColor DarkGray
}

function Cmd-List {
    $nvmHome = Get-NvmHome
    $versions = @(Get-InstalledVersions $nvmHome)
    $current  = Get-UserEnv "NVM_CURRENT"

    # Extract just the version folder name from NVM_CURRENT (e.g. "v20.11.0")
    $currentVersion = if ($current) { Split-Path $current -Leaf } else { $null }

    if ($versions.Count -eq 0) {
        Write-Host "No Node versions installed. Run: nvm install <version>" -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "Installed Node versions (in $nvmHome):" -ForegroundColor Cyan
    foreach ($v in $versions) {
        $isActive = $currentVersion -and ($currentVersion.ToLower() -eq $v.ToLower())
        $marker = if ($isActive) { " *" } else { "  " }
        $color  = if ($isActive) { "Green" } else { "White" }
        Write-Host "$marker $v" -ForegroundColor $color
    }
    Write-Host ""
    if ($currentVersion) {
        Write-Host "  * = active ($current)" -ForegroundColor DarkGray
    }
}

function Cmd-Search($filter) {
    $arch = Get-Arch
    $indexUrl = "https://nodejs.org/dist/index.json"

    Write-Host "Fetching release list from nodejs.org ..." -ForegroundColor Cyan
    try {
        $json = Invoke-RestMethod -Uri $indexUrl -UseBasicParsing
    } catch {
        Write-Host "Failed to fetch release list." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkRed
        return
    }

    # Filter to releases that have a Windows zip for our arch.
    # The index.json "files" property is an array of strings like:
    #   ["win-x64-zip", "win-x86-zip", "src", ...]
    $winField = "win-$arch-zip"
    $releases = @($json | Where-Object {
        $_.files -contains $winField
    })

    # Optional partial filter — matches anywhere in the version string
    # e.g. "20" matches v20.x.x, "20.11" matches v20.11.x, "lts" could match codenames if added later
    if ($filter) {
        $needle = $filter.TrimStart('v')
        $releases = @($releases | Where-Object { $_.version -like "*$needle*" })
    }

    if (-not $releases -or @($releases).Count -eq 0) {
        Write-Host "No releases found matching '$filter' for $arch." -ForegroundColor Yellow
        return
    }

    # Show at most 30 results
    $releases = @($releases) | Select-Object -First 30

    # Get installed set for annotation
    $nvmHomeVal = Get-UserEnv "NVM_HOME"
    $installed  = @{}
    if ($nvmHomeVal -and (Test-Path $nvmHomeVal)) {
        Get-InstalledVersions $nvmHomeVal | ForEach-Object { $installed[$_] = $true }
    }

    Write-Host ""
    Write-Host ("Available Node releases for win-$arch (showing up to 30):") -ForegroundColor Cyan
    Write-Host ("{0,-12} {1,-10} {2}" -f "Version", "LTS", "Date") -ForegroundColor DarkGray
    Write-Host ("{0,-12} {1,-10} {2}" -f "-------", "---", "----") -ForegroundColor DarkGray

    foreach ($r in $releases) {
        $lts   = if ($r.lts -and $r.lts -ne $false) { $r.lts } else { "-" }
        $inst  = if ($installed.ContainsKey($r.version)) { " [installed]" } else { "" }
        $color = if ($installed.ContainsKey($r.version)) { "Green" } else { "White" }
        Write-Host ("{0,-12} {1,-10} {2}{3}" -f $r.version, $lts, $r.date, $inst) -ForegroundColor $color
    }
    Write-Host ""
    Write-Host "Run 'nvm install <version>' to install any of the above." -ForegroundColor DarkGray
}

# ─────────────────────────────────────────────
#  Entry point
# ─────────────────────────────────────────────

function Show-Help {
    Write-Host ""
    Write-Host "nvm.ps1 - Node Version Manager (user-level, no admin required)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\nvm.ps1 home                  Print NVM_HOME"
    Write-Host "  .\nvm.ps1 home <path>           Set NVM_HOME"
    Write-Host "  .\nvm.ps1 install <version>     Download and install Node (e.g. 20.11.0)"
    Write-Host "  .\nvm.ps1 uninstall <version>   Remove an installed Node version"
    Write-Host "  .\nvm.ps1 use <version>         Switch the active Node version"
    Write-Host "  .\nvm.ps1 list                  List installed versions"
    Write-Host "  .\nvm.ps1 search [prefix]       Search available releases on nodejs.org"
    Write-Host ""
    Write-Host "Environment variables managed:" -ForegroundColor Yellow
    Write-Host "  NVM_HOME    Root folder containing all Node installations"
    Write-Host "  NVM_CURRENT Path to the currently active Node installation"
    Write-Host "  PATH        Updated on 'use' to point to the active Node"
    Write-Host ""
}

# ── Parse arguments ──────────────────────────

$cmd     = if ($args.Count -gt 0) { $args[0].ToLower() } else { "" }
$cmdArgs = if ($args.Count -gt 1) { $args[1..($args.Count-1)] } else { @() }

switch ($cmd) {
    "home"      { Cmd-Home      $cmdArgs }
    "install"   { Cmd-Install   ($cmdArgs | Select-Object -First 1) }
    "uninstall" { Cmd-Uninstall ($cmdArgs | Select-Object -First 1) }
    "use"       { Cmd-Use       ($cmdArgs | Select-Object -First 1) }
    "list"      { Cmd-List }
    "ls"        { Cmd-List }
    "search"    { Cmd-Search    ($cmdArgs | Select-Object -First 1) }
    default     { Show-Help }
}