<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   PSelect {
      Field company
      Field raisedAmt -as AvgRaisedAmt -Average -Unit Currency
      Field raisedAmt -as TotalRaisedAmt -Sum -Unit Currency
      Field raisedAmt -as MaxRaisedAmt -Maximum -Unit Currency
      Field raisedAmt -as Rounds -Count
      GroupBy company
      FromCsv "TechCrunchcontinentalUSA.csv"
   }
#>
function PSelect {
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,Position=0)]
        [Scriptblock]
        $ScriptBlock,

        # Parameter help description
        [Parameter(ValueFromPipeline=$true)]
        [Object[]]
        $InputObject
    )

    Begin {
        $PSelectParams = @{}
    }

    Process { FromPipeline -Object $InputObject }

    End {
        & $ScriptBlock

        If (-not $PSelectParams.ContainsKey("GroupBy")) {
            Throw "GroupBy is required."
        }

        $groups = $PSelectParams.Data | 
            Group-Object $PSelectParams.GroupBy

        If ($PSelectParams.ContainsKey("Sort")) {            
            $groups = $groups | Sort-Object Name -Descending:$PSelectParams["Sort"]
        }

        foreach ($group in $groups) {

            $output = New-Object PSObject

            foreach ($field in $PSelectParams.Fields) {
                $propertyName = $field["Name"]
                $value = $group.Name

                if ($field.ContainsKey("As")) {
                    $propertyName = $field["As"]
                }

                if ($field.ContainsKey("Aggregate")) {

                    $aggregates = $group.Group | 
                        Measure-Object -Property $field["Name"] -Sum -Average -Maximum -Minimum

                    switch ($field["Aggregate"])
                    {
                        'Average' {$value = $aggregates.Average}
                        'Sum'     {$value = $aggregates.Sum}
                        'Minimum' {$value = $aggregates.Minimum}
                        'Maximum' {$value = $aggregates.Maximum}
                        'StdDev' {
                            $avg = $aggregates.Average
                            $values = New-Object System.Collections.Generic.List[double]
                            $null = $group.Group.ForEach({
                                $f = $field["Name"]
                                $values.Add($_.$f)
                            })
                            $sumOfSquaresOfDifferences = [System.Linq.Enumerable]::Sum([System.Linq.Enumerable]::Select($values, [System.Func[double,double]] {param($val) ($val - $avg) * ($val - $avg)}))
                            $value = [Math]::Sqrt($sumOfSquaresOfDifferences/$aggregates.Count)
                        }
                        Default   {$value = $aggregates.Count}
                    }
                }

                # 
                if ($field.ContainsKey("Unit")) {
                    switch ($field["Unit"]) {
                        'Currency'   {$value = $value.ToString("C")}
                        #'Currency'   {
                         #   $value = "{0,18:C}" -f $value
                            #"{0,10:C}" -f 100
                        #}
                        'Percentage' {$value = $value.ToString("P")}
                    }
                }

                if ($field.ContainsKey("Format")) {
                    $value = $field["Format"] -f $value
                }

                $output | Add-Member -NotePropertyName $propertyName -NotePropertyValue $value
                
            }
            $output.PSObject.TypeNames.Insert(0, "PSelectRecord")
            $output
        }
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Field {
    [CmdletBinding(DefaultParameterSetName="Default")]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory,Position=0)]     
        [String]
        $Name,

        # Param2 help description
        [Parameter(Position=1)] 
        [String]
        $As,

        [Parameter(Position=2,ParameterSetName="Unit")]
        [ValidateSet("Currency","Percentage","Seconds","Minutes","Hours","Days","Weeks","Months","Years")]
        [String]
        $Unit,

        [Parameter(Position=2,ParameterSetName="Format")]
        [ValidatePattern("{0.*}")]
        [String]
        $Format,

        [Switch]
        $Average,

        [Switch]
        $Sum,

        [Switch]
        $Minimum,

        [Switch]
        $Maximum,

        [Switch]
        $Count,

        [Switch]
        $StdDev        
    )

    Begin {
        If (-not $PSelectParams.ContainsKey("Fields")) {
            $PSelectParams.Add("Fields", (New-Object System.Collections.ArrayList))
        }
    }

    End {

        $field = @{Name=$Name}

        if ($PSBoundParameters.ContainsKey("As")) { $field.Add("As", $As) }
        if ($PSBoundParameters.ContainsKey("Unit")) { $field.Add("Unit", $Unit) }
        if ($PSBoundParameters.ContainsKey("Format")) { $field.Add("Format", $Format) }

        if ($Average) { $field.Add("Aggregate", "Average") }
        elseif ($Sum)     { $field.Add("Aggregate", "Sum") }
        elseif ($Minimum) { $field.Add("Aggregate", "Minimum") }
        elseif ($Maximum) { $field.Add("Aggregate", "Maximum") }
        elseif ($Count)   { $field.Add("Aggregate", "Count") }
        elseif ($StdDev)  { $field.Add("Aggregate", "StdDev") }

        $PSelectParams.Fields.Add($field) | Out-Null
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function GroupBy {
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   Position=0)]
        [string[]]
        $Name
    )

    If (-not $PSelectParams.ContainsKey("GroupBy")) {
        $PSelectParams.Add("GroupBy", ($Name))
    }
    else
    {
        Throw "Only one source is supported."
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function FromCsv {
    [CmdletBinding(DefaultParameterSetName="csv")]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   Position=0,
                   ParameterSetName="csv")]
        [string]
        $Path
    )

    If (-not $PSelectParams.ContainsKey("Data")) {
        $PSelectParams.Add("Data", (Get-Content -Path $Path | ConvertFrom-Csv))
    }
    else
    {
        Throw "Only one From statement is supported."
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function FromPipeline {
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   Position=0,
                   ParameterSetName="csv")]
        [Object[]]
        $Object
    )

    If (-not $PSelectParams.ContainsKey("Data")) {
        $PSelectParams.Add("Data", (New-object Collections.ArrayList))
    }

    $Object | Foreach-Object {
        $null = $PSelectParams["Data"].Add($PSItem)
    }
}

function SortData {
    [CmdletBinding(DefaultParameterSetName="Ascending")]
    param (
        [Parameter(ParameterSetName="Ascending")]
        [Switch]$Ascending,

        [Parameter(ParameterSetName="Descending")]
        [Switch]$Descending
    )

    If (-not $PSelectParams.ContainsKey("Sort")) {
        $dirDesc=$false

        if($Descending) {
            $dirDesc=$true
        }
        
        $PSelectParams.Add("Sort", $dirDesc)
    }
    else {
        Throw "Only one SortData statement is supported."
    }
}