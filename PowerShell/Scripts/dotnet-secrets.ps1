# dotnet user-secrets list | Out-Null

$projectPath = (Resolve-Path .).Path
$projectName = Split-Path $projectPath -Leaf

$userSecretsId = Select-String `
    -Path "$projectPath\*.csproj" `
    -Pattern '<UserSecretsId>(.*?)</UserSecretsId>' |
    ForEach-Object { $_.Matches.Groups[1].Value } |
    Select-Object -First 1

if (-not $userSecretsId) {
    Write-Error "No UserSecretsId found in project."
    exit 1
}

$secretsPath = Join-Path `
    $env:APPDATA `
    "Microsoft\UserSecrets\$userSecretsId\secrets.json"

if (-not (Test-Path $secretsPath)) {
    New-Item -ItemType File -Path $secretsPath -Force | Out-Null
}

code $secretsPath