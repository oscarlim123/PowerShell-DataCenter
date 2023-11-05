
<#---------------------------------------------------------------------
    Recibe una lista y crea un fichero con su contenido.
    Si ya existe se sobreescribe
---------------------------------------------------------------------#>
function GuardarEnArchivo([string[]]$listado, [string]$rutaArchivo = "Resultados.txt") {    
    $listado | Set-Content -Path $rutaArchivo -Force
    Write-Host "Valores guardados en el archivo: $rutaArchivo"
}

<#---------------------------------------------------------------------

---------------------------------------------------------------------#>
function FunctionName () {
    $zonasHorarias = [System.TimeZoneInfo]::GetSystemTimeZones()
    $zonaEncontrada = $false

    foreach ($zona in $zonasHorarias) {
        if ($zona.Id -eq "Cuba Standard Time") {
            $zonaEncontrada = $true
            return $true
            break
        }
    }
}
