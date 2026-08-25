<#
.SYNOPSIS
    Provides convenient access to active PSReadLine key bindings.
#>

function Get-BoundKeyBinding {
    Get-PSReadLineKeyHandler -Bound |
    Where-Object Group -eq 'Custom' |
    Format-Table Key, Function, Description -AutoSize
}

Set-Alias -Name keybind -Value Get-BoundKeyBinding
Set-Alias -Name keybinds -Value Get-BoundKeyBinding
Set-Alias -Name keybindings -Value Get-BoundKeyBinding
Set-Alias -Name hotkeys -Value Get-BoundKeyBinding

Export-ModuleMember `
    -Function Get-BoundKeyBinding `
    -Alias keybind, keybinds, keybindings, hotkeys
