# Specifies a path to one or more locations.
Param(
    [Parameter(Mandatory=$true)]
    [Alias("-p")]
    [ValidateNotNullOrEmpty()]
    [int]$Puerto
)

# Obtén una lista de las conexiones TCP activas en un puerto determinado
$connections = Get-NetTCPConnection

# Filtra las conexiones por puerto
$connections = $connections | Where-Object { $_.LocalPort -eq $Puerto }

$result = @{}

# Obtén estadísticas sobre cada conexión
foreach ($connection in $connections) {
    $result["Proceso"] = $connection.OwningProcessName
    $result["Origen"] = $connection.LocalAddress
    $result["Destino"] = $connection.RemoteAddress
    $result["Bytes recibidos"] = $connection.ReceivedBytes
    $result["Bytes enviados"] = $connection.SentBytes
}

$result