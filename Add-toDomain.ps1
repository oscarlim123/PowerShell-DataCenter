<# 
.COMPONENT
    PowerShell 4.0
.DESCRIPTION
    Hace una conexión a un rango de IPs y agrega los WindowsServer 2012 a un dominio. Toma username y passwd de
    un fichero de passwd.txt
.PARAMETER UserName
    Nombre de usuario con permisos de administración para hacer la conexión
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
    # Crear una lista vacía para el listado
    #$userExist = New-Object System.Collections.Generic.List[string]     
    $currentIP = $inicio
    $passwdFile = ".\passwd.txt"
    #$username = Get-Content $passwdFile | Select-Object -First 1
    #$password = Get-Content $passwdFile | Select-Object -Last 1
    $passwd = Get-Content $passwdFile
    $userName = $passwd[0]
    $password = $passwd[1]

    $dom = $userName.Split('\') | Select-Object -First 1

#endregion

while ($currentIP.Address -le $fin.Address) {
    try {
        $session = New-PSSession -ComputerName $currentIP -Credential $Credential

        if ($session.State -eq 'Opened') {           
            #region ParteModificable
                $block1 = {Test-Connection -ComputerName $dom -Count 3}

                $block2 = {
                    $securePassword = ConvertTo-SecureString $using:password -AsPlainText -Force
                    $cred = New-Object System.Management.Automation.PSCredential($using:username,$securePassword)
                    
                    $pcParams = @{
                        ComputerName = $env:COMPUTERNAME
                        DomainName = $dom
                        Credential = $cred
                        Force = $true
                        Restart = $true                   
                    }

                    Add-Computer $pcParams
                    #Add-Computer -ComputerName $env:COMPUTERNAME -DomainName $dom -Credential $cred -Restart -Force
                }

                Invoke-Command -Session $session -ScriptBlock $block1
                Invoke-Command -Session $session -ScriptBlock $block2
                
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

#GuardarEnArchivo $userExist "userExist.txt"
Write-Host "VM comprobadas: $count";

