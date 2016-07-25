# PSelect

A SQL-ish DSL in PowerShell to assist in aggregating collections of data.

```powershell
PS C:\Source\GitHub\PSelect> PSelect {
    Field category
    Field raisedAmt -as AvgRaisedAmt -Average -Unit Currency
    Field raisedAmt -as TotalRaisedAmt -Sum -Unit Currency
    Field raisedAmt -as MaxRaisedAmt -Maximum -Unit Currency
    Field raisedAmt -as MinRaisedAmt -Min -Unit Currency
    Field raisedAmt -as Rounds -Count
    GroupBy category
    SortData
    FromCsv TechCrunchcontinentalUSA.csv
} |ft -AutoSize

category   AvgRaisedAmt       TotalRaisedAmt     MaxRaisedAmt       MinRaisedAmt       Rounds
--------   ------------       --------------     ------------       ------------       ------
               $15,554,166.67    $373,300,000.00    $150,000,000.00        $900,000.00     24
biotech        $19,312,500.00     $77,250,000.00     $37,000,000.00        $250,000.00      4
cleantech      $18,492,857.14    $258,900,000.00     $57,000,000.00      $1,000,000.00     14
consulting      $6,427,000.00     $32,135,000.00     $13,000,000.00         $10,000.00      5
hardware       $21,141,025.64    $824,500,000.00    $130,000,000.00        $100,000.00     39
mobile          $6,729,583.33    $323,020,000.00     $25,000,000.00         $20,000.00     48
other           $7,490,625.00    $119,850,000.00     $29,000,000.00        $300,000.00     16
software        $9,979,823.53  $1,017,942,000.00     $60,000,000.00         $10,000.00    102
web             $9,739,300.29 $11,765,074,750.00    $300,000,000.00          $6,000.00   1208
```