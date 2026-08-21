# USAGE
# Import-Module $PSScriptRoot\Linq.psm1 -DisableNameChecking -Force
#
# Code sntatched from
# https://gist.github.com/josheinstein/2559785

##############################################################################
# SUMMARY
# Commands that add LINQ-like functionality to the PowerShell pipeline.
#
# NOTES
# PowerShell 2.0 will complain about the non-standard verb names.
# In short, I don't give a shit. I wanted the names to be consistent with
# LINQ and there isn't an appropriate verb that would cover all the
# functions. Feel free to rename as you see fit.
#
# AUTHOR
# Josh Einstein
#
# LICENSE
# Creative Commons License Deed 
# Attribution-NonCommercial-ShareAlike 2.5
# http://creativecommons.org/licenses/by-sa/3.0/us/
##############################################################################


##############################################################################
# PUBLIC FUNCTIONS
##############################################################################


##############################################################################
#.SYNOPSIS
# Determines whether all elements of a sequence satisfy a condition.
#
#.DESCRIPTION
# This method does not return all the elements of a collection. Instead, it 
# determines whether all the elements of a collection satisfy a condition.
#
# The predicate will stop being evaluated as soon as the result can be
# determined.
#
#.PARAMETER Predicate
# A function to test each element for a condition.
#
#.PARAMETER InputObject
# An sequence that contains the elements to apply the predicate to.
#
#.EXAMPLE
# 1,2,3,4,5 | Linq-All { $_ -lt 6 }
##############################################################################
function Linq-All {

[CmdletBinding()]
param ( 

    [Parameter(Position=1,Mandatory=$true)]
    [ScriptBlock]$Predicate,
    
    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject

)

    begin {
        $AllSoFar = $true
    }
    
    process { 

        # Short Circuit
        # Stop checking once we found one negative
        if (-not $AllSoFar) {
            return
        }

        $AllSoFar = Test-Predicate $InputObject $Predicate
        
    }
    
    end {
        $AllSoFar
    }

}

##############################################################################
#.SYNOPSIS
# Determines whether any element of a sequence satisfies a condition.
#
#.DESCRIPTION
# This method does not return any one element of a collection. Instead, it
# determines whether any elements of a collection satisfy a condition.
#
# The predicate will stop being evaluated as soon as the result can be
# determined.
#
#.PARAMETER Predicate
# A function to test each element for a condition.
#
#.PARAMETER InputObject
# An sequence that contains the elements to apply the predicate to.
#
#.EXAMPLE
# 1..10 | Linq-Any { $_ -gt 5 }
##############################################################################
function Linq-Any {

[CmdletBinding()]
param ( 
    
    [Parameter(Position=1)]
    [ScriptBlock]$Predicate,

    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject
    
)

    begin {
        $AnySoFar = $false
    }
    
    process { 
    
        # Short Circuit
        # Once we find one, stop checking
        if ($AnySoFar) {
            return
        }
        
        $AnySoFar = Test-Predicate $InputObject $Predicate
        
    }
    
    end {
        $AnySoFar
    }

}

##############################################################################
#.SYNOPSIS
# Returns a number that represents how many elements in the specified
# sequence satisfy a condition. 
#
#.PARAMETER Predicate
# A function to test each element for a condition.
#
#.PARAMETER InputObject
# A sequence that contains elements to be counted.
#
#.EXAMPLE
# 1..10 | Linq-Count { $_ -gt 5 }
##############################################################################
function Linq-Count {

[CmdletBinding()]
param ( 
    
    [Parameter(Position=1)]
    [ScriptBlock]$Predicate,

    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject
    
)

    begin { 
        $Count = 0
    }
    
    process { 
        if (Test-Predicate $InputObject $Predicate) {
            $Count += 1
        }
    }
    
    end {
        $Count
    }

}

##############################################################################
#.SYNOPSIS
# Returns the first element in a sequence that satisfies a specified condition.
#
#.PARAMETER Predicate
# A function to test each element for a condition.
#
#.PARAMETER InputObject
# A sequence that contains elements to be tested.
#
#.EXAMPLE
# 1..10 | Linq-First { $_ -gt 5 }
##############################################################################
function Linq-First {

[CmdletBinding()]
param ( 
    
    [Parameter(Position=1)]
    [ScriptBlock]$Predicate,

    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject
    
)

    begin {
        $Count = 0
    }
    
    process { 

        if ($Count -gt 0) {
            return
        }

        if (Test-Predicate $InputObject $Predicate) {
            $Count += 1
            $InputObject
        }

    }

}

