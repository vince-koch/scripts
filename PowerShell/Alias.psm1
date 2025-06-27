Try-Import-Module $PSScriptRoot\Json.psm1

$script:ManifestPath = "$env:USERPROFILE\.aliases.json"

function Register-AliasFunctions {
    $aliases = Json-LoadHashtable -Path $script:ManifestPath
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

    $aliases = Json-LoadHashtable -Path $script:ManifestPath

    switch ($action) {
        'list' {
            if ($aliases.Count -eq 0) {
                Write-Output "No aliases registered."
                return
            }

            $aliases.Keys | ForEach-Object {
                [PSCustomObject]@{
                    Alias = $_
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
            Json-SaveHashtable -Path $script:ManifestPath -Hashtable $aliases
            Register-AliasFunctions
            Write-Host "Alias '$name' added for: $resolvedPath"
        }

        'remove' {
            if ($aliases.ContainsKey($name)) {
                $aliases.Remove($name) | Out-Null
                Remove-Item -Path "Function:$name" -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "Function:Global:$name" -Force -ErrorAction SilentlyContinue
                Json-SaveHashtable -Path $script:ManifestPath -Hashtable $aliases
                Write-Host "Alias '$name' removed."
            } else {
                Write-Warning "Alias '$name' not found."
            }
        }

        default {
            Write-Host "Usage:" -ForegroundColor Yellow
            Write-Host "    alias list                 # List saved aliases"
            Write-Host "    alias add <name> <path>    # Adds a new alias"
            Write-Host "    alias remove <name>        # Removes a saved alias"
            Write-Host ""
            Write-Host "Examples:" -ForegroundColor Yellow
            Write-Host "  alias list"
            Write-Host "  alias add notepad 'C:\Windows\notepad.exe'"
            Write-Host "  alias remove notepad"
        }
    }
}

Register-AliasFunctions

Export-ModuleMember -Function alias