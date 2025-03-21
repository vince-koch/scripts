# Interactive S3 Browser in PowerShell (SSO-ready, using .NET SDK)
# Assumes: `aws sso login --profile $Env:AWS_PROFILE` has been run

Try-Import-Module $PSScriptRoot\Console.psm1


Add-Type -Path "$HOME\.nuget\packages\awssdk.s3\3.7.406\lib\net8.0\AWSSDK.S3.dll"
Add-Type -Path "$HOME\.nuget\packages\awssdk.core\3.7.400.51\lib\net8.0\AWSSDK.Core.dll"
Add-Type -Path "$HOME\.nuget\packages\awssdk.sso\3.7.400.51\lib\net8.0\AWSSDK.SSO.dll"
Add-Type -Path "$HOME\.nuget\packages\awssdk.ssooidc\3.7.400.51\lib\net8.0\AWSSDK.SSOOIDC.dll"


function Set-AWSProfileAndRegion {
    $awsProfile = $Env:AWS_PROFILE
    if (-not $awsProfile) {
        Write-Error "AWS_PROFILE environment variable is not set."
        exit 1
    }

    $configPath = Join-Path $HOME ".aws\config"
    $regionName = ""

    if (Test-Path $configPath) {
        $sectionName = "[profile $awsProfile]"
        $lines = Get-Content $configPath
        $inSection = $false

        foreach ($line in $lines) {
            if ($line -match "^\[.*\]") {
                $inSection = ($line -eq $sectionName)
            }
            elseif ($inSection -and $line -match "^region\s*=\s*(.+)$") {
                $regionName = $Matches[1].Trim()
                break
            }
        }
    }

    if (-not $regionName) {
        Write-Error "Could not determine region from profile '$awsProfile'. Ensure it is set in ~/.aws/config."
        exit 1
    }

    $region = [Amazon.RegionEndpoint]::GetBySystemName($regionName)
    $creds = New-Object Amazon.Runtime.StoredProfileAWSCredentials($awsProfile)
    $global:S3Client = New-Object Amazon.S3.AmazonS3Client($creds, $region)
}

function Get-S3Buckets {
    $global:S3Client.ListBucketsAsync().Result.Buckets | Select-Object -ExpandProperty BucketName
}

function Browse-S3Bucket {
    param(
        [string]$BucketName
    )

    $prefixParts = @()
    while ($true) {
        $prefix = if ($prefixParts.Count -gt 0) { $prefixParts[-1] } else { '' }

        Clear-Host
        Write-Host "Prefix Parts: $prefixParts" -ForegroundColor Yellow
        Write-Host "Current Path: s3://$BucketName/$prefix`n" -ForegroundColor Cyan

        $request = New-Object Amazon.S3.Model.ListObjectsV2Request
        $request.BucketName = $BucketName
        $request.Prefix = $prefix
        $request.Delimiter = "/"

        $response = $global:S3Client.ListObjectsV2Async($request).Result

        $items = @()
        $items += [PSCustomObject]@{ Type = "exit"; Path = ""; Text = "EXIT" }
        $items += [PSCustomObject]@{ Type = "upload"; Path = ""; Text = "UPLOAD FILE" }

        if ($prefixParts.Count -gt 0) {
            $items += [PSCustomObject]@{ Type = "up"; Path = ""; Text = "../ (Go Up)" }
        }

        $items += $response.CommonPrefixes | ForEach-Object {
            [PSCustomObject]@{
                Type = "folder"
                Path = $_
                Text = $_ -replace "^$prefix", "[Folder] "
            }
        }

        $items += $response.S3Objects | Where-Object { $_.Key -ne $prefix } | ForEach-Object {
            [PSCustomObject]@{
                Type = "file"
                Path = $_.Key
                Text = $_.Key -replace "^$prefix", "[File] "
            }
        }

        $choice = Console-Menu -Items $items -ItemsProperty { param ($item) $item.Text }

        switch ($choice.Type) {
            "up" {
                if ($prefixParts.Count -gt 1) {
                    $prefixParts = $prefixParts[0..($prefixParts.Count - 2)]
                }
                else {
                    $prefixParts = @()
                }
            }
            "upload" {
                $path = Read-Host "Enter local file path to upload"
                if (Test-Path $path) {
                    $key = $prefix + (Split-Path $path -Leaf)
                    $putRequest = New-Object Amazon.S3.Model.PutObjectRequest
                    $putRequest.BucketName = $BucketName
                    $putRequest.Key = $key
                    $putRequest.FilePath = $path
                    $global:S3Client.PutObjectAsync($putRequest).Wait()
                    Read-Host "Uploaded. Press Enter to continue."
                }
            }
            "folder" {
                $prefixParts += $choice.Path
            }
            "file" {
                $key = $choice.Path
                $action = Read-Host "Actions for '$key' - (D)ownload / (R)emove / (C)ancel"
                switch ($action.ToUpper()) {
                    "D" {
                        $destination = Read-Host "Enter local destination path"
                        $getRequest = New-Object Amazon.S3.Model.GetObjectRequest
                        $getRequest.BucketName = $BucketName
                        $getRequest.Key = $key
                        $response = $global:S3Client.GetObjectAsync($getRequest).Result
                        $response.WriteResponseStreamToFileAsync($destination, $true).Wait()
                        Read-Host "Downloaded. Press Enter to continue."
                    }
                    "R" {
                        $delRequest = New-Object Amazon.S3.Model.DeleteObjectRequest
                        $delRequest.BucketName = $BucketName
                        $delRequest.Key = $key
                        $global:S3Client.DeleteObjectAsync($delRequest).Wait()
                        Read-Host "Deleted. Press Enter to continue."
                    }
                }
            }
            "exit" {
                return
            }
        }
    }
}

# --- Run Script ---
Set-AWSProfileAndRegion
$buckets = Get-S3Buckets
$selectedBucket = Console-Menu -Items $buckets -Title "Select Bucket"
Browse-S3Bucket -BucketName $selectedBucket
