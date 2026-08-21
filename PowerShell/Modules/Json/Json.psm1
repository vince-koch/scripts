# If your JSON file contains this
#   { "foo": "bar", "baz": "qux" }
# The return will be this
#   @{ foo = "bar"; baz = "qux" }
function Json-LoadHashtable {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return @{}
    }

    $json = Get-Content -Path $Path -Raw
    $obj = $json | ConvertFrom-Json

    $hashtable = @{}

    foreach ($prop in $obj.PSObject.Properties) {
        $hashtable[$prop.Name] = $prop.Value
    }

    return $hashtable
}

function Json-SaveHashtable {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [hashtable]$Hashtable
    )

    $json = $Hashtable | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.Encoding]::UTF8)
}

function Json-PrintHashtable {
    param (
        [Parameter(Mandatory)]
        [hashtable]$Hashtable
    )

    foreach ($key in $Hashtable.Keys) {
        Write-Host "$key = $($Hashtable[$key])"
    }
}

# If your JSON file contains this
#   { "foo": "bar", "baz": "qux" }
# The return will be this
#   [PSCustomObject] with properties foo and baz
function Json-LoadPsObject {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return [PSCustomObject]@{}
    }

    $json = Get-Content -Path $Path -Raw
    return $json | ConvertFrom-Json
}

function Json-SavePsObject {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [psobject]$Object
    )

    $json = $Object | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.Encoding]::UTF8)
}

function Json-PrintPsObject {
    param (
        [Parameter(Mandatory)]
        [psobject]$Object
    )

    foreach ($prop in $Object.PSObject.Properties) {
        Write-Host "$($prop.Name) = $($prop.Value)"
    }
}

Export-ModuleMember -Function Json-LoadHashtable
Export-ModuleMember -Function Json-SaveHashtable
Export-ModuleMember -Function Json-PrintHashtable
Export-ModuleMember -Function Json-LoadPsObject
Export-ModuleMember -Function Json-SavePsObject
Export-ModuleMember -Function Json-PrintPsObject
