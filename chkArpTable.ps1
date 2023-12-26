#Clear-Host

<# 
.SYNOPSIS
This function takes an array of IP and MAC addresses, searches for duplicates, 
and returns an object that contains the duplicated IP and MAC addresses.
.PARAMETER arrayTablaARP
Array containning arp table
.EXAMPLE
$duplicatedValues = Find-DuplicatedValues -arrayTablaARP $arpTable
#>
function Find-DuplicatedValues {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Array]$arrayTablaARP
    )
  
    $noMac = "00-00-00-00-00-00"
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
            if ($foundValues.ContainsKey($ip) -and $mac -ne $noMac) {
                $duplicatedValues.Ip += [PSCustomObject]@{
                    Ip = $ip
                    Mac = $mac
                }
            }

            if ($foundValues.ContainsKey($mac) -and $mac -ne $noMac) {
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

<#
.SYNOPSIS
The script gets the list of MAC addresses for physical interfaces on the system. 
It uses the PowerShell cmdlets Get-NetAdapter and Get-NetIPAddress to get the IP addresses for each interface 
and then uses the Get-NetNeighbor cmdlet to get the IP addresses and link layer (MAC) addresses of neighbors on the network. 
The script creates an ARP table that stores the tuples of neighbor IP and MAC addresses and also generates 
an output message that shows the information for each interface and its neighbors. 
Finally, the output message is saved to a specified file and the ARP table is returned.
.EXAMPLE
$arpTable = Get-MacList -outputFile $macListFile
#>
function Get-MacList {
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


# Specify the path to the file
$macListFile = "MACxInterfaces.txt"

try {
    . .\Funciones.ps1
}
catch {
    Write-Error "Error processing data: $($_.Exception.Message)" -ErrorAction Stop
}

$arpTable = Get-MacList -outputFile $macListFile
$duplicatedValues = Find-DuplicatedValues -arrayTablaARP $arpTable

$interfacesList = Get-NetAdapter -Physical | Select-Object -ExpandProperty Name
$fakeIP = Get-NetNeighbor -InterfaceAlias $interfacesList[0] | Where-Object {$_.IPAddress -notmatch "^172\.23\.6\."}

Write-Output "Duplicates entries in the ARP table:"
Write-Output ""

try {
    # Iterate through the duplicated entries
    foreach ($key in $duplicatedValues.Keys) {
        $duplicatedValue = $duplicatedValues[$key]
    
        Write-Output "$key :"
    
        # Iterate through the items in each duplicated entry
        foreach ($item in $duplicatedValue) {
            Write-Output " $($item.Ip)  $($item.Mac)"
        }
    }   
    Write-Output "ARP table listing saved to the file $macListFile"
    Write-Output ""
    Write-Output $fakeIP
}   
catch [System.Exception]{
    Write-Error "Error processing data: $($_.Exception.Message)" -ErrorAction Stop
}
