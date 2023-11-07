
<#---------------------------------------------------------------------
.DESCRIPTION
    Recibe una lista y crea un fichero con su contenido.
    Si ya existe se sobreescribe
.PARAMETER list
    Arreglo de strings que se guardará en el fichero resultante

.PARAMETER rutaArchivo
    Nombre del fichero que se quiere crear

---------------------------------------------------------------------#>
function GuardarEnArchivo([string[]]$list, [string]$rutaArchivo = "Resultados.txt") {    
    $list | Set-Content -Path $rutaArchivo -Force
    Write-Host "Valores guardados en el archivo: $rutaArchivo"
}


<#---------------------------------------------------------------------
.DESCRIPTION 
    Recibe 2 direcciones IP y las valida
.PARAMETER IPInicial
    IP inicial
.PARAMETER IPFinal
    IP final
---------------------------------------------------------------------#>
function CheckIP {
    param (
        [Parameter(Mandatory=$true)]
        [ValidatePattern("^(\d{1,3}\.){3}\d{1,3}$")]
        [string]$IPInicial,

        [Parameter(Mandatory=$true)]
        [ValidatePattern("^(\d{1,3}\.){3}\d{1,3}$")]
        [string]$IPFinal
    )

    try {
        if ($inicio.Address -lt $fin.Address) {
            return $true
        } else {
            return $false
        }
    } catch {
        return $false
    }
}

