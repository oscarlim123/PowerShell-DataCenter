# Obtén una lista de las conexiones TCP activas en un puerto determinado
$connections = Get-NetTCPConnection

# Filtra las conexiones por puerto
$connections = $connections | Where-Object { $_.LocalPort -eq 4192 }

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