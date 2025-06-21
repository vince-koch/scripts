function Is-VisualStudioCode {
    return ($env:TERM_PROGRAM -eq "vscode")
}


function Handle-VisualStudioCode {
    if (-not (Is-VisualStudioCode)) {
        return
    }

    Write-Host "$($env:TERM_PROGRAM)" -ForegroundColor Blue -NoNewLine
    Write-Host " $($env:TERM_PROGRAM_VERSION)" -ForegroundColor Cyan

    # Visual Studio Code always word wraps the terminal window which makes dootnet build output look terrible
    # To combat that we will attempt to reset the horizontal buffer size each time the prompt is shown
    # And we will do it each time our prompt is run

    $global:vscode_previous_prompt = global:prompt

    function global:prompt {
        try {
            $desiredWidth = 2000
            $bufferSize = $Host.UI.RawUI.BufferSize
            $Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size($desiredWidth, $bufferSize.Height)
        } catch {
        }

        return $global:vscode_previous_prompt
    }
}


function Is-VisualStudio {
    return -not [string]::IsNullOrEmpty($env:VisualStudioEdition)
}


function Handle-VisualStudio {
    # Visual Studio
    if (-not (Is-VisualStudio)) {
        return
    }

    Write-Host "$($env:VisualStudioEdition)" -ForegroundColor Blue -NoNewLine
    Write-Host " $($env:VisualStudioVersion)" -ForegroundColor Cyan

    # # if we're using starship, select a preset which doesn't break in visual studio
    # if ($env:STARSHIP_CONFIG) {
    #     $env:STARSHIP_CONFIG = [System.IO.Path]::Combine($PSScriptRoot, "starship-presets", "toml", "no-nerd-font.toml")
    # }
}


Export-ModuleMember -Function Is-VisualStudioCode
Export-ModuleMember -Function Handle-VisualStudioCode
Export-ModuleMember -Function Is-VisualStudio
Export-ModuleMember -Function Handle-VisualStudio