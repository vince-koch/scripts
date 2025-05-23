function Github-ListFiles {
    param (
        [Parameter(Mandatory = $True)] [string] $Owner,
        [Parameter(Mandatory = $True)] [string] $Repo,
        [Parameter(Mandatory = $True)] [string] $Branch,
        [Parameter(Mandatory = $False)] [string] $SubFolder = $null
    )

    # invoke github tree api
    $apiUrl = "https://api.github.com/repos/$($Owner)/$($Repo)/git/trees/$($Branch)?recursive=1"
    $headers = @{ "User-Agent" = "PowerShellScript" }
    $treeData = Invoke-RestMethod -Uri $apiUrl -Headers $headers
    if ($treeData.truncated -eq $True) {
        throw "Github Api Returned Truncated=True"
    }

    # filter to files (remove folder entries)
    $files = $treeData.tree | Where-Object { $_.type -eq "blob" }
    

    # filter files to those in the given subfolder
    if ([string]::IsNullOrWhiteSpace($SubFolder) -eq $False) {
        $normalizedFolder = $Subfolder.Trim('/')
        $files = $files | Where-Object { $_.path -like "$normalizedFolder/*" }
    }

    $result = $files | Select-Object path, sha, size, url, @{ Name = "rawUrl"; Expression = { "https://raw.githubusercontent.com/$Owner/$Repo/$Branch/$($_.path)" } }
    #$result | Format-Table

    return $result
}


function Github-DownloadFiles {
    param (
        [Parameter(Mandatory = $True)] [string] $Owner,
        [Parameter(Mandatory = $True)] [string] $Repo,
        [Parameter(Mandatory = $True)] [string] $Branch,
        [Parameter(Mandatory = $False)] [string] $SubFolder = "x",
        [Parameter(Mandatory = $False)] [string] $Destination = "."
    )

    $files = Github-ListFiles -Owner $Owner -Repo $Repo -Branch $Branch -SubFolder $SubFolder
    
    foreach ($file in $Files) {
        $relativePath = $file.path
        $outputPath = Join-Path $Destination $relativePath
        $outputDir = Split-Path $outputPath -Parent

        # ensure destination directory exists
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        # download the file
        Invoke-WebRequest -Uri $file.rawUrl -OutFile $outputPath -UseBasicParsing -ErrorAction Stop
    }
}


Export-ModuleMember -Function Github-ListFiles
Export-ModuleMember -Function Github-DownloadFiles
