#Clear-Host


function findDuplicatedValues {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Array]$arrayTablaARP
    )
  
    # Error handling
    if ($null -eq $arrayTablaARP -or $arrayTablaARP.Count -eq 0) {
        throw "El parámetro 'arrayTablaARP' debe ser un arreglo no nulo y contener elementos."
    }

    $duplicatedValues = [ordered]@{
        Ip = @()
        Mac = @()
    }
    $foundValues = @{}

    foreach ($fila in $arrayTablaARP) {
        if ($fila.Count -ge 2) {
            $ip = $fila[0]
            $mac = $fila[1]

            # Check if either IP or MAC address is already found and the MAC address is not "00-00-00-00-00-00"
            if ($foundValues.ContainsKey($ip) -and $mac -ne "00-00-00-00-00-00") {
                $duplicatedValues.Ip += [PSCustomObject]@{
                    Ip = $ip
                    Mac = $mac
                }
            }

            if ($foundValues.ContainsKey($mac) -and $mac -ne "00-00-00-00-00-00") {
                $duplicatedValues.Mac += [PSCustomObject]@{
                    Ip = $ip
                    Mac = $mac
                }
            }

            $foundValues[$ip] = $true
            $foundValues[$mac] = $true
        }
    }

    return $duplicatedValues  
}

<#-------------------------------------------------------------#>

function getMacList {
    param (
        [string]$outputFile
    )
    $interfacesList = Get-NetAdapter -Physical

    # Creamos una lista que puede contener una matriz de objetos (IP, MAC)
    # $tablaARP = New-Object 'System.Collections.Generic.List[System.Object[]]'
    $arpTable = [System.Collections.ArrayList]@()
    
    $outputMessage = "Tabla ARP agrupada por las interfaces fisicas.`n"

    foreach ($interface in $interfacesList) { 
        # Obtén una lista de las direcciones IP de la interfaz
        $ips = Get-NetIPAddress -InterfaceAlias $interface.Name
  
            if($ips.IPAddress){
                $neighbors = Get-NetNeighbor -InterfaceAlias $($interface.Name) -ErrorAction SilentlyContinue
                if ($neighbors) { 
                    $outputMessage += "Interface: $($interface.Name)`nIP Address: $($ips.IPAddress)`n-------------------------------------`n"

                    foreach($neighbor in $neighbors){
                        $newTupla = @($neighbor.IPAddress, $neighbor.LinkLayerAddress)
                        $arpTable.Add($newTupla)
                        $outputMessage += "$newTupla`n"
                    }  
                    $outputMessage += "`n"
                    #$outputMessage | Out-File -FilePath $outputFile -Force
                }
                else {
                    Write-Error "No se ha podido obtener la lista"
                }
            }
            <# $tablaARP.Add(@("",""))#>
    }   
    $outputMessage | Out-File -FilePath $outputFile -Force
    return $arpTable 
}
       
<#-------------------------------------------------------------#>


try {
    $MACListFich = "MACxInterfaces.txt"

    . .\Funciones.ps1

    $tablaARP = getMacList $MACListFich
    $duplicatedValues = findDuplicatedValues $tablaARP
    Write-Output "Entradas duplicadas en la tabla ARP:"
    Write-Output ""
    foreach ($key in $duplicatedValues.Keys) {
        $duplicatedValue = $duplicatedValues[$key]
    
        Write-Output "$key :"
    
        foreach ($item in $duplicatedValue) {
            Write-Host " $($item.Ip)  $($item.Mac)"
        }
    }   
    Write-Output "Listado de la tabla ARP en el fichero $MACListFich"
    Write-Output ""
}
catch {
    Write-Error "Errores al procesar los datos $($_.Exception.Message)" -ErrorAction Stop
}
