#######################################################################################################################
# DOCUMENTATION
#    https://codesteps.com/2019/03/28/powershell-bitwise-logical-operators/
#    https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/operators/bitwise-and-shift-operators
#
#
# SUMMARY
#    X | Q      sets bit(s) Q
#    X & ~Q     clears bit(s) Q
#    ~X         flips/inverts all bits in X
#
# Name                            C#      PShell      Description
# ------------------------------- ------- ----------- ---------------------------------------------------------------
# Bitwise complement operator     ~       -bnot       The ~ operator produces a bitwise complement of its operand by reversing each bit:
# Logical AND operator            &       -band       The & operator computes the bitwise logical AND of its integral operands:
# Logical exclusive OR operator   ^       -bxor       The ^ operator computes the bitwise logical exclusive OR, also known as the bitwise logical XOR, of its integral operands:
# Logical OR operator             |       -bor        The | operator computes the bitwise logical OR of its integral operands:
# Left-shift operator             <<      -shl        The << operator shifts its left-hand operand left by the number of bits defined by its right-hand operand.
# Right-shift operator            >>      -shr        The >> operator shifts its left-hand operand right by the number of bits defined by its right-hand operand.
#######################################################################################################################

function Flags-Add {
    param (
        [Parameter()] [int] $Value,
        [Parameter()] [int] $Flag
    )

    # return a | b;
    return $Value -bor $Flag
}

function Flags-Combine {
    param (
        [Parameter(Mandatory=$True, ValueFromRemainingArguments=$true)]
        [Hashtable[]] $Flags
    )

    if ($Flags.Length -eq 0)
    {
        return 0
    }

    $result = 0
    foreach ($flag in $Flags)
    {
        $result = $result -bor $flag
    }

    return $result
}

function Flags-Has {
    param (
        [Parameter()] [int] $Value,
        [Parameter()] [int] $Flag
    )

    # return (flag & BIT_7) == BIT_7;
    return ($Value -band $Flag) -eq $Flag;
}

function Flags-Remove {
    param (
        [Parameter()] [int] $Value,
        [Parameter()] [int] $Flag
    )

    # remove a & ~b
    return $Value -band (-bnot $Flag)
}

function Flags-Toggle {
    param (
        [Parameter()] [int] $Value,
        [Parameter()] [int] $Flag
    )

    # return a ^ b;
    return $Value -bxor $Flag
}

Function Merge-Hashtables {
    param (
        #[Parameter(Mandatory = $true)]#, ValueFromRemainingArguments = $true)]
        [Hashtable[]] $Input
    )

    [Hashtable] $Output = @{}
    foreach ($Hashtable in $Input)
    {
        if ($Hashtable -is [Hashtable])
        {
            foreach ($Key in $Hashtable.Keys) 
            {
                $Output.$Key = $Hashtable.$Key
            }
        }
    }

    $Output
}

#######################################################################################################################
# EXPORTS
#######################################################################################################################
Export-ModuleMember -Function Flags-Add
Export-ModuleMember -Function Flags-Combine
Export-ModuleMember -Function Flags-Has
Export-ModuleMember -Function Flags-Remove
Export-ModuleMember -Function Flags-Toggle
Export-ModuleMember -Function Merge-Hashtables