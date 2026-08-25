$script:WindowsTerminalSettingsPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'

function Read-WindowsTerminalJson {
    param([Parameter(Mandatory)][string]$Path)
    $json = (Get-Content -LiteralPath $Path | Where-Object { -not $_.TrimStart().StartsWith('//') }) -join "`n"
    $json | ConvertFrom-Json
}

function Get-WindowsTerminalSettings {
    if (-not (Test-Path -LiteralPath $script:WindowsTerminalSettingsPath)) {
        throw "Windows Terminal settings not found: $script:WindowsTerminalSettingsPath"
    }
    $settings = Read-WindowsTerminalJson $script:WindowsTerminalSettingsPath
    $package = Get-AppxPackage -Name Microsoft.WindowsTerminal -ErrorAction SilentlyContinue
    $defaultPath = if ($package.InstallLocation) { Join-Path $package.InstallLocation 'defaults.json' }
    if (-not $defaultPath -or -not (Test-Path -LiteralPath $defaultPath)) {
        $defaultPath = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\defaults.json'
    }
    if (Test-Path -LiteralPath $defaultPath) {
        $schemes = @{}
        foreach ($scheme in @((Read-WindowsTerminalJson $defaultPath).schemes) + @($settings.schemes)) {
            if ($scheme.name) { $schemes[$scheme.name] = $scheme }
        }
        $settings | Add-Member NoteProperty schemes @($schemes.Values) -Force
    }
    $settings
}

function Write-WindowsTerminalSettingsLines {
    param([Parameter(Mandatory)][string[]]$Lines)

    $settingsDirectory = Split-Path $script:WindowsTerminalSettingsPath -Parent
    $operationId = [guid]::NewGuid()
    $temporaryPath = Join-Path $settingsDirectory ('.settings-{0}.tmp' -f $operationId)
    $backupPath = Join-Path $settingsDirectory ('.settings-{0}.bak' -f $operationId)
    try {
        $content = $Lines -join [Environment]::NewLine
        [IO.File]::WriteAllText($temporaryPath, $content, [Text.UTF8Encoding]::new($false))
        [IO.File]::Replace($temporaryPath, $script:WindowsTerminalSettingsPath, $backupPath)
    }
    finally {
        if ([IO.File]::Exists($temporaryPath)) {
            [IO.File]::Delete($temporaryPath)
        }
        if ([IO.File]::Exists($backupPath)) {
            [IO.File]::Delete($backupPath)
        }
    }
}

function Write-WindowsTerminalThemeName {
    param([Parameter(Mandatory)][string]$Name)
    $lines = @(Get-Content -LiteralPath $script:WindowsTerminalSettingsPath)
    $token = '"colorScheme":'
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $position = $lines[$index].IndexOf($token)
        if ($position -lt 0) { continue }
        $prefix = $lines[$index].Substring(0, $position + $token.Length)
        $comma = if ($lines[$index].TrimEnd().EndsWith(',')) { ',' } else { '' }
        $lines[$index] = "$prefix `"$Name`"$comma"
    }
    Write-WindowsTerminalSettingsLines -Lines $lines
}

function Update-WindowsTerminalDefaultProperties {
    param(
        [hashtable]$Set = @{},
        [string[]]$Remove = @()
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.AddRange([string[]](Get-Content -LiteralPath $script:WindowsTerminalSettingsPath))
    $defaultsKey = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^\s*"defaults"\s*:') { $defaultsKey = $index; break }
    }

    if ($defaultsKey -lt 0) {
        if ($Set.Count -eq 0) { return }
        $profilesKey = -1; $listKey = -1
        for ($index = 0; $index -lt $lines.Count; $index++) {
            if ($profilesKey -lt 0 -and $lines[$index] -match '^\s*"profiles"\s*:') { $profilesKey = $index; continue }
            if ($profilesKey -ge 0 -and $lines[$index] -match '^\s*"list"\s*:') { $listKey = $index; break }
        }
        if ($listKey -lt 0) { throw 'Unable to find profiles.list in Windows Terminal settings.' }

        $indent = [regex]::Match($lines[$listKey], '^\s*').Value
        $lines.Insert($listKey, "$indent`"defaults`":")
        $lines.Insert($listKey + 1, "$indent{")
        $lines.Insert($listKey + 2, "$indent},")
        $defaultsKey = $listKey
    }

    $start = -1
    for ($index = $defaultsKey; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '\{') { $start = $index; break }
        if ($index -gt $defaultsKey + 3) { break }
    }
    if ($start -lt 0) { throw 'Unable to find the profiles.defaults object.' }

    if ($start -eq $defaultsKey -and $lines[$start] -match '^(\s*)"defaults"\s*:\s*\{(.+)\}\s*(,?)\s*$') {
        $indent = $matches[1]; $innerJson = '{' + $matches[2] + '}'; $comma = $matches[3]
        $properties = @((ConvertFrom-Json $innerJson).PSObject.Properties)
        $lines[$start] = "$indent`"defaults`":"
        $lines.Insert($start + 1, "$indent{")
        $insertAt = $start + 2
        foreach ($property in $properties) {
            $value = $property.Value | ConvertTo-Json -Compress
            $lines.Insert($insertAt, "$indent    `"$($property.Name)`": $value,")
            $insertAt++
        }
        if ($properties.Count -gt 0) { $lines[$insertAt - 1] = $lines[$insertAt - 1].TrimEnd(',') }
        $lines.Insert($insertAt, "$indent}$comma")
        $start++
    }

    if ($lines[$start] -match '\{\s*\}\s*,?\s*$') {
        $indent = ([regex]::Match($lines[$start], '^\s*').Value)
        $comma = if ($lines[$start].TrimEnd().EndsWith(',')) { ',' } else { '' }
        if ($start -eq $defaultsKey) {
            $lines[$start] = "$indent`"defaults`":"
            $lines.Insert($start + 1, "$indent{")
            $lines.Insert($start + 2, "$indent}$comma")
            $start++
        }
        else {
            $lines[$start] = "$indent{"
            $lines.Insert($start + 1, "$indent}$comma")
        }
    }

    $depth = 0; $end = -1
    for ($index = $start; $index -lt $lines.Count; $index++) {
        $depth += ([regex]::Matches($lines[$index], '\{')).Count
        $depth -= ([regex]::Matches($lines[$index], '\}')).Count
        if ($index -gt $start -and $depth -eq 0) { $end = $index; break }
    }
    if ($end -lt 0) { throw 'Unable to find the end of profiles.defaults.' }

    $propertyNames = @($Set.Keys) + @($Remove) | Sort-Object -Unique
    for ($index = $end - 1; $index -gt $start; $index--) {
        if ($lines[$index] -match '^\s*"([^\"]+)"\s*:') {
            $name = $matches[1]
            if ($name -in $propertyNames) { $lines.RemoveAt($index); $end-- }
        }
    }

    $indent = ([regex]::Match($lines[$start], '^\s*').Value) + '    '
    if ($Set.Count -gt 0 -and $end -gt $start + 1) {
        $lines[$end - 1] = $lines[$end - 1].TrimEnd(',') + ','
    }
    foreach ($name in @($Set.Keys | Sort-Object)) {
        $jsonValue = $Set[$name] | ConvertTo-Json -Compress
        $lines.Insert($end, "$indent`"$name`": $jsonValue,")
        $end++
    }
    if ($end -gt $start + 1) {
        $lines[$end - 1] = $lines[$end - 1].TrimEnd(',')
    }
    Write-WindowsTerminalSettingsLines -Lines $lines
}