##############################################################################
#.SYNOPSIS
# Returns the last element of a sequence that satisfies a specified condition. 
#
#.PARAMETER Predicate
# A function to test each element for a condition.
#
#.PARAMETER InputObject
# A sequence that contains elements to be tested.
#
#.EXAMPLE
# 1..10 | Linq-Last { $_ -gt 5 }
##############################################################################
function Linq-Last {

[CmdletBinding()]
param ( 
    
    [Parameter(Position=1)]
    [ScriptBlock]$Predicate,

    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject
    
)

    begin {
        $Result = $null
        $Count = 0
    }
    
    process { 
        if (Test-Predicate $InputObject $Predicate) {
            $Count += 1
            $Result = $InputObject
        }
    }
    
    end {
        if ($Count -gt 0) {
            $Result
        }
    }

}

##############################################################################
#.SYNOPSIS
# Returns the only element of a sequence that satisfies a specified condition,
# and throws an exception if more than one or no such element exists.
#
#.PARAMETER Predicate
# A function to test each element for a condition.
#
#.PARAMETER InputObject
# A sequence that contains elements to be tested.
#
#.EXAMPLE
# 1..10 | Linq-Single { $_ -ge 10 }
##############################################################################
function Linq-Single {

[CmdletBinding()]
param ( 
    
    [Parameter(Position=1)]
    [ScriptBlock]$Predicate,

    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject
    
)

    begin { 
        $Result = $null
        $Count = 0
    }
    
    process { 
        if (Test-Predicate $InputObject $Predicate) {
            if ($Count++ -gt 0) {
                throw 'More than one element in the sequence matched the condition.'
            }
            $Result = $InputObject
        }
    }
    
    end {
        if ($Count -eq 1) {
            $Result
        }
    }

}

##############################################################################
#.SYNOPSIS
# Bypasses a specified number of elements in a sequence and then returns the
# remaining elements. 
#
#.DESCRIPTION
# If source contains fewer than count elements, an empty sequence is
# returned. If count is less than or equal to zero, all elements of source 
# are yielded.
#
#.PARAMETER Count
# The number of elements to skip before returning the remaining elements.
#
#.PARAMETER InputObject
# A sequence that contains elements to be tested.
#
#.EXAMPLE
# 1..10 | Linq-Skip 5
##############################################################################
function Linq-Skip {

[CmdletBinding()]
param ( 
    
    [Parameter(Position=1,Mandatory=$true)]
    [Int64]$Count,        

    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject
    
)

    begin {
        $ProcessCount = 0
    }
    
    process { 
        if ( ++$ProcessCount -gt $Count ) {
            $InputObject
        }
    }

}

##############################################################################
#.SYNOPSIS
# Bypasses elements in a sequence as long as a specified condition is true and
# then returns the remaining elements.
#
#.PARAMETER Predicate
# A function to test each element for a condition.
#
#.PARAMETER InputObject
# A sequence that contains elements to be tested.
#
#.EXAMPLE
# 1..10 | Linq-SkipWhile { $_ -lt 5 }
##############################################################################
function Linq-SkipWhile {

[CmdletBinding()]
param ( 
    
    [Parameter(Position=1,Mandatory=$true)]
    [ScriptBlock]$Predicate,        

    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject
    
)

    begin { 
        $Result = $false
    }
    
    process { 

        if ( $Result -eq $true ) {
            return $InputObject 
        }

        if (-not (Test-Predicate $InputObject $Predicate)) {
            $Result = $true
            $InputObject
        }

    }

}

##############################################################################
#.SYNOPSIS
# Returns a specified number of contiguous elements from the start of a sequence.
#
#.DESCRIPTION
# If count is less than or equal to zero, source is not enumerated and an
# empty sequence is returned.
#
#.PARAMETER Count
# The number of elements to return.
#
#.PARAMETER InputObject
# The sequence to return elements from.
#
#.EXAMPLE
# 1..10 | Linq-Take 5
##############################################################################
function Linq-Take {

[CmdletBinding()]
param ( 
    
    [Parameter(Position=1,Mandatory=$true)]
    [Int64]$Count,        

    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject
    
)

    begin { 
        [Int64]$ProcessCount = 0
    }
    
    process { 
        if ($ProcessCount++ -lt $Count) {
            $InputObject
        }
    }
    
    end {
    }

}


