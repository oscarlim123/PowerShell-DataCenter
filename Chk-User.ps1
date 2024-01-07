<# 
.DESCRIPTION
Hace una conexión a un rango de IPs y comprueba la existencia de un usuario
.PARAMETER userName
Nombre de usuario con permisos de administración para hacer la conexión
.PARAMETER findUser
Nombre de usuario que se quiere buscar
.PARAMETER $IPInicial
IP Inicial
.PARAMETER $IPFinal
IP Final
.EXAMPLE
	PS> ./Chk-User.ps1 -u Administrator -findUser Cubilla
.LINK
	https://github.com/oscarlim123/PowerShell-DataCenter
.NOTES
	Author: oscarlim@protonmail.com
#>

param(
    [Parameter(Mandatory=$true, HelpMessage="Nombre de usuario.")]
    [Alias("-u")]
    [ValidateNotNullOrEmpty()]
    [string]$userName,

    [Parameter(Mandatory=$true, HelpMessage="Nombre de usuario que quiere buscar.")]
    [ValidateNotNullOrEmpty()]
    [string]$findUser
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
    # Crear una lista vacía para el listado
    $userExist = New-Object System.Collections.Generic.List[string]     
    $currentIP = $inicio
#endregion

while ($currentIP.Address -le $fin.Address) {
    try {
        $session = New-PSSession -ComputerName $currentIP -Credential $Credential

        if ($session.State -eq 'Opened') {           
            #region ParteModificable
                $newUserToCheck = Invoke-Command -Session $session -ScriptBlock {
                    param($x)
                    net user $x                
                } -ArgumentList $findUser -ErrorAction SilentlyContinue
    
                if ($null -eq $newUserToCheck) {
                    $result = "El usuario $findUser no esta creado en $currentIP."
                    Write-Host $result
                    $userExist.Add($result)
                }              
            #endregion

            Remove-PSSession -Session $session
            $count++;
        } else {
            Write-Host "No se pudo establecer la sesión remota. Estado de la sesión: $($session.State)"
        }
    }
    catch {
        Write-Host "Error al establecer la sesión remota: $_"
    }

    $bytes = $currentIP.GetAddressBytes()
    $bytes[-1]++
    $currentIP = [System.Net.IPAddress]::new($bytes)
}

GuardarEnArchivo $userExist "userExist.txt"
Write-Host "VM comprobadas: $count";