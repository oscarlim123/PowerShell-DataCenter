param(
    [Parameter(Mandatory=$true)]
    [String] $Location,
    [Parameter(Mandatory=$true)]
    [String[]] $Extensions
)

$Results = @{}
foreach ($Extension in $Extensions) {
    $CurrentExtension = $Extension.ToLower()
    $Count = (Get-ChildItem -Path $Location -Filter $CurrentExtension | Measure-Object).Count
    $Results[$Extension] = $Count
}

$Results
    