
<# 
.SYNOPSIS
	Muestra la fecha y hora de las estaciones de un AD
.PARAMETER
.EXAMPLE
	PS> ./Get-TimeAD.ps1
.LINK

.NOTES

#>

# Lista de nombres de computadoras del dominio
$computerADList = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name

$archivoSalida = "HoraComputadorasAD.txt"
$timexComputadoras = New-Object System.Collections.Generic.List[string]

foreach ($computer in $computerADList) {
    $online = Test-Connection -ComputerName $computer -Count 2 -Quiet -ErrorAction SilentlyContinue
    
    if ($online) {
        try {
            $objectHora = Get-WmiObject -Class Win32_LocalTime -ComputerName $computer -ErrorAction Stop
            $resultado = "Hora en $computer : $($objectHora.Day)/$($objectHora.Month)/$($objectHora.Year) $($objectHora.Hour):$($objectHora.Minute):$($objectHora.Second)"
            Write-Host $resultado 
            $timexComputadoras.Add($resultado)     
        } catch {
            $errorMensaje = "Error al obtener obtener la hora en $computer. Error: $_"
            Write-Host $errorMensaje
            $timexComputadoras.Add($errorMensaje)
        }
    } else {
        $offlineMensaje = "La computadora $computer no esta encendida o no responde al ping."
        Write-Host $offlineMensaje
        $timexComputadoras.Add($offlineMensaje)
    }
}

$timexComputadoras | Set-Content -Path $archivoSalida -Force
Write-Host "Resultados guardados en $archivoSalida"
