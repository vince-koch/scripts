try {
    $utf8 = [System.Text.UTF8Encoding]::new()
    $OutputEncoding = $utf8
    [console]::InputEncoding  = $utf8
    [console]::OutputEncoding = $utf8
    #Write-Host "Encoding set to UTF8" -ForegroundColor DarkGray
} catch {
    Write-Host "Failed to set encoding to UTF8" -ForegroundColor Red
    Write-Host $_.Exception.ToString() -ForegroundColor Magenta
}


function Clean-Folder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$directory
    )

    Write-Host "📂 Cleaning folder " -NoNewLine
    Write-Host "$directory" -ForegroundColor Cyan

    $SpinIncrement = 25
    $Processed = 0
    $Deleted = 0
    $Skipped = 0

    if (-not (Test-Path -LiteralPath $directory)) {
        Write-Host "❌ Directory does not exist: $directory" -ForegroundColor Red
        return
    }

    $savedProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    Get-ChildItem -LiteralPath $directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
            $Deleted++
        }
        catch {
            $Skipped++
        }

        $Processed++
        if ($Processed -eq 1 -or ($Processed % $SpinIncrement) -eq 0) {
            $spinner = @('⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏')[$Processed / $SpinIncrement % 10]
            Write-Host ("`r$spinner Cleaning... ⏳ $Processed processed, 🧹 $Deleted deleted, ⚠ $Skipped skipped") -NoNewline
        }
    }

    Write-Host ("`r✅ Complete!  ⏳ $Processed processed, 🧹 $Deleted deleted, ⚠ $Skipped skipped") -NoNewline

    $ProgressPreference = $savedProgressPreference
}


function Cleanup-Folders {
    [CmdletBinding()]
    param ()

    $TempPath = [System.IO.Path]::GetTempPath()
    Clean-Folder -directory $TempPath
}


Cleanup-Folders