##############################################################################
#.SYNOPSIS
# Returns elements from a sequence as long as a specified condition is true.
#
#.PARAMETER Predicate
# A function to test each element for a condition.
#
#.PARAMETER InputObject
# A sequence that contains elements to be tested.
#
#.EXAMPLE
# 1..10 | Linq-TakeWhile { $_ -lt 5 }
##############################################################################
function Linq-TakeWhile {

[CmdletBinding()]
param ( 
    
    [Parameter(Position=1,Mandatory=$true)]
    [ScriptBlock]$Predicate,        

    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject
    
)

    begin {
        $Result = $true
    }
    
    process { 

        if ( $Result -eq $false ) { return }
        
        if (Test-Predicate $InputObject $Predicate) {
            $InputObject
        }
        else {
            $Result = $false
        }

    }
    
}

##############################################################################
#.SYNOPSIS
# Creates a Hashtable from a sequence according to specified key selector and
# element selector functions. 
#
#.PARAMETER KeySelector
# A function to extract a key from each element.
#
#.PARAMETER ValueSelector
# A transform function to produce a result element value from each element.
#
#.PARAMETER InputObject
# A sequence that contains elements to be tested.
#
#.PARAMETER Force
# If set, duplicate keys in the sequence will overwrite existing keys in
# the dictionary. The default behavior is to write an error if a duplicate
# key is detected.
#
#.EXAMPLE
# Get-Process | Linq-ToDictionary { $_.Id }
##############################################################################
function Linq-ToDictionary {

[CmdletBinding()]
param ( 
    
    [Alias('k')]
    [Parameter(Position=1,Mandatory=$true)]
    [ScriptBlock]$KeySelector,
    
    [Alias('v')]
    [Parameter(Position=2)]
    [ScriptBlock]$ValueSelector,        

    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject,
    
    [Parameter()]
    [Switch]$Force
    
)

    begin {
        $Result = @{}
    }
    
    process { 

        $Key = Invoke-Selector $InputObject $KeySelector
        $Value = Invoke-Selector $InputObject $ValueSelector

        if ($Result.ContainsKey($Key)) {
            if ($Force) {
                $Result[$Key] = $Value
            }
            else {
                Write-Error "Duplicate key: $Key"
            }
        }
        else {
            $Result.Add($Key,$Value)
        }

    }
    
    end {
        $Result
    }

}

##############################################################################
#.SYNOPSIS
# Creates a HashSet containing only unique items from a sequence.
#
#.PARAMETER Selector
#.PARAMETER InputObject
#.PARAMETER Type
##############################################################################
function Linq-ToSet {

[CmdletBinding()]
param(
    
    [Parameter(Position=1)]
    [Object]$Selector,
    
    [Parameter()]
    [Type]$Type = 'PSObject',
    
    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject

)

    begin { 
        if ($Type -eq [String]) {
            $Set = New-Object "System.Collections.Generic.HashSet[$Type]" @([System.StringComparer]::OrdinalIgnoreCase)
        }
        else {
            $Set = New-Object "System.Collections.Generic.HashSet[$Type]"
        }
    }
    
    process {
        if ($Selection = Invoke-Selector $InputObject $Selector) {
            [Void]$Set.Add($Selection)
        }
    }
    
    end { 
        ,$Set
    }

}

##############################################################################
#.SYNOPSIS
# Excludes duplicated values from a sequence.
#
#.PARAMETER Selector
#.PARAMETER InputObject
##############################################################################
function Linq-Distinct {

[CmdletBinding()]
param(
    
    [Parameter(Position=1)]
    [Object]$Selector,
    
    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject

)

    begin { 
        $Set = New-Object 'System.Collections.Generic.HashSet[PSObject]'
    }
    
    process {
        if ($Selection = Invoke-Selector $InputObject $Selector) {
            if ($Set.Add($Selection)) {
                $Selection
            }
        }        
    }

}

# public static IEnumerable<TSource> DistinctBy<TSource, TKey>(this IEnumerable<TSource> source, Func<TSource, TKey> keySelector)
# {
#     var seenKeys = new HashSet<TKey>();
#     return source.Where(element => seenKeys.Add(keySelector(element)));
# }
function Linq-DistinctBy {

[CmdletBinding()]
param(
    
    [Parameter(Position=1,Mandatory=$true)]
    [ScriptBlock]$Selector,
    
    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject

)
   
    begin {
        $Result = @{}
    }
    
    process { 

        $Key = Invoke-Selector $InputObject $Selector
        $Value = Invoke-Selector $InputObject {$_}       
        $Result[$Key] = $Value
    }
    
    end {
        @($Result.Values)
    }
}

