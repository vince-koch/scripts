param(
    [string]$BucketName   = 'pareo-local',

    # Mount point for the S3 bucket. Accepts a drive letter (e.g. 'L:') or a
    # folder path (e.g. 'C:\mounts\pareo-local'). The folder will be created if
    # it does not exist; its parent must already exist. If omitted, defaults to
    # a subfolder named after the bucket in the current working directory.
    [string]$MountPoint   = '',

    # When set, creates the S3 bucket if it does not already exist.
    [switch]$CreateBucket = $false
)

$ErrorActionPreference = 'Stop'

if (-not $MountPoint) {
    $MountPoint = Join-Path (Get-Location) $BucketName
}

$LOCALSTACK_IMAGE = 'localstack/localstack:2026.03.0'
$CONTAINER_NAME   = 'localstack'

function Invoke-Cli {
    param(
        [scriptblock]$Command,
        [string]$ErrorMessage
    )
    $output = & $Command 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error $ErrorMessage
        exit 1
    }
    return $output
}

function Ensure-DockerRunning {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error 'Docker is not installed or not on PATH.'
        exit 1
    }
    $dockerInfo = Invoke-Cli -Command { docker info --format 'Server Version: {{.ServerVersion}}  |  OS: {{.OperatingSystem}}' } -ErrorMessage 'Docker daemon is not running.'
    Write-Host "Docker: $dockerInfo"
}

function Ensure-LocalStackRunning {
    $existingId = Invoke-Cli `
        -Command      { docker ps -a --filter "name=^${CONTAINER_NAME}$" --filter "ancestor=${LOCALSTACK_IMAGE}" --format '{{.ID}}' } `
        -ErrorMessage 'Failed to query Docker containers.'

    if (-not $existingId) {
        if (-not $env:LOCALSTACK_AUTH_TOKEN) {
            Write-Error 'LOCALSTACK_AUTH_TOKEN environment variable is not set.'
            exit 1
        }

        Write-Host "LocalStack container not found. Starting a new one..."
        Invoke-Cli -Command { docker run -d --name $CONTAINER_NAME -p 4566:4566 -e LOCALSTACK_AUTH_TOKEN=$env:LOCALSTACK_AUTH_TOKEN $LOCALSTACK_IMAGE } -ErrorMessage 'Failed to start LocalStack container.'
        Write-Host 'LocalStack container started.'
        return
    }

    $runningId = Invoke-Cli `
        -Command      { docker ps --filter "name=^${CONTAINER_NAME}$" --filter "ancestor=${LOCALSTACK_IMAGE}" --format '{{.ID}}' } `
        -ErrorMessage 'Failed to query running Docker containers.'

    if ($runningId) {
        Write-Host "LocalStack container is already running (ID: $runningId)."
        return
    }

    Write-Host 'LocalStack container exists but is stopped. Starting it...'
    Invoke-Cli -Command { docker start $existingId } -ErrorMessage 'Failed to start existing LocalStack container.'
    Write-Host "LocalStack container started (ID: $existingId)."
}

function Ensure-WinFsp {
    if (Get-Service -Name WinFsp -ErrorAction SilentlyContinue) { return }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host 'WinFsp not found. Installing via winget...'
        Invoke-Cli -Command { winget install --id WinFsp.WinFsp --exact --silent } -ErrorMessage 'Failed to install WinFsp via winget.'
        Write-Host 'WinFsp installed.'
    } else {
        Write-Error 'WinFsp is not installed and winget is not available to install it.'
        exit 1
    }
}

function Ensure-Rclone {
    if (Get-Command rclone -ErrorAction SilentlyContinue) { return }

    # rclone is required for mounting the S3 bucket. It depends on WinFsp for filesystem support, so we ensure that first.
    #Ensure-WinFsp

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host 'rclone not found. Installing via winget...'
        Invoke-Cli -Command { winget install --id Rclone.Rclone --exact --silent } -ErrorMessage 'Failed to install rclone via winget.'
        Write-Host 'rclone installed.'
    } else {
        Write-Error 'rclone is not installed and winget is not available to install it.'
        exit 1
    }
}

