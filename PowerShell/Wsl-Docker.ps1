Function Wsl-TranslatePath {
    param (
        [string] $path
    )

    $fullPath = [System.IO.Path]::GetFullPath($path)
    $root = [System.IO.Path]::GetPathRoot($fullPath)
    $drive = $root.SubString(0, 1).ToLower()
    $wslPath = "/mnt/$($drive)/" + $fullPath.SubString($root.Length).Replace("\", "/")

    #Write-Host "PATH [$path] ==> [$wslPath]" -ForegroundColor DarkGray

    return $wslPath
}

Function Wsl-EnsureDockerStarted {
    [string] $path = [System.IO.Path]::Combine($PSScriptRoot, "..\Bash\wsl-docker-ensure-started.sh")
    $wslPath = Wsl-TranslatePath $path
    wsl $wslPath
}

Function Wsl-StartDocker {
    wsl docker $args
}
 
Function Wsl-StartMinikube {
    wsl minikube $args
}
 
Function Wsl-StartKubectl {
    wsl minikube kubectl -- $args
}
 
Function Wsl-StartLazyDocker {
    wsl ~/.local/bin/lazydocker $args
}

Set-Alias -Name docker -Value Wsl-StartDocker
Set-Alias -Name minikube -Value Wsl-StartMinikube
Set-Alias -Name kubectl -Value Wsl-StartKubectl
Set-Alias -Name lazydocker -Value Wsl-StartLazyDocker

Wsl-EnsureDockerStarted
Write-Host "WSL Docker Extensions Loaded" -ForegroundColor Yellow