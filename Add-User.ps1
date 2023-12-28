<# 
.DESCRIPTION
Hace una conexión a un rango de IPs y agrega un nuevo usuario del grupo "Administrators"
.PARAMETER UserName
Nombre de usuario con permisos de administración para hacer la conexión
.PARAMETER newUser
Nombre de usuario que se va a agregar
.PARAMETER passNewuser
Contraseña del nuevo usuario
.PARAMETER $IPInicial
IP Inicial
.PARAMETER $IPFinal
IP Final
.EXAMPLE
	PS> ./Add-User.ps1 -u Administrator -newuser Cubilla -passNewUser qwQ12780Xx
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

    [Parameter(Mandatory=$true, HelpMessage="Nombre de usuario que quiere agregar.")]
    [ValidateNotNullOrEmpty()]
    [string]$newUser,

    [Parameter(Mandatory=$true, HelpMessage="Password del nuevo usuario.")]
    [ValidateNotNullOrEmpty()]
    [string]$passNewuser
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
#endregion

while ($currentIP.Address -le $fin.Address) {
    try {
        $Session = New-PSSession -ComputerName $currentIP -Credential $Credential
        if ($Session.State -eq 'Opened') {           
            #region ParteModificable
            $newusertoadd = Invoke-Command -Session $Session -ScriptBlock {
                param($x, $y) 
                net user $x $y /add /expires:never #/passwordchg:no
                wmic useraccount where "Name='$x'" set PasswordExpires=False
                net localgroup Administrators $x /add
            } -ArgumentList $newUser, $passNewuser
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

Write-Host "Usuario agregado en: $count";