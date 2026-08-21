<#
.SYNOPSIS
    Opens files and folders in Notepad++.
.DESCRIPTION
    Locates the installed Notepad++ executable and forwards all supplied arguments to it.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

[string[]] $exePaths = @(
    "C:\Program Files\Notepad++\notepad++.exe",
    "C:\Program Files (x86)\Notepad++\notepad++.exe"
)

[string] $exe = $exePaths | Where-Object { [System.IO.File]::Exists($_) } | Select-Object -First 1
if ($null -eq $exe) {
    Write-Error "Unable to find path where notepad++.exe is installed"
    exit 1
}

for ($i = 0; $i -lt $Arguments.Length; $i++) {
    if ($Arguments[$i].IndexOf(' ') -gt -1 -and -not $Arguments[$i].StartsWith('"')) {
        $Arguments[$i] = "`"$($Arguments[$i])`""
    }
}

if ($Arguments.Length -gt 0) {
    Start-Process -FilePath $exe -ArgumentList $Arguments
}
else {
    Start-Process -FilePath $exe
}
