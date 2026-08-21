function Open-DotNetSecrets {
    <#
    .SYNOPSIS
        Opens the current .NET project's user-secrets file in VS Code.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path
    )

    $projectPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    $projectFiles = @(Get-ChildItem -LiteralPath $projectPath -Filter '*.csproj' -File)
    if ($projectFiles.Count -eq 0) { throw "No .csproj file found in $projectPath" }

    $userSecretsId = $projectFiles |
        Select-String -Pattern '<UserSecretsId>(.*?)</UserSecretsId>' |
        ForEach-Object { $_.Matches.Groups[1].Value } |
        Select-Object -First 1
    if (-not $userSecretsId) { throw 'No UserSecretsId found in the project.' }

    $secretsPath = Join-Path $env:APPDATA "Microsoft\UserSecrets\$userSecretsId\secrets.json"
    $secretsDirectory = Split-Path $secretsPath -Parent
    if (-not (Test-Path -LiteralPath $secretsDirectory)) {
        New-Item -ItemType Directory -Path $secretsDirectory -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $secretsPath)) {
        New-Item -ItemType File -Path $secretsPath -Force | Out-Null
    }

    & code $secretsPath
}
