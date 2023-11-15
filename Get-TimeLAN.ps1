<# 
.SYNOPSIS
	Hace una conexión a un rango de IPs y toma la zona horaria, la va mostrando y crea un fichero
    con el resultado
.PARAMETER UserName
    Nombre de usuario con permisos de administración para hacer la conexión
.PARAMETER stepIP
    Valor del incremento de las direcciones IP. Valores posibles: 1, 2
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
    [string]$UserName,

    [Parameter(Mandatory=$true, HelpMessage="IValor del incremento de las direcciones IP.")]
    [Alias("-s")]
    [ValidateScript({
        if ($_ -eq 1 -or $_ -eq 2) {
            $true
        } else {
            throw "El valor debe ser 1 o 2."
        }
    })]
    [ValidateNotNullOrEmpty()]
    [int]$stepIP
)

. .\Funciones.ps1

#region Pedido de datos
    $securePasswd = Read-Host -Prompt "Contraseña" -AsSecureString
    $IPInicial = Read-Host -Prompt "IP inicial "
    $IPFinal = Read-Host -Prompt "IP final "
    Write-Host " "
#endregion

#region Preparacion de variables
if (-not $UserName) {
    $UserName = "Administrator"
}
if (-not $stepIP) {
    $stepIP = 1
}
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
    $timexComputadoras = New-Object System.Collections.Generic.List[string]     
    $currentIP = $inicio
#endregion

while ($currentIP.Address -le $fin.Address) {
    try {

        $Session = New-PSSession -ComputerName $currentIP -Credential $Credential

        if ($Session.State -eq 'Opened') {           
            #region ParteModificable
                $time = Invoke-Command -Session $Session -ScriptBlock {Get-Date} -ErrorAction Stop
                $HostName = Invoke-Command -Session $Session -ScriptBlock {$env:COMPUTERNAME}

                $resultado = "Hora en $HostName ($currentIP) : $time"
                Write-Host $resultado
            #endregion

            Remove-PSSession -Session $Session
            $count++;
        } else {
            $resultado = "No se pudo establecer la sesión remota. Estado de la sesión: $($Session.State)"
            Write-Host $resultado
        }
        $timexComputadoras.Add($resultado)
    }
    catch {
        Write-Host "Error al establecer la sesión remota: $_"
    }

    $bytes = $currentIP.GetAddressBytes()

    if($stepIP -eq 1){
        $bytes[-1]++
    }
    elseif ($stepIP -eq 2) {
        $bytes[-1] += 2
    }

    $currentIP = [System.Net.IPAddress]::new($bytes)
}

GuardarEnArchivo $timexComputadoras "ListadoHoras.txt"
Write-Host "Cantidad de hosts chequeados: $count";
