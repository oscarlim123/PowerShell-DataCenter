<# 
.SYNOPSIS
	Forzar la sincronización con el servidor de dominio
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
        $Session = New-PSSession -ComputerName $computer

        if ($Session.State -eq 'Opened') {           
            #region ParteModificable
                $TimeZone = Invoke-Command -ComputerName $computer -ScriptBlock { 
                    w32tm /resync /rediscover 
                } -ErrorAction SilentlyContinue

                $rsync = "Sincronizacion de $computer"
                Write-Host $rsync
        
                # Matriz con los resultados
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
