<# 
.DESCRIPTION
Hace una conexión a un rango de IPs y agrega a la red "Ethernet 2" el DNS primario y secundario
.PARAMETER UserName
Nombre de usuario con permisos de administración para hacer la conexión
.PARAMETER securePasswd
Contraseña del usuario
.PARAMETER $IPInicial
IP Inicial
.PARAMETER $IPFinal
IP Final
.EXAMPLE
	PS> ./Add-DNS.ps1 -u Administrator
.LINK
	https://github.com/oscarlim123/PowerShell-DataCenter
.NOTES
	Author: oscarlim@protonmail.com
#>

param(
    [Parameter(Mandatory=$true, HelpMessage="Nombre de usuario.")]
    [Alias("-u")]
    [ValidateNotNullOrEmpty()]
    [string]$userName
)

. .\Funciones.ps1

#region Pedido de datos
    $securePasswd = Read-Host -Prompt "Contraseña de Login" -AsSecureString
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

    $Credential = New-Object PSCredential -ArgumentList ($userName, $securePasswd)
    $count = 0;  
    $currentIP = $inicio
    $dnsPrimario = "10.200.1.5"
    $dnsSecundario = "10.200.1.6"
#endregion

while ($currentIP.Address -le $fin.Address) {
    try {
        $session = New-PSSession -ComputerName $currentIP -Credential $Credential

        if ($session.State -eq 'Opened') {           
            #region ParteModificable
                $scriptConfiguracion = {
                    param($dnsPrimario, $dnsSecundario)
                    Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses @($dnsPrimario, $dnsSecundario)
                }

                Invoke-Command -Session $session -ScriptBlock $scriptConfiguracion -ArgumentList $dnsPrimario, $dnsSecundario
                Write-Host "$currentIP"
            #endregion

            Remove-PSSession -Session $session
            $count++;
        } else {
            Write-Host "No se pudo establecer la sesión remota en $currentIP. Estado de la sesión: $($session.State)"
        }
    }
    catch {
        Write-Host "Error al establecer la sesión remota: $_"
    }

    $bytes = $currentIP.GetAddressBytes()
    $bytes[-1]++
    $currentIP = [System.Net.IPAddress]::new($bytes)
}

Write-Host "VM comprobadas: $count";

