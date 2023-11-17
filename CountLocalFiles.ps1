<# 
.SYNOPSIS
Cuenta el número de archivos con una extensión específica en una ubicación determinada. 
.PARAMETER Location
Ubicación de los archivos
.PARAMETER Extensions
 Matriz de extensiones de archivo.
.DESCRIPTION
El script crea un hashtable llamado $Results para almacenar los resultados del recuento de archivos. 
Luego, utiliza un bucle foreach para recorrer cada extensión en la matriz $Extensions.
El script finalmente devuelve el hashtable $Results
.EXAMPLE
	PS> ./CountLocalFiles.ps1
.LINK
	https://github.com/oscarlim123/PowerShell-DataCenter
.NOTES
	Author: oscarlim@protonmail.com
#>
param(
    [Parameter(Mandatory=$true)]
    [String] $Location,

    [Parameter(Mandatory=$true)]
    [String[]] $Extensions
)

$CmdParams = @{
    Path = $Location
    Filter = "*.*"
    Recurse = $true
    Depth = 1
}

$Results = @{}

foreach ($Extension in $Extensions) {   
        $CurrentExtension = $Extension.ToLower() 

        # Establecer el filtro en la extensión actual
        $CmdParams.Filter = "*.$CurrentExtension" 

        $count = (Get-ChildItem @CmdParams | Measure-Object).Count
       
        if ($count -gt 0) {
            $Results[$Extension] = $count
        }else {
            $Results[$Extension] = 0
        }
}

$Results