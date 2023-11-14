<# 
.SYNOPSIS
	Forzar la sincronización de las estaciones de un Directorio Activo con el servidor de dominio.
    Lanza los comandos de resincronización de tiempo en segundo plano
.EXAMPLE
	PS> ./rsyncTimeAD.ps1
.LINK
    https://github.com/oscarlim123/PowerShell-DataCenter
.NOTES
    Crea un fichero con los resultados
#>
$computerADList = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name

$archivoSalida = "Estaciones_sincronizadas.txt"
$timexComputadoras = New-Object System.Collections.Generic.List[string]

foreach ($computer in $computerADList) {
    try {
        $Session = New-PSSession -ComputerName $computer -ErrorAction Stop

        if ($Session.State -eq 'Opened') {           
            #region ParteModificable
                $TimeZone = Invoke-Command -ComputerName $computer -ScriptBlock { 
                    w32tm /resync /rediscover 
                } -AsJob -ErrorAction SilentlyContinue

                $rsync = "Sincronizacion de $computer"
                Write-Host $rsync
        
                $timexComputadoras.Add($rsync)
            #endregion
            Remove-PSSession -Session $Session
        } else {
            throw
        }
    }
    catch {
        $rsync = "Error al establecer la sesión remota en $computer : $($_.exception.message)"
        $timexComputadoras.Add($rsync)
        Write-Host $rsync
    } 
}

$timexComputadoras | Set-Content -Path $archivoSalida -Force
Write-Host "Resultados guardados en $archivoSalida"