function Ensure-LocalStackBucket {
    $buckets = Invoke-Cli `
        -Command      { docker exec $CONTAINER_NAME awslocal s3api list-buckets --query 'Buckets[].Name' --output text } `
        -ErrorMessage 'Failed to list LocalStack S3 buckets.'

    if ($buckets -split '\s+' -contains $BucketName) {
        Write-Host "S3 bucket '$BucketName' already exists."
        return
    }

    if (-not $CreateBucket) {
        Write-Error "S3 bucket '$BucketName' does not exist. Use -CreateBucket to create it."
        exit 1
    }

    Write-Host "Creating S3 bucket '$BucketName'..."
    Invoke-Cli -Command { docker exec $CONTAINER_NAME awslocal s3api create-bucket --bucket $BucketName } -ErrorMessage "Failed to create S3 bucket '$BucketName'."
    Write-Host "S3 bucket '$BucketName' created."
}

function Mount-LocalStackBucket {
    $isDriveLetter = $MountPoint -match '^[A-Za-z]:$'

    if ($isDriveLetter) {
        if (Test-Path $MountPoint) {
            Write-Host "Drive $MountPoint is in use. Unmounting..."
            $proc = Get-CimInstance Win32_Process -Filter "name = 'rclone.exe'" |
                Where-Object { $_.CommandLine -like "*$MountPoint*" }
            if ($proc) { Stop-Process -Id $proc.ProcessId -Force }
            $timeout = 10; $elapsed = 0
            while ((Test-Path $MountPoint) -and $elapsed -lt $timeout) {
                Start-Sleep -Seconds 1; $elapsed++
            }
            if (Test-Path $MountPoint) {
                Write-Error "Drive $MountPoint could not be unmounted after ${timeout}s."
                exit 1
            }
            Write-Host "Drive $MountPoint unmounted."
        }
    } else {
        # Folder mount: parent must exist, create mount dir if needed
        $parent = Split-Path $MountPoint -Parent
        if (-not (Test-Path $parent)) {
            Write-Error "Parent path '$parent' does not exist. Please create it first."
            exit 1
        }
        if (Test-Path $MountPoint) {
            $contents = Get-ChildItem $MountPoint -ErrorAction SilentlyContinue
            if ($contents) {
                Write-Host "Folder $MountPoint is in use. Unmounting..."
                $proc = Get-CimInstance Win32_Process -Filter "name = 'rclone.exe'" |
                    Where-Object { $_.CommandLine -like "*$MountPoint*" }
                if ($proc) { Stop-Process -Id $proc.ProcessId -Force }
                $timeout = 10; $elapsed = 0
                while ((Get-ChildItem $MountPoint -ErrorAction SilentlyContinue) -and $elapsed -lt $timeout) {
                    Start-Sleep -Seconds 1; $elapsed++
                }
                Write-Host "Folder $MountPoint unmounted."
            }
        }
    }

    Write-Host "Mounting '$BucketName' -> " -NoNewline
    Write-Host $MountPoint -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to unmount and exit." -ForegroundColor Yellow
    $rcloneArgs = @(
        'mount', ":s3:$BucketName", $MountPoint,
        '--s3-provider', 'Minio',
        '--s3-access-key-id', 'test',
        '--s3-secret-access-key', 'test',
        '--s3-endpoint', 'http://localhost:4566',
        '--s3-region', 'us-east-1',
        '--links',
        '--vfs-cache-mode', 'full'
    )
    & rclone @rcloneArgs
    Write-Host "Bucket '$BucketName' unmounted from $MountPoint."
}

# 1. Ensure Docker is installed and running
Ensure-DockerRunning

# 2. Ensure LocalStack is running
Ensure-LocalStackRunning

# 3. Ensure LocalStack S3 bucket exists
Ensure-LocalStackBucket
Write-Host "LocalStack -> " -NoNewline
Write-Host "https://app.localstack.cloud/inst/default/resources/s3/$BucketName" -ForegroundColor Cyan

# 4. Ensure rclone and WinFsp are available
Ensure-Rclone

# 5. Mount the S3 bucket to the mount point
Mount-LocalStackBucket

# 6. Open the LocalStack resources page
#Start-Process 'https://app.localstack.cloud/inst/default/resources'