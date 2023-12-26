<# 
.DESCRIPTION
Hace una conexión a un rango de IPs y agrega el usuario "Cubilla" y lo agrega al grupo "Administrators"
.PARAMETER UserName
Nombre de usuario con permisos de administración para hacer la conexión
.PARAMETER $IPInicial
IP Inicial
.PARAMETER $IPFinal
IP Final
.EXAMPLE
	PS> ./Add-User.ps1 -u Administrator
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
    # Crear una lista vacía para el listado
    #$usersCD = New-Object System.Collections.Generic.List[string]     
    $currentIP = $inicio
#endregion

while ($currentIP.Address -le $fin.Address) {
    try {
        $Session = New-PSSession -ComputerName $currentIP -Credential $Credential

        if ($Session.State -eq 'Opened') {           
            #region ParteModificable
            $newuser = Invoke-Command -Session $Session -ScriptBlock {
                #net user Cubilla 1234qwer* /add /expires:never /passwordchg:no
                net user Cubilla 1234qwer* /add /expires:never
                wmic useraccount where "Name='Cubilla'" set PasswordExpires=False
                net localgroup Administrators Cubilla /add
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

#GuardarEnArchivo $usersCD "usersCD.txt"
Write-Host "Usurio agregado en: $count";