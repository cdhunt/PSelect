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
        [Parameter(Mandatory=$true,
                   Position=0)]
        [Scriptblock]
        $ScriptBlock
    )

    Begin {
        $PSelectParams = @{}
    }

    Process { }

    End {
        & $ScriptBlock

        If (-not $PSelectParams.ContainsKey("GroupBy")) {
            Throw "GroupBy is required."
        }

        $groups = $PSelectParams.Data | 
            Group-Object $PSelectParams.GroupBy

        If ($PSelectParams.ContainsKey("Sort")) {            
            $groups = $groups | sort name -Descending:$PSelectParams["Sort"]
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
                        Default   {$value = $aggregates.Count}
                    }
                }

                if ($field.ContainsKey("Unit")) {
                    switch ($field["Unit"]) {
                        #'Currency'   {$value = $value.ToString("C")}
                        'Currency'   {
                            $value = "{0,18:C}" -f $value
                            #"{0,10:C}" -f 100
                        }
                        'Percentage' {$value = $value.ToString("P")}                        
                    }
                }

                $output | Add-Member -MemberType NoteProperty -Name $propertyName -Value $value
            }

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
    [CmdletBinding(DefaultParameterSetName="Count")]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   Position=0)]
        [String]
        $Name,

        # Param2 help description
        [Parameter(Position=1)]
        [String]
        $As,

        [Parameter(Position=2)]
        [ValidateSet("Currency","Percentage","Seconds","Minutes","Hours","Days","Weeks","Months","Years")]
        [String]
        $Unit,

        [Parameter(ParameterSetName="Average")]
        [Switch]
        $Average,

        [Parameter(ParameterSetName="Sum")]
        [Switch]
        $Sum,

        [Parameter(ParameterSetName="Minimum")]
        [Switch]
        $Minimum,

        [Parameter(ParameterSetName="Maximum")]
        [Switch]
        $Maximum,

        [Parameter(ParameterSetName="Count")]
        [Switch]
        $Count
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

        if ($Average) { $field.Add("Aggregate", "Average") }
        if ($Sum)     { $field.Add("Aggregate", "Sum") }
        if ($Minimum) { $field.Add("Aggregate", "Minimum") }
        if ($Maximum) { $field.Add("Aggregate", "Maximum") }
        if ($Count)   { $field.Add("Aggregate", "Count") }

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
        [string]
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
        Throw "Only one source is supported."
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
        if($Descending) {$dirDesc=$true}
        $PSelectParams.Add("Sort", $dirDesc)
    }
}