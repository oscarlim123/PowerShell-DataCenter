<# 
.SYNOPSIS
	Hace una conexión a un rango de IPs y cambia la zona horaria
.DESCRIPTION
.PARAMETER UserName
    Nombre de usuario con permisos de administración para hacer la conexión
.EXAMPLE
	PS> ./Get-TimeZone.ps1 -u Administrator
.LINK
	https://github.com/oscarlim123/PowerShell-DataCenter
.NOTES
	Author: oscarlim@protonmail.com
#>

param(
    [Parameter(Mandatory=$true, HelpMessage="Nombre de usuario.")]
    [Alias("-u")]
    [ValidateNotNullOrEmpty()]
    [string]$UserName
)

. .\Funciones.ps1

#region Pedido de datos
    $securePasswd = Read-Host -Prompt "Contraseña" -AsSecureString
    $IPInicial = Read-Host -Prompt "IP inicial "
    $IPFinal = Read-Host -Prompt "IP final "
    Write-Host " "
#endregion

#region Preparacion de variables
    #region Comprobación de IP
        try {
            $Global:inicio = [System.Net.IPAddress]::Parse($IPInicial)
            $Global:fin = [System.Net.IPAddress]::Parse($IPFinal)
            $chkIP = CheckIP $IPInicial $IPFinal

            if ($chkIP -eq $false){
                Throw "Error"
            } 
        }
        catch {
            Write-Error "Hay errores en las direcciones IP proporcionadas $($_.Exception.Message)" -ErrorAction Stop
        }
    #endregion

    $Credential = New-Object PSCredential -ArgumentList ($UserName, $securePasswd)
    $count = 0;
    # Crear una lista vacía para el listado de zonas horarias
    $ZonasHorariasCambiadas = New-Object System.Collections.Generic.List[string]
    $ZonasHorariasCambiadas.Add("Hosts a los que se les cambió la Zona Horaria")
    $newZonaHoraria = "Cuba Standard Time"
    $currentIP = $inicio
#endregion

while ($currentIP.Address -le $fin.Address) {
    try {
        $Session = New-PSSession -ComputerName $currentIP -Credential $Credential
        if ($Session.State -eq 'Opened') {
            
            #region ParteModificable
                $TimeZones = Invoke-Command -Session $Session -ScriptBlock {
                    [System.TimeZoneInfo]::GetSystemTimeZones()
                }

                foreach ($timeZone in $TimeZones) {
                    if ($timeZone.Id -eq $newZonaHoraria) {
                        Write-Host "$HostName ($($Session.ComputerName)) tiene la zona horaria '$newZonaHoraria' existe."
                        
                        Invoke-Command -Session $Session -ScriptBlock {                       
                        Param($x) tzutil /s $x
                        } -ArgumentList $newZonaHoraria -AsJob

                        $ZonasHorariasCambiadas.Add("Zona horaria cambiada $HostName ($($Session.ComputerName)) : $($TimeZone)")
                        Write-Host "Zona Horaria cambiada"
                        break
                    }
                }               
            #endregion
            Remove-PSSession -Session $Session
            $count++;
        } else {
            Write-Host "No se pudo establecer la sesión remota. Estado de la sesión: $($Session.State)"
        }
    }
    catch {
        Write-Host "Error al establecer la sesión remota: $_"
    }

    $bytes = $currentIP.GetAddressBytes()
    $bytes[-1]++
    $currentIP = [System.Net.IPAddress]::new($bytes)
}

GuardarEnArchivo $ZonasHorariasCambiadas "SetListadoZonasHorarias.txt"
Write-Host "Cantidad de hosts chequeados: $count"
