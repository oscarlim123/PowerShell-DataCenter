[string[]]$adapterName = "Ethernet","Wi-Fi","Ethernet 2"
$interfaces = Get-NetAdapter | Where-Object { $_.Name -in $adapterName }

# Recorre las interfaces de red
foreach ($interface in $interfaces) {
    
    # Obtén una lista de las direcciones IP de la interfaz
    $ips = Get-NetIPAddress -InterfaceAlias $interface.Name

    # Recorre las direcciones IP
    foreach ($ip in $ips) {
       
        if($ip.IPAddress -ne $null){
            $neighbors = Get-NetNeighbor -InterfaceAlias $($interface.Name) -ErrorAction SilentlyContinue
            if ($neighbors) {
                Write-Output "Interface: $($interface.Name)"
                Write-Output "IP Address: $($ip.IPAddress)"
                #Write-Output "MAC Address: $($neighbors.LinkLayerAddress)"
                Write-Output ""
                Write-Output $neighbors
                Write-Output ""
            }
        }
    }
}