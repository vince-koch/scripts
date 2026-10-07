# Completions Module - argument completers for interactive shell use

$moduleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$publicFunctions = @(
    'Enable-DirectoryCompletion'
)

foreach ($function in $publicFunctions) {
    . (Join-Path $moduleRoot "Public\$function.ps1")
}

Export-ModuleMember -Function $publicFunctions
