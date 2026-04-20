#Requires -Version 5.1
<#
.SYNOPSIS
    SOPTEC - Herramienta de diagnostico, reparacion y mantenimiento de Windows.
.DESCRIPTION
    Menu principal. Carga todos los modulos por dot-sourcing para compartir sesion.
    Ejecutar con: powershell -ExecutionPolicy Bypass -File soptec.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# ---------------------------------------------------------------------------
#  GLOBALES
# ---------------------------------------------------------------------------
$Global:SOPTEC_ROOT  = $PSScriptRoot
$Global:SOPTEC_LANG  = "ES"   # ES | EN

# ---------------------------------------------------------------------------
#  DOT-SOURCE DE MODULOS  (comparten la misma sesion/scope)
# ---------------------------------------------------------------------------
$modulosRequeridos = @(
    "diagnostico",
    "reparacion",
    "red",
    "limpieza",
    "reporte",
    "software",
    "optimizaciones"
)

foreach ($mod in $modulosRequeridos) {
    $ruta = Join-Path $Global:SOPTEC_ROOT "modules\$mod.ps1"
    if (Test-Path $ruta) {
        . $ruta
    } else {
        Write-Warning "Modulo no encontrado: $ruta"
    }
}

# ---------------------------------------------------------------------------
#  FUNCIONES GLOBALES DE UI  (disponibles para todos los modulos)
# ---------------------------------------------------------------------------
function Show-Banner {
    $host.UI.RawUI.BackgroundColor = "Black"
    Clear-Host

    Write-Host ""
    Write-Host "  ╔═════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║                                 ║" -ForegroundColor DarkCyan
    Write-Host "  ║  " -ForegroundColor DarkCyan -NoNewline
    Write-Host "╔══╗ ╔══╗ ╔══╗ ╔╦╗  ╔══╗ ╔══╗" -ForegroundColor White -NoNewline
    Write-Host "  ║" -ForegroundColor DarkCyan
    Write-Host "  ║  " -ForegroundColor DarkCyan -NoNewline
    Write-Host "╚═╗  ║  ║ ╠══╝  ║   ╠══  ║   " -ForegroundColor White -NoNewline
    Write-Host "  ║" -ForegroundColor DarkCyan
    Write-Host "  ║  " -ForegroundColor DarkCyan -NoNewline
    Write-Host "╚══╝ ╚══╝ ╩     ╩   ╚══╝ ╚══╝" -ForegroundColor White -NoNewline
    Write-Host "  ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                 ║" -ForegroundColor DarkCyan
    Write-Host "  ╚═════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""

    # Barra de subtitulo con fondo cyan
    $titulo = "  SOPTEC TECNICO PRO  -  By Manuel Rodriguez  "
    Write-Host $titulo.PadRight(60) -ForegroundColor Black -BackgroundColor Cyan
    Write-Host ""

    # Leyenda de colores
    Write-Host "  " -NoNewline
    Write-Host "[Blanco: Seguro/Info]" -ForegroundColor White -NoNewline
    Write-Host " | " -ForegroundColor DarkGray -NoNewline
    Write-Host "[Amarillo: Avanzado]" -ForegroundColor Yellow -NoNewline
    Write-Host " | " -ForegroundColor DarkGray -NoNewline
    Write-Host "[Rojo: Borrado/Reset]" -ForegroundColor Red
    Write-Host ""
}

function Show-Separator {
    param([string]$Color = "DarkGray")
    Write-Host ("  " + ("─" * 56)) -ForegroundColor $Color
}

function Show-ModuleHeader {
    param([string]$Titulo, [string]$Color = "Cyan")
    Show-Banner
    Write-Host "  " -NoNewline
    Write-Host "=== $Titulo ===" -ForegroundColor $Color
    Show-Separator
    Write-Host ""
}

function Pause-Menu {
    Write-Host ""
    Write-Host "  Presiona cualquier tecla para continuar..." -ForegroundColor DarkGray
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-AdminWarning {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host ""
        Write-Host "  ADVERTENCIA: " -ForegroundColor Yellow -NoNewline
        Write-Host "Esta funcion requiere permisos de Administrador." -ForegroundColor White
        Write-Host "  Reinicia el script como Administrador para continuar." -ForegroundColor DarkGray
        Pause-Menu
        return $false
    }
    return $true
}

# ---------------------------------------------------------------------------
#  CREDITOS
# ---------------------------------------------------------------------------
function Show-Creditos {
    Show-ModuleHeader "CREDITOS" "Cyan"

    Write-Host "  Herramienta    : " -ForegroundColor DarkGray -NoNewline
    Write-Host "SOPTEC v1.0" -ForegroundColor White

    Write-Host "  Autor          : " -ForegroundColor DarkGray -NoNewline
    Write-Host "Manuel Rodriguez" -ForegroundColor Cyan

    Write-Host "  Descripcion    : " -ForegroundColor DarkGray -NoNewline
    Write-Host "Suite de diagnostico y mantenimiento Windows" -ForegroundColor White

    Write-Host "  Modulos        : " -ForegroundColor DarkGray -NoNewline
    Write-Host "Diagnostico, Reparacion, Redes, Limpieza, Reporte" -ForegroundColor White

    Write-Host "  PowerShell min : " -ForegroundColor DarkGray -NoNewline
    Write-Host "5.1" -ForegroundColor White

    Write-Host ""
    Show-Separator
    Write-Host ""
    Write-Host "  Uso bajo tu propia responsabilidad." -ForegroundColor DarkGray
    Write-Host "  Siempre se recomienda crear un punto de restauracion" -ForegroundColor DarkGray
    Write-Host "  antes de ejecutar operaciones de reparacion." -ForegroundColor DarkGray
    Write-Host ""
    Pause-Menu
}

# ---------------------------------------------------------------------------
#  CAMBIO DE IDIOMA
# ---------------------------------------------------------------------------
function Switch-Idioma {
    if ($Global:SOPTEC_LANG -eq "ES") {
        $Global:SOPTEC_LANG = "EN"
        Write-Host ""
        Write-Host "  Language switched to: " -ForegroundColor DarkGray -NoNewline
        Write-Host "ENGLISH" -ForegroundColor Cyan
        Write-Host "  (Full EN translation coming soon - running in mixed mode)" -ForegroundColor DarkGray
    } else {
        $Global:SOPTEC_LANG = "ES"
        Write-Host ""
        Write-Host "  Idioma cambiado a: " -ForegroundColor DarkGray -NoNewline
        Write-Host "ESPANOL" -ForegroundColor Cyan
    }
    Start-Sleep -Seconds 1
}

# ---------------------------------------------------------------------------
#  MENU PRINCIPAL
# ---------------------------------------------------------------------------
function Show-MainMenu {
    Show-Banner

    Write-Host "  " -NoNewline
    Write-Host "MENU PRINCIPAL" -ForegroundColor White
    Show-Separator
    Write-Host ""

    # Opciones blancas (seguras)
    Write-Host "   1. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Diagnostico e Info de Sistema" -ForegroundColor White

    Write-Host "   2. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Reparacion y Solucion de Errores" -ForegroundColor White

    Write-Host "   3. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Redes y Conectividad" -ForegroundColor White

    Write-Host "   4. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Limpieza y Mantenimiento" -ForegroundColor White

    Write-Host "   5. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Gestor de Software y Arranque" -ForegroundColor White

    Write-Host "   6. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Optimizaciones y Atajos Clasicos" -ForegroundColor White

    Write-Host ""
    Show-Separator
    Write-Host ""

    # Modo automatico (amarillo)
    Write-Host "   A. " -ForegroundColor DarkGray -NoNewline
    Write-Host "MODO AUTOMATICO" -ForegroundColor Yellow -NoNewline
    Write-Host " (limpieza + reparacion completa)" -ForegroundColor DarkGray

    # Opciones cyan
    Write-Host "   L. " -ForegroundColor DarkGray -NoNewline
    Write-Host "CAMBIAR IDIOMA ES/EN" -ForegroundColor Cyan

    Write-Host "   C. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Creditos" -ForegroundColor Cyan

    Write-Host ""
    Show-Separator
    Write-Host ""

    Write-Host "   0. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Salir" -ForegroundColor Red

    Write-Host ""
}

# ---------------------------------------------------------------------------
#  CONFIGURACION DE CONSOLA
# ---------------------------------------------------------------------------
$host.UI.RawUI.WindowTitle      = "SOPTEC"
$host.UI.RawUI.BackgroundColor  = "Black"
$host.UI.RawUI.ForegroundColor  = "White"
Clear-Host

# ---------------------------------------------------------------------------
#  BUCLE PRINCIPAL
# ---------------------------------------------------------------------------
do {
    Show-MainMenu

    Write-Host "  + Opcion: " -ForegroundColor Cyan -NoNewline
    $opcion = (Read-Host).Trim().ToUpper()

    switch ($opcion) {
        "1" { Invoke-Diagnostico }
        "2" { Invoke-Reparacion  }
        "3" { Invoke-Red         }
        "4" { Invoke-Limpieza    }
        "5" { Invoke-GestorSoftware  }
        "6" { Invoke-Optimizaciones  }
        "A" { Invoke-ModoAutomatico  }
        "L" { Switch-Idioma          }
        "C" { Show-Creditos          }
        "0" {
            Show-Banner
            Write-Host "  Saliendo de SOPTEC..." -ForegroundColor DarkGray
            Write-Host ""
            Start-Sleep -Seconds 1
        }
        default {
            Write-Host ""
            Write-Host "  Opcion no valida. Intenta de nuevo." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }

} while ($opcion -ne "0")
