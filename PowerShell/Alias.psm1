$script:ManifestPath = Join-Path $env:USERPROFILE ".aliases.json"

function Get-AliasManifest {
    if (Test-Path $script:ManifestPath) {
        $content = Get-Content $script:ManifestPath | ConvertFrom-Json -AsHashtable
        if ($null -eq $content) { return @{} }
        return $content
    } else {
        return @{}
    }
}

function Save-AliasManifest($data) {
    $data | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 $script:ManifestPath
}

function Register-AliasFunctions {
    $aliases = Get-AliasManifest
    foreach ($aliasName in $aliases.Keys) {
        $exePath = $aliases[$aliasName]
        $scriptBlock = [ScriptBlock]::Create("param([Parameter(ValueFromRemainingArguments = `$true)] `$args); & '$exePath' @args")
        Set-Item -Path "Function:Global:$aliasName" -Value $scriptBlock -Force
    }
}

function alias {
    param(
        [Parameter(Position = 0)] [string] $action,
        [Parameter(Position = 1)] [string] $name,
        [Parameter(Position = 2)] [string] $path
    )

    $aliases = Get-AliasManifest

    switch ($action) {
        'help' {
            Write-Host "Alias Management Commands:"
            Write-Host "------------------------"
            Write-Host "list   - Lists all registered aliases"
            Write-Host "add    - Adds a new alias (alias add <name> <path>)"
            Write-Host "remove - Removes an existing alias (alias remove <name>)"
            Write-Host "help   - Shows this help message"
            Write-Host ""
            Write-Host "Examples:"
            Write-Host "  alias add notepad 'C:\Windows\notepad.exe'"
            Write-Host "  alias remove notepad"
            Write-Host "  alias list"
        }

        'list' {
            if ($aliases.Count -eq 0) {
                Write-Output "No aliases registered."
                return
            }

            $aliases.Keys | ForEach-Object {
                [PSCustomObject]@{
                    Name = $_
                    Path = $aliases[$_]
                }
            } | Format-Table -AutoSize
        }

        'add' {
            # Try to resolve the path, checking current directory first
            $resolvedPath = $null
            $searchPaths = @(
                $PWD.Path,  # Current directory
                $env:Path -split ';'  # System PATH
            )

            foreach ($searchPath in $searchPaths) {
                $testPath = Join-Path $searchPath $path
                if (Test-Path $testPath) {
                    $resolvedPath = $testPath
                    break
                }
            }

            if (-not $resolvedPath) {
                Write-Error "Could not find executable: $path"
                return
            }

            if (-not (Test-Path $resolvedPath -PathType Leaf)) {
                Write-Error "Path is not a file: $resolvedPath"
                return
            }

            $fileInfo = Get-Item $resolvedPath
            if (-not $fileInfo.Extension -and -not (Test-Path $resolvedPath -PathType Leaf)) {
                Write-Error "File is not executable: $resolvedPath"
                return
            }

            $aliases[$name] = $resolvedPath
            Save-AliasManifest $aliases
            Register-AliasFunctions
            Write-Host "Alias '$name' added for: $resolvedPath"
        }

        'remove' {
            if ($aliases.ContainsKey($name)) {
                $aliases.Remove($name) | Out-Null
                Remove-Item -Path "Function:$name" -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "Function:Global:$name" -Force -ErrorAction SilentlyContinue
                Save-AliasManifest $aliases
                Write-Host "Alias '$name' removed."
            } else {
                Write-Warning "Alias '$name' not found."
            }
        }

        default {
            Write-Host "Alias Management Commands:"
            Write-Host "--------------------------"
            Write-Host "list   - Lists all registered aliases"
            Write-Host "add    - Adds a new alias (alias add <name> <path>)"
            Write-Host "remove - Removes an existing alias (alias remove <name>)"
            Write-Host "help   - Shows this help message"
            Write-Host ""
            Write-Host "Examples:"
            Write-Host "  alias add notepad 'C:\Windows\notepad.exe'"
            Write-Host "  alias remove notepad"
            Write-Host "  alias list"
        }
    }
}

Register-AliasFunctions

Export-ModuleMember -Function alias