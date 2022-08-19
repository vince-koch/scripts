# USAGE
# Import-Module $PSScriptRoot\Notepad++.psm1 -DisableNameChecking -Force

function Open-NotepadPlusPlus {
    [string[]] $exePaths = $(
	    "C:\Program Files\Notepad++\notepad++.exe",
        "C:\Program Files (x86)\Notepad++\notepad++.exe"
    )

    [string] $exe = $exePaths | Where { [System.IO.File]::Exists($_) }
    if ($exe -eq $null) {
        Write-Error "Unable to find path where notepad++.exe is installed" -ForegroundColor Red
        return -1
    }

	for ($i = 0; $i -lt $args.Length; $i++) {
		if ($args[$i].IndexOf(' ') -gt -1 -and -not $args[$i].StartsWith('"')) {
			$args[$i] = "`"$($args[$i])`""
		}
	}
	
	if ($args.Length -gt 0) {
        Start-Process -FilePath $exe -ArgumentList $args
    }
    else {
        Start-Process -FilePath $exe
    }
}

Set-Alias -Name npp -Value Open-NotepadPlusPlus

Export-ModuleMember -Function Open-NotepadPlusPlus -Alias npp