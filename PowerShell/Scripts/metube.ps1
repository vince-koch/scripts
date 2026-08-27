# https://github.com/alexta69/metube

Write-Host "Starting metube container" -NoNewLine
Write-Host "http://localhost:8081" -ForegroundColor Cyan

try {
    Start-Process http://localhost:8081
    docker run --rm -p 8081:8081 -v "${PWD}:/downloads" ghcr.io/alexta69/metube
}
finally {
    Remove-Item -Path "${PWD}/.metube" -Recurse -Force
}