##############################################################################
#.SYNOPSIS
# Repeats the input values a specified number of times.
#
#.PARAMETER Count
#.PARAMETER Selector
#.PARAMETER InputObject
##############################################################################
function Linq-Repeat {

[CmdletBinding()]
param(
    
    [Parameter(Position=1)]
    [Int32]$Count = 1,
    
    [Parameter(Position=2)]
    [Object]$Selector,
    
    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject

)

    process {
        if ($Selection = Invoke-Selector $InputObject $Selector) {
            for ($i = 0; $i -lt $Count; $i++) {
                $Selection
            }
        }        
    }

}

##############################################################################
#.SYNOPSIS
# Calculates the average of values in a sequence.
#.DESCRIPTION
#
#.PARAMETER Selector
#.PARAMETER InputObject
##############################################################################
function Linq-Average {

[CmdletBinding()]
param(
    
    [Parameter(Position=1)]
    [Object]$Selector,
    
    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject

)

    begin {
        $Sum = $null
        $Count = 0
    }
    
    process {
        if ($Selection = Invoke-Selector $InputObject $Selector) {
            if ($Sum -ne $null) {
                $Sum += $Selection
                $Count += 1
            }
            else {
                $Sum = $Selection
                $Count = 1
            }
        }
    }
    
    end {
        if ($Count -gt 0) {
            $Sum/$Count
        }
    }

}

##############################################################################
#.SYNOPSIS
# Calculates the sum of values in a sequence.
#
#.PARAMETER Selector
#.PARAMETER InputObject
##############################################################################
function Linq-Sum {

[CmdletBinding()]
param(
    
    [Parameter(Position=1)]
    [Object]$Selector,
    
    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject

)

    begin {
        $Count = 0
        $Sum = $null
    }
    
    process {
        if ($Selection = Invoke-Selector $InputObject $Selector) {
            if ($Sum -ne $null) {
                $Sum += $Selection
                $Count += 1
            }
            else {
                $Sum = $Selection
                $Count = 1
            }
        }
    }
    
    end {
        if ($Count -gt 0) {
            $Sum
        }
    }

}


##############################################################################
#.SYNOPSIS
# Calculates the maximum value in a sequence.
#
#.PARAMETER Selector
# If specified, selects a value to measure based on the input item.
# Otherwise, the input item itself will be measured.
#
#.PARAMETER InputObject
# The item to measure, typically passed from a pipeline.
##############################################################################
function Linq-Max {

[CmdletBinding()]
param(
    
    [Parameter(Position=1)]
    [Object]$Selector,
    
    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject

)

    begin {
        $Max = $null
    }
    
    process {
        if ($Selection = Invoke-Selector $InputObject $Selector) {
            if ( $Max -eq $null -or $Selection -gt $Max ) {
                $Max = $Selection
            }
        }
    }
    
    end {
        if ( $Max -ne $null ) { $Max }
    }

}


##############################################################################
#.SYNOPSIS
# Calculates the minimum value in a sequence.
#
#.PARAMETER Selector
# If specified, selects a value to measure based on the input item.
# Otherwise, the input item itself will be measured.
#
#.PARAMETER InputObject
# The item to measure, typically passed from a pipeline.
##############################################################################
function Linq-Min {

[CmdletBinding()]
param(
    
    [Parameter(Position=1)]
    [Object]$Selector,
    
    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject

)

    begin {
        $Min = $null
    }
    
    process {
        if ($Selection = Invoke-Selector $InputObject $Selector) {
            if ( $Min -eq $null -or $Selection -lt $Min ) {
                $Min = $Selection
            }
        }
    }
    
    end {
        if ( $Min -ne $null ) { $Min }
    }

}


##############################################################################
#.SYNOPSIS
# Excludes from a sequence the items which also appear in a second sequence.
#
#.PARAMETER Sequence
#.PARAMETER InputObject
##############################################################################
function Linq-Except {

[CmdletBinding()]
param(
    
    [Parameter(Position=1)]
    [Array]$Sequence,
    
    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject

)

    process {
        if ($Sequence -notcontains $InputObject) {
            $InputObject
        }
    }

}


##############################################################################
#.SYNOPSIS
# Returns the items that exist in both the pipeline input and another
# collection.
#
#.PARAMETER Sequence
#.PARAMETER InputObject
##############################################################################
function Linq-Intersect {

[CmdletBinding()]
param(
    
    [Parameter(Position=1)]
    [Array]$Sequence,
    
    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject

)

    process {
        if ($Sequence -contains $InputObject) {
            $InputObject
        }
    }

}


##############################################################################
#.SYNOPSIS
# Selects a property, property set, or ScriptBlock projection of the input.
#
#.DESCRIPTION
# This cmdlet has virtually no advantages over using ForEach-Object to
# project a value out to the pipeline, but I implemented it anyway because
# of some coding OCD I have.
#
#.PARAMETER Selector
# If specified, selects a value based on the input item.
# Otherwise, the input item itself will be selected.
#
#.PARAMETER InputObject
# The item to process, typically passed from a pipeline.
##############################################################################
function Linq-Select {
    
[CmdletBinding()]
param(
    
    [Parameter(Position=1, Mandatory=$true)]
    [Object]$Selector,
    
    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject

)
    
    process {
        Invoke-Selector $InputObject $Selector
    }

}

##############################################################################
#.SYNOPSIS
# Similar to Linq-Select but always ensures the output is wrapped in an array.
#
#.PARAMETER Selector
# If specified, selects a value based on the input item.
# Otherwise, the input item itself will be selected.
# The difference between this and Linq-Select is that the output will always
# be an array even if the sequence only produces one object.
#
#.PARAMETER InputObject
# The item to process, typically passed from a pipeline.
##############################################################################
function Linq-SelectMany {

[CmdletBinding()]
param(
    
    [Parameter(Position=1, Mandatory=$true)]
    [Object]$Selector,
    
    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject

)
    
    process {
        ,(Invoke-Selector $InputObject $Selector)
    }

}

##############################################################################
#.SYNOPSIS
# Returns the zero-based position of the first element in a sequence that
# meets the specified criteria.
#
#.PARAMETER Selector
# The predicate that the found item must match.
#
#.PARAMETER InputObject
# The item to process, typically passed from a pipeline.
##############################################################################
function Linq-IndexOf {
    
[CmdletBinding()]
param(

    [Parameter(Position=1,Mandatory=$true)]
    [ScriptBlock]$Predicate,

    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject

)

    begin { 
        $CurrentIndex = -1
        $FoundIndex = -1
    }
    
    process { 

        $CurrentIndex += 1

        if ( $FoundIndex -ge 0 ) { return }
        
        if ( Test-Predicate $InputObject $Predicate ) {
            $FoundIndex = $CurrentIndex
            $FoundIndex
        }

    }
    
    end {
        if ($FoundIndex -eq -1) { -1 }
    }

}

##############################################################################
#.SYNOPSIS
# Drills into an input object based on one or more property names to simplify
# access to data inside deep hierarchical structures.
#
#.DESCRIPTION
# This concept is somewhat difficult to describe and it has no corresponding
# feature in LINQ. A closer analogy would be XPath. Given an object that
# contains a property which is a collection of other objects, property names
# can be specified that cause Linq-Expand to evaluate a property, enumerate
# the items, select the next property, enumerate the items, and so on.
#
#.PARAMETER Property
# One or more property names that describes a path into the input object.
# Separate multiple property names with commas.
#
#.PARAMETER InputObject
# The item to process, typically passed from a pipeline.
#
#.EXAMPLE
# # where you typically do this...
# Get-Command | %{$_.ParameterSets} | %{$_.Parameters} | %{$_.Attributes} | %{$_.TypeId}
#
# # you can now do this...
# Get-Command | Expand ParameterSets,Parameters,Attributes,TypeId
##############################################################################
function Linq-Expand {

[CmdletBinding()]
param(

    [Parameter(Position=1,Mandatory=$true)]
    [String[]]$Property,        

    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject
    
)
    
    process {
    
        if ( $InputObject -eq $null ) { return }
        
        $OutputObjects = @($InputObject)
        foreach ($P in $Property) {
            $OutputObjects = @($OutputObjects | %{ $_.$P })
        }
        
        $OutputObjects
    
    }

}


##############################################################################
#.SYNOPSIS
# Returns items from a sequence whose selected values match one or more
# wildcard patterns.
#
#.DESCRIPTION
# This function uses the wildcard matching features of PowerShell to
# determine if the selected value matches one or more wildcard patterns
# and if so, the input object is passed along the pipeline.
#
# A particularly ugly piece of code is needed if you want to accept an array
# of strings for a parameter and allow the user to specify wildcards in them.
# Consider the -Include parameter of Get-ChildItem that allows you to specify
# wildcards such as:
#
# Get-ChildItem . -Include *.ps1,*.psm1
#
# The problem is you have to loop over the input set and loop over the
# patterns checking for a match on any of them. This function simplifies that
# process by rolling it into a single pipeline-aware cmdlet.
#
#.PARAMETER Pattern
# One or more wildcard patterns that will be matched against a value
# selected from the input object.
#
#.PARAMETER Selector
# Selects a property of the input object or some other value based on the
# input object to be tested against the patterns. If not specified, the
# input object itself is matched.
#
#.PARAMETER InputObject
# The object to test against the pattern.
#
#.PARAMETER Not
# If specified, the meaning of the pattern is inverted and only items not
# matching any of the patterns are returned.
#
#.EXAMPLE
# Get-Process | Like sql*,sharepoint*
#
#.LINK 
# Linq-WhereLike
##############################################################################
function Linq-WhereLike {

[CmdletBinding()]
param(
    
    [Parameter(Position=1)]
    [String[]]$Pattern,

    [Parameter(Position=2)]
    [Object]$Selector,
    
    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject,

    [Parameter()]
    [Switch]$Not

)

    process {
        if ($Pattern.Length) {
            if ($Selection = Invoke-Selector $InputObject $Selector) {
                if ($Not) {
                    for ($i=0; $i -lt $Pattern.Length; $i++) {
                        if ($Selection -notlike $Pattern[$i]) {
                        }
                        else {
                            return
                        }
                    }
                    return $InputObject
                }
                else {
                    for ($i=0; $i -lt $Pattern.Length; $i++) {
                        if ($Selection -like $Pattern[$i]) {
                            return $InputObject
                        }
                    }
                }
            }
        }
        else {
            return $InputObject
        }
    }

}


##############################################################################
#.SYNOPSIS
# Returns items from a sequence whose selected values match one or more
# regular expression patterns.
#
#.DESCRIPTION
# This function uses the regular expression features of PowerShell to
# determine if the selected value matches one or more regex patterns
# and if so, the input object is passed along the pipeline.
#
# A particularly ugly piece of code is needed if you want to accept an array
# of strings for a parameter and allow the user to specify wildcards in them.
# Consider the -Include parameter of Get-ChildItem that allows you to specify
# wildcards such as:
#
# Get-ChildItem . -Include *.ps1,*.psm1
#
# The problem is you have to loop over the input set and loop over the
# patterns checking for a match on any of them. This function simplifies that
# process by rolling it into a single pipeline-aware cmdlet.
#
#.PARAMETER Pattern
# One or more regular expression patterns that will be matched against a value
# selected from the input object.
#
#.PARAMETER Selector
# Selects a property of the input object or some other value based on the
# input object to be tested against the patterns. If not specified, the
# input object itself is matched.
#
#.PARAMETER InputObject
# The object to test against the pattern.
#
#.PARAMETER Not
# If specified, the meaning of the pattern is inverted and only items not
# matching any of the patterns are returned.
#
#.EXAMPLE
# Get-Process | Match sql.*,sharepoint.*
#
#.LINK 
# Linq-WhereMatch
##############################################################################
function Linq-WhereMatch {

[CmdletBinding()]
param(
    
    [Parameter(Position=1)]
    [String[]]$Pattern,

    [Parameter(Position=2)]
    [Object]$Selector,
    
    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject,
    
    [Parameter()]
    [Switch]$Not,
    
    [Parameter()]
    [Switch]$IgnoreNull

)

    process {
        if ($Pattern.Length) {
            if ($Selection = Invoke-Selector $InputObject $Selector) {
                if ($Not) {
                    for ($i=0; $i -lt $Pattern.Length; $i++) {
                        if ($Selection -notmatch $Pattern[$i]) {
                        }
                        else {
                            return
                        }
                    }
                    return $InputObject
                }
                else {
                    for ($i=0; $i -lt $Pattern.Length; $i++) {
                        if ($Selection -match $Pattern[$i]) {
                            return $InputObject
                        }
                    }
                }
            }
        }
        else {
            return $InputObject
        }
    }

}


##############################################################################
# PRIVATE FUNCTIONS
##############################################################################

# It is actually surprisingly difficult to write a function (in a module)
# that uses $_ in scriptblocks that it takes as parameters. This is a strange
# issue with scoping that seems to only matter when the function is a part
# of a module which has an isolated scope.
# 
# In the case of this code:
# 1..10 | Add-Ten { $_ + 10 }
#
# ... the function Add-Ten must jump through hoops in order to invoke the
# supplied scriptblock in such a way that $_ represents the current item
# in the pipeline.
#
# Which brings me to Invoke-ScriptBlock.
# This function takes a ScriptBlock as a parameter, and an object that will
# be supplied to the $_ variable. Since the $_ may already be defined in
# this scope, we need to store the old value, and restore it when we are done.
# Unfortunately this can only be done (to my knowledge) by hitting the
# internal api's with reflection. Not only is this an issue for performance,
# it is also fragile. Fortunately this appears to still work in PowerShell
# version 2 through 3 beta.
# No warranties expressed or implied.

function Invoke-ScriptBlock {

[CmdletBinding()]
param (
    
    [Parameter(Position=1,Mandatory=$true)]
    [ScriptBlock]$ScriptBlock,
    
    [Parameter(ValueFromPipeline=$true)]
    [Object]$InputObject
    
)
    
    begin {
        $SessionStateProperty = [ScriptBlock].GetProperty('SessionState',([System.Reflection.BindingFlags]'NonPublic,Instance'))
        $SessionState = $SessionStateProperty.GetValue($ScriptBlock, $null)
    }
    process {
        $NewUnderBar = $InputObject
        $OldUnderBar = $SessionState.PSVariable.GetValue('_')
        try {
            $SessionState.PSVariable.Set('_', $NewUnderBar)
            $SessionState.InvokeCommand.InvokeScript($SessionState, $ScriptBlock, @())
        }
        finally {
            $SessionState.PSVariable.Set('_', $OldUnderBar)
        }
    }

}

function Invoke-Selector($InputObject, [Object]$Selector) {
    if ($Selector -is [ScriptBlock]) {
        Invoke-ScriptBlock -InputObject:$InputObject -ScriptBlock:$Selector
    }
    elseif ($Selector -is [String]) {
        $InputObject.$Selector
    }
    elseif ($Selector -is [String[]]) {
        Select-Object -InputObject:$InputObject -Property:$Selector
    }
    elseif ($Selector -eq $null) {
        $InputObject
    }
    else {
        throw 'Selector must be a ScriptBlock, an individual property, or a property set.'
    }
}

function Test-Predicate($InputObject, [Object]$Predicate) {
    if ($Predicate) {
        if (Invoke-ScriptBlock -InputObject:$InputObject -ScriptBlock:$Predicate ) {
            return $true 
        }
        else {
            return $false
        }
    }
    else {
        return $true # no predicate always includes inputobject
    }
}


##############################################################################
# EXPORTS
##############################################################################


Export-ModuleMember -Function Linq-All
Export-ModuleMember -Function Linq-Any
Export-ModuleMember -Function Linq-Average
Export-ModuleMember -Function Linq-Count
Export-ModuleMember -Function Linq-Distinct
Export-ModuleMember -Function Linq-DistinctBy
Export-ModuleMember -Function Linq-Except
Export-ModuleMember -Function Linq-Expand
Export-ModuleMember -Function Linq-First
Export-ModuleMember -Function Linq-IndexOf
Export-ModuleMember -Function Linq-Intersect
Export-ModuleMember -Function Linq-Last
Export-ModuleMember -Function Linq-Max
Export-ModuleMember -Function Linq-Min
Export-ModuleMember -Function Linq-Repeat
Export-ModuleMember -Function Linq-Select
Export-ModuleMember -Function Linq-SelectMany
Export-ModuleMember -Function Linq-Single
Export-ModuleMember -Function Linq-Skip
Export-ModuleMember -Function Linq-SkipWhile
Export-ModuleMember -Function Linq-Sum
Export-ModuleMember -Function Linq-Take
Export-ModuleMember -Function Linq-TakeWhile
Export-ModuleMember -Function Linq-ToDictionary
Export-ModuleMember -Function Linq-ToSet

Export-ModuleMember -Function Linq-WhereMatch
Export-ModuleMember -Function Linq-WhereLike