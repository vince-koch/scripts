# USAGE
# Import-Module $PSScriptRoot\Shebang.psm1 -DisableNameChecking -Force

function Shebang {
	param (
		[Parameter(Mandatory=$true, Position=0)]
		[ValidateNotNullOrEmpty()]
		[string] $filename,
		
        [Parameter(Mandatory=$True, Position = 1, ValueFromRemainingArguments=$true)]
		[string[]] $arguments
	)
	
	[string] $shebang = "#! "
	
	if ([System.IO.File]::Exists($filename) -eq $false) {
		Write-Host "File [$filename] does not exist" -ForegroundColor Red
		return 1
	}
	
	[string] $first = Get-Content $filename -First 1
	if ($first.StartsWith($shebang) -eq $false) {
		Write-Host "File [$filename] did not begin with the shebang sequence [$shebang]" -ForegroundColor Red
		return 1
	}
	
	[string] $command = $first.Substring($shebang.Length)
	if ([string]::IsNullOrWhiteSpace($command)) {
		Write-Host "File [$filename] began with the shebang sequence but did not contain an instruction" -ForegroundColor Red
		return 1
	}
	
	Write-Host $command $arguments  -ForegroundColor DarkGray
	$startProcessParams = @{
		FilePath               = $command
		ArgumentList           = $arguments
		Wait                   = $true;
		PassThru               = $true;
		NoNewWindow            = $true;
	}

	$cmd = Start-Process @startProcessParams
	return $cmd.ExitCode
}

Set-Alias -Name sb -Value Shebang

Export-ModuleMember -Function Shebang -Alias sb