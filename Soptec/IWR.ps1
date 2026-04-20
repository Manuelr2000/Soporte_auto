#Requires -Version 5.1
<#
.SYNOPSIS
    Descarga y ejecuta el instalador correcto de Soptec desde GitHub Releases
    segun la arquitectura del sistema.

.DESCRIPTION
    Detecta la arquitectura del procesador (x64, x86, arm64),
    consulta la ultima release de GitHub, descarga el instalador
    correspondiente y lo ejecuta silenciosamente.

.PARAMETER Version
    Version especifica a descargar (ej: "1.2.3"). Por defecto usa la ultima release.

.PARAMETER DestDir
    Directorio donde se guardara el instalador. Por defecto usa %TEMP%.

.PARAMETER NoCleanup
    Si se especifica, no elimina el instalador despues de ejecutarlo.

.EXAMPLE
    .\IWR.ps1
    .\IWR.ps1 -Version "2.0.0"
    .\IWR.ps1 -DestDir "C:\Instaladores" -NoCleanup
#>
[CmdletBinding()]
param(
    [string] $Version   = "",
    [string] $DestDir   = $env:TEMP,
    [switch] $NoCleanup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# CONFIGURACION  –  ajusta estos valores segun tu repositorio
# ---------------------------------------------------------------------------
$GITHUB_OWNER = "tu-organizacion"        # <-- cambia esto
$GITHUB_REPO  = "soptec"                 # <-- cambia esto

# Patron de nombre de asset por arquitectura.
# Usa {VERSION} como marcador; se sustituye por el numero real de version.
$ASSET_PATTERN = @{
    "x64"   = "soptec-{VERSION}-win-x64.exe"
    "x86"   = "soptec-{VERSION}-win-x86.exe"
    "arm64" = "soptec-{VERSION}-win-arm64.exe"
}

# Argumentos silenciosos del instalador (ajustar segun empaquetador)
$INSTALLER_ARGS = @("/S", "/NORESTART")   # Ejemplo para NSIS/Inno Setup
# ---------------------------------------------------------------------------

function Write-Step {
    param([string]$Message)
    Write-Host "  --> $Message" -ForegroundColor Cyan
}

function Get-SystemArch {
    $arch = $env:PROCESSOR_ARCHITECTURE   # AMD64 | x86 | ARM64
    switch ($arch.ToUpper()) {
        "AMD64" { return "x64"   }
        "X86"   { return "x86"   }
        "ARM64" { return "arm64" }
        default {
            # Fallback: consulta WMI
            $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Architecture
            switch ($cpu) {
                9  { return "x64"   }   # x64
                5  { return "arm64" }   # ARM64
                0  { return "x86"   }   # x86
                default { throw "Arquitectura de CPU no reconocida: $arch (WMI: $cpu)" }
            }
        }
    }
}

function Get-LatestRelease {
    param([string]$Owner, [string]$Repo)
    $apiUrl = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
    Write-Step "Consultando GitHub API: $apiUrl"
    $headers = @{ "User-Agent" = "IWR-Installer/1.0" }
    $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
    return $response
}

function Get-SpecificRelease {
    param([string]$Owner, [string]$Repo, [string]$Tag)
    $tag = if ($Tag.StartsWith("v")) { $Tag } else { "v$Tag" }
    $apiUrl = "https://api.github.com/repos/$Owner/$Repo/releases/tags/$tag"
    Write-Step "Consultando GitHub API: $apiUrl"
    $headers = @{ "User-Agent" = "IWR-Installer/1.0" }
    $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
    return $response
}

function Find-Asset {
    param($Release, [string]$Pattern)
    $tagName    = $Release.tag_name -replace "^v", ""
    $assetName  = $Pattern -replace "\{VERSION\}", $tagName
    $asset      = $Release.assets | Where-Object { $_.name -eq $assetName }
    if (-not $asset) {
        # Intento de busqueda parcial si el nombre exacto no coincide
        $asset = $Release.assets | Where-Object { $_.name -like "*$tagName*" } | Select-Object -First 1
    }
    return $asset, $assetName
}

# ===========================================================================
#  INICIO
# ===========================================================================
Write-Host ""
Write-Host "=================================================" -ForegroundColor Yellow
Write-Host "  Instalador de Soptec" -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Yellow
Write-Host ""

# 1. Detectar arquitectura
Write-Step "Detectando arquitectura del sistema..."
$arch = Get-SystemArch
Write-Host "     Arquitectura: $arch" -ForegroundColor Green

# 2. Obtener informacion de la release
Write-Step "Obteniendo informacion de la release desde GitHub..."
if ($Version -ne "") {
    $release = Get-SpecificRelease -Owner $GITHUB_OWNER -Repo $GITHUB_REPO -Tag $Version
} else {
    $release = Get-LatestRelease -Owner $GITHUB_OWNER -Repo $GITHUB_REPO
}

$releaseVersion = $release.tag_name -replace "^v", ""
Write-Host "     Version encontrada: $releaseVersion" -ForegroundColor Green

# 3. Buscar el asset correcto
if (-not $ASSET_PATTERN.ContainsKey($arch)) {
    throw "No hay patron de asset configurado para la arquitectura '$arch'."
}

$assetResult, $expectedName = Find-Asset -Release $release -Pattern $ASSET_PATTERN[$arch]

if (-not $assetResult) {
    Write-Host ""
    Write-Host "  Assets disponibles en esta release:" -ForegroundColor Yellow
    $release.assets | ForEach-Object { Write-Host "    - $($_.name)" }
    throw "No se encontro el asset '$expectedName' para arquitectura $arch en la release $releaseVersion."
}

$downloadUrl  = $assetResult.browser_download_url
$assetName    = $assetResult.name
$destPath     = Join-Path $DestDir $assetName

Write-Host "     Asset : $assetName" -ForegroundColor Green
Write-Host "     URL   : $downloadUrl" -ForegroundColor Green
Write-Host "     Destino: $destPath" -ForegroundColor Green

# 4. Descargar
Write-Step "Descargando instalador..."
$progressPreferenceBak = $global:ProgressPreference
$global:ProgressPreference = "SilentlyContinue"   # Evita barra de progreso lenta
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $destPath -UseBasicParsing
} finally {
    $global:ProgressPreference = $progressPreferenceBak
}
Write-Host "     Descarga completada." -ForegroundColor Green

# 5. Verificar que el archivo existe y tiene tamano mayor a 0
$fileInfo = Get-Item $destPath
if ($fileInfo.Length -eq 0) {
    throw "El archivo descargado esta vacio: $destPath"
}
Write-Host "     Tamano: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Green

# 6. Ejecutar instalador
Write-Step "Ejecutando instalador..."
Write-Host "     Argumentos: $($INSTALLER_ARGS -join ' ')" -ForegroundColor DarkGray

$proc = Start-Process -FilePath $destPath -ArgumentList $INSTALLER_ARGS -Wait -PassThru

if ($proc.ExitCode -ne 0) {
    Write-Host ""
    Write-Host "  ADVERTENCIA: El instalador termino con codigo $($proc.ExitCode)." -ForegroundColor Yellow
    Write-Host "  Consulta la documentacion del instalador para interpretar este codigo." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "  Instalacion completada correctamente." -ForegroundColor Green
}

# 7. Limpieza
if (-not $NoCleanup) {
    Write-Step "Eliminando archivo temporal..."
    Remove-Item $destPath -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "=================================================" -ForegroundColor Yellow
Write-Host "  Listo." -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Yellow
Write-Host ""

exit $proc.ExitCode
