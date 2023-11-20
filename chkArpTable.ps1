function getDuplicatedValues {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Array]$arrayTablaARP
    )

    # Manejo de Errores
    if ($null -eq $arrayTablaARP -or $arrayTablaARP.Count -eq 0) {
        throw "El parámetro 'arrayTablaARP' debe ser un arreglo no nulo y contener elementos."
    }

    $ipDuplicadas = @()
    $ipEncontradas = @{}
    $macDuplicadas = @()
    $macEncontradas = @{}

    foreach ($fila in $arrayTablaARP) {
        # Debe contener al menos 2 columnas
        if ($fila.Count -ge 2) {
            $ip = $fila[0]
            $mac = $fila[1]

            # Check if the IP address is already found and the MAC address is not "00-00-00-00-00-00"
            if ($ipEncontradas.ContainsKey($ip) -and $mac -ne "00-00-00-00-00-00") {
                $ipDuplicadas += [PSCustomObject]@{
                    Ip = $ip
                    Mac = $mac
                }
            } else {
                $ipEncontradas[$ip] = $true
            }

            # Check if the MAC address is already found and the MAC address is not "00-00-00-00-00-00"
            if ($macEncontradas.ContainsKey($mac) -and $mac -ne "00-00-00-00-00-00") {
                $macDuplicadas += [PSCustomObject]@{
                    Ip = $ip
                    Mac = $mac
                }
            } else {
                $macEncontradas[$mac] = $true
            }
        }
    }

    # Create a hashtable to store the results
    $resultados = @{
        "IpDuplicadas" = $ipDuplicadas
        "MacDuplicadas" = $macDuplicadas
    }
    return $resultados 
}

<#-------------------------------------------------------------#>

function getMacList {

    $interfaces = Get-NetAdapter -Physical

    # Creamos una lista que puede contener una matriz de objetos (IP, MAC)
    $tablaARP = New-Object 'System.Collections.Generic.List[System.Object[]]'
    Clear-Host

    Import-Module .\Funciones.ps1

    foreach ($interface in $interfaces) { 
        # Obtén una lista de las direcciones IP de la interfaz
        $ips = Get-NetIPAddress -InterfaceAlias $interface.Name

        # Recorre las direcciones IP     
            if($null -ne $ips.IPAddress){
                $neighbors = Get-NetNeighbor -InterfaceAlias $($interface.Name) -ErrorAction SilentlyContinue
                if ($neighbors) { 
                    Write-Output "Interface: $($interface.Name)"
                    Write-Output "IP Address: $($ips.IPAddress)"
                    Write-Output ""
                    Write-Output $neighbors
                    Write-Output ""  

                    foreach($neighbor in $neighbors){
                        $newTupla = @($neighbor.IPAddress, $neighbor.LinkLayerAddress)
                        $tablaARP.Add($newTupla)
                    }                
                }
            }
            <# $tablaARP.Add(@("",""))#>
    }   
    return $tablaARP 
}
       
<#-------------------------------------------------------------#>

try {
    $tablaARP = getMacList
    $duplicatedValues = getDuplicatedValues $tablaARP

    foreach ($key in $duplicatedValues.Keys) {
        $duplicatedValue = $duplicatedValues[$key]
    
        Write-Output ""
        Write-Output "$key :"
    
        foreach ($item in $duplicatedValue) {
            Write-Host " $($item.Ip)  $($item.Mac)"
        }
    }   
}
catch {
    Write-Error "Errores al procesar los datos $($_.Exception.Message)" -ErrorAction Stop
}




    <# foreach ($entry in $duplicatedValues.GetEnumerator()) {
        $key = $entry.Key
        $duplicatedValue = $entry.Value

        Write-Output ""
        Write-Output "$key :"

        <#
        Se recorre el array $macDuplicadas y se accede a las propiedades "Ip" y "Mac" de cada objeto 
        utilizando la sintaxis $item.Ip y $item.Mac. Luego, se muestra cada par de valores IP y MAC
        
        foreach ($value in $duplicatedValue) {
            foreach ($item in $value) {
                Write-Host " $($item.Ip)  $($item.Mac)"
            }       
        }
    } #>