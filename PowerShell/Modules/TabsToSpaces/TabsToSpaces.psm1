# USAGE
# Import-Module $PSScriptRoot\TabsToSpaces.psm1 -DisableNameChecking -Force

function Indent-Tabs-To-Spaces([string] $path, [int] $spacesPerTab = 4) {
    [string] $indent = $(" " * $spacesPerTab)
    [string[]] $lines = [System.IO.File]::ReadAllLines($path)

    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        $trimmed = $line.TrimStart()
        $start = $line.SubString(0, $line.Length - $trimmed.Length).Replace("`t", $indent)
        $lines[$i] = $start + $trimmed
    }

    [System.IO.File]::WriteAllLines($path, $lines)
}

Set-Alias -Name t2s -Value Indent-Tabs-To-Spaces
Set-Alias -Name tts -Value Indent-Tabs-To-Spaces

Export-ModuleMember -Function Indent-Tabs-To-Spaces -Alias t2s, tts