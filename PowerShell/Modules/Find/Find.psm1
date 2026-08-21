function Find-File {
    param (
        [string] $fileName,
        [string[]] $paths
    )
    
    Write-Host "Searching $($paths.Length) paths for $fileName"
    foreach ($path in $paths) {
        try {
            [string] $fullPath = [System.IO.Path]::Combine($path, $moduleName)
            if ([System.IO.File]::Exists($fullPath)) {
                return $fullPath
            }
        }
        catch {
        }
    }

    return $null
}

function Find-Module {
    param (
        [string] $moduleName
    )
    
    [string[]] $modulePaths = $env:PSModulePath.Split(';')
    [string] $modulePath = Find-File $moduleName $modulePaths
    
    if ($modulePath.Length -eq 0) {
        [string[]] $paths = $env:Path.Split(';')
        $modulePath = Find-File $moduleName $paths
    }
    
    if ($modulePath -eq $null) {
        throw new "Unable to locate module $moduleName"
    }
    
    Write-Host "Importing $modulePath"
    Import-Module $modulePath -DisableNameChecking -Force
}

Export-ModuleMember -Function Find-File
Export-ModuleMember -Function Find-Module