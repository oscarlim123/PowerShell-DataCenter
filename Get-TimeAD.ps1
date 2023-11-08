# Lista de nombres de computadoras del dominio
$computadoras = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name

# Ruta del archivo de salida
$archivoSalida = "ResultadoHoraComputadoras.txt"

# Iterar a través de las computadoras y obtener la hora
foreach ($computadora in $computadoras) {
    $online = Test-Connection -ComputerName $computadora -Count 1 -Quiet -ErrorAction SilentlyContinue
    if ($online) {
        try {
            $hora = Invoke-Command -ComputerName $computadora -ScriptBlock { Get-Date } -ErrorAction Stop
            $resultado = "Hora en $computadora : $hora"
            Write-Host $resultado
            Add-Content -Path $archivoSalida -Value $resultado
        } catch {
            $errorMensaje = "No se pudo obtener la hora en $computadora. Error: $_"
            Write-Host $errorMensaje
            Add-Content -Path $archivoSalida -Value $errorMensaje

            # Forzar la sincronización con el servidor de dominio
            Write-Host "Forzando sincronización de tiempo en $computadora con el servidor de dominio..."
            Invoke-Command -ComputerName $computadora -ScriptBlock { w32tm /resync /rediscover } -ErrorAction SilentlyContinue
        }
    } else {
        $offlineMensaje = "La computadora $computadora no está encendida o no responde al ping."
        Write-Host $offlineMensaje
        Add-Content -Path $archivoSalida -Value $offlineMensaje
    }
}

Write-Host "Resultados guardados en $archivoSalida"
