<# 
.SYNOPSIS
	
.DESCRIPTION
	This PowerShell script checks ....
.PARAMETER accion
	
.EXAMPLE
	PS> ./check-subnet-mask.ps1 255.255.255.0
	✔️ subnet mask 255.255.255.0 is valid
.LINK
	https://github.com/fleschutz/PowerShell EJEMPLO
.NOTES
	Author: 



 El equipo remoto debe permitir conexiones remotas a través de WinRM. 
 El firewall en el equipo remoto debe permitir las conexiones a través del puerto utilizado por WinRM 
 (normalmente, el puerto 5985 para HTTP y 5986 para HTTPS).

 Agregar en el cliente los equipos remotos a los host de confianza. Ejecutar en el PowerShell como Administrador:
 Set-Item WSMan:\localhost\Client\TrustedHosts -Value "10.200.1.*" -Force

 Si hay problema con la conexión habilitar WinRM en el equipo remoto:
 Enable-PSRemoting -Force
 Get-Service WinRM
 Start-Service WinRM
 Restart-Service WinRM
#>
# $TimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById("Cuba Standard Time")
# tzutil /s $TimeZone.Id
Param(
    [string]$accion
)
. .\Funciones.ps1

#region Pedido de datos
    Write-Host " "

    $IPInicial = Read-Host -Prompt "IP inicial "
    $IPFinal = Read-Host -Prompt "IP final "
    Write-Host "Usuario Administrator" 
    $securePasswd = Read-Host -Prompt "Contraseña" -AsSecureString
 
    Write-Host " "
#endregion

#region Preparacion de variables
    #region Comprobación de IP
        $ipRegex = "^(\d{1,3}\.){3}\d{1,3}$"
        if (($IPInicial -match $ipRegex) -and ($IPFinal -match $ipRegex)) {
            # Convertir las direcciones IP en formato de objeto [System.Net.IPAddress]
            $inicio = [System.Net.IPAddress]::Parse($IPInicial)
            $fin = [System.Net.IPAddress]::Parse($IPFinal)
        
            if ($inicio.Address -lt $fin.Address) {
                Write-Host "Validando direcciones IP.....OK"
                Write-Host "Estableciendo conexiones..."
            }
            else {
                Write-Host "ERROR: $IPInicial debe ser menor que $IPFinal"
                Exit
            }
        }
        else {
            Write-Host "ERROR: Una o ambas direcciones IP no son válidas"
            Exit
        }
    #endregion

    $UserName = "Administrator"
    $Credential = New-Object PSCredential -ArgumentList ($UserName, $securePasswd)
    $count = 0;
    # Crear una lista vacía para el listado de zonas horarias
    $listadoZonaHoraria = New-Object System.Collections.Generic.List[string]  
    
    $currentIP = $inicio
#endregion

while ($currentIP.Address -le $fin.Address) {
    try {
        $Session = New-PSSession -ComputerName $currentIP -Credential $Credential

        if ($Session.State -eq 'Opened') {
            
            #region ParteModificable
                $TimeZone = Invoke-Command -Session $Session -ScriptBlock {
                    $TimeZoneInfo = [System.TimeZoneInfo]::Local
                    $TimeZoneInfo.DisplayName
                }
        
                $HostName = Invoke-Command -Session $Session -ScriptBlock {
                    $env:COMPUTERNAME
                }
        
                $resultado = "Zona horaria de $HostName ($($Session.ComputerName)) : $($TimeZone)"
                Write-Host $resultado
        
                # Matriz con los resultados
                $listadoZonaHoraria.Add($resultado)
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

GuardarEnArchivo $listadoZonaHoraria "ListadoZonasHorarias.txt"
Write-Host "Cantidad de hosts chequeados: $count";
