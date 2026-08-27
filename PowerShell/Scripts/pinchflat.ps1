# https://github.com/kieraneglin/pinchflat#docker

$TimeZoneIanaId = ""
[System.TimeZoneInfo]::TryConvertWindowsIdToIanaId((Get-TimeZone).Id, [ref]$TimeZoneIanaId) | Out-Null; $ianaId

$ConfigFolder = Join-Path -Path $pwd -ChildPath "config"
New-Item -ItemType Directory -Force -Path "$ConfigFolder"

$DownloadsFolder = Join-Path -Path $pwd -ChildPath "downloads"
New-Item -ItemType Directory -Force -Path "$DownloadsFolder"

docker run `
  -d `
  -e TZ=$TimeZoneIanaId `
  -p 8945:8945 `
  -v "$($ConfigFolder):/config" `
  -v "$($DownloadsFolder):/downloads" `
  ghcr.io/kieraneglin/pinchflat:latest

Start-Process http://localhost:8945