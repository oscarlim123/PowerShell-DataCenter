
# Forzar la sincronización con el servidor de dominio
#Write-Host "Forzando sincronización de tiempo en $computer con el servidor de dominio..."
#Invoke-Command -ComputerName $computer -ScriptBlock { w32tm /resync /rediscover } -ErrorAction SilentlyContinue

# Lista de nombres de computadoras del dominio
$computerADList = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name

$archivoSalida = "HoraComputadorasAD.txt"

foreach ($computer in $computerADList) {
    $online = Test-Connection -ComputerName $computer -Count 2 -Quiet -ErrorAction SilentlyContinue
    
    if ($online) {
        try {
            #$hora = Invoke-Command -ComputerName $computer -ScriptBlock { Get-Date } -ErrorAction Stop
            $objectHora = Get-WmiObject -Class Win32_LocalTime -ComputerName $computer -ErrorAction Stop

            $resultado = "Hora en $computer : $objectHora.Day/$objectHora.Month/$objectHora.Year $objectHora.Hour:$objectHora.Minute:$objectHora.Second"
            Write-Host $resultado
            Add-Content -Path $archivoSalida -Value $resultado       
        } catch {
            $errorMensaje = "Error al obtener obtener la hora en $computer. Error: $_"
            Write-Host $errorMensaje
            Add-Content -Path $archivoSalida -Value $errorMensaje
        }
    } else {
        $offlineMensaje = "La computadora $computer no esta encendida o no responde al ping."
        Write-Host $offlineMensaje
        Add-Content -Path $archivoSalida -Value $offlineMensaje
    }
}

Write-Host "Resultados guardados en $archivoSalida"
