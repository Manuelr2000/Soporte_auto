# =============================================================================
#  MODULO: limpieza.ps1
#  Descripcion: Limpieza, mantenimiento y MODO AUTOMATICO completo
#  Requiere: Show-Banner, Show-ModuleHeader, Pause-Menu (definidos en soptec.ps1)
# =============================================================================

function Invoke-Limpieza {
    do {
        Show-ModuleHeader "LIMPIEZA Y MANTENIMIENTO" "White"

        Write-Host "   1. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Limpiar archivos temporales           " -ForegroundColor White -NoNewline
        Write-Host "(Temp, Cache, Prefetch)" -ForegroundColor DarkGray

        Write-Host "   2. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Vaciar Papelera de Reciclaje          " -ForegroundColor White

        Write-Host "   3. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Optimizar discos SSD                  " -ForegroundColor Yellow -NoNewline
        Write-Host "(TRIM)" -ForegroundColor DarkGray

        Write-Host "   4. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Crear Punto de Restauracion           " -ForegroundColor White

        Write-Host "   5. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Limpiar logs del sistema              " -ForegroundColor Yellow

        Write-Host ""
        Show-Separator
        Write-Host ""
        Write-Host "   0. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Volver al Menu Principal" -ForegroundColor Red
        Write-Host ""

        Write-Host "  + Opcion: " -ForegroundColor Cyan -NoNewline
        $op = (Read-Host).Trim()

        switch ($op) {
            "1" { Invoke-LimpiarTemporales    }
            "2" { Invoke-VaciarPapelera       }
            "3" { Invoke-TRIM                 }
            "4" { New-PuntoRestauracion       }
            "5" { Invoke-LimpiarLogs          }
            "0" { break }
            default {
                Write-Host "  Opcion no valida." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($op -ne "0")
}

# =============================================================================
#  MODO AUTOMATICO (llamado desde menu principal con opcion A)
# =============================================================================

function Invoke-ModoAutomatico {
    Show-ModuleHeader "MODO AUTOMATICO - LIMPIEZA Y REPARACION COMPLETA" "Yellow"

    # --- ADVERTENCIA PREVIA ---
    Write-Host "  Este modo realizara automaticamente las siguientes operaciones:" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "  " -NoNewline
    Write-Host "[PASO 0]" -ForegroundColor Cyan -NoNewline
    Write-Host " RESPALDO     " -ForegroundColor White -NoNewline
    Write-Host "Crear Punto de Restauracion automatico" -ForegroundColor DarkGray

    Write-Host "  " -NoNewline
    Write-Host "[PASO 1]" -ForegroundColor White -NoNewline
    Write-Host " ELIMINACION  " -ForegroundColor White -NoNewline
    Write-Host "Archivos Temporales, Cache, Prefetch y Papelera" -ForegroundColor DarkGray

    Write-Host "  " -NoNewline
    Write-Host "[PASO 2]" -ForegroundColor Yellow -NoNewline
    Write-Host " OPTIMIZACION " -ForegroundColor White -NoNewline
    Write-Host "Ejecutar TRIM en discos solidos (SSD)" -ForegroundColor DarkGray

    Write-Host "  " -NoNewline
    Write-Host "[PASO 3]" -ForegroundColor Yellow -NoNewline
    Write-Host " REPARACION   " -ForegroundColor White -NoNewline
    Write-Host "Escaneo SFC y DISM (Requiere Internet)" -ForegroundColor DarkGray

    Write-Host "  " -NoNewline
    Write-Host "[PASO 4]" -ForegroundColor Red -NoNewline
    Write-Host " REDES        " -ForegroundColor White -NoNewline
    Write-Host "Reset de IP, DNS y Winsock" -ForegroundColor DarkGray

    Write-Host ""
    Show-Separator
    Write-Host ""

    Write-Host "  Requiere permisos de " -ForegroundColor DarkGray -NoNewline
    Write-Host "Administrador" -ForegroundColor Yellow -NoNewline
    Write-Host " e " -ForegroundColor DarkGray -NoNewline
    Write-Host "Internet" -ForegroundColor Yellow -NoNewline
    Write-Host " para los pasos 3 y 4." -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "   1. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Ejecutar y Volver al Menu" -ForegroundColor Green

    Write-Host "   2. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Ejecutar y CERRAR Soptec" -ForegroundColor Red

    Write-Host "   0. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Volver sin ejecutar" -ForegroundColor DarkGray

    Write-Host ""
    Write-Host "  + Opcion: " -ForegroundColor Cyan -NoNewline
    $eleccion = (Read-Host).Trim()

    if ($eleccion -notin @("1","2")) {
        Write-Host ""
        Write-Host "  Modo Automatico cancelado." -ForegroundColor DarkGray
        Start-Sleep -Seconds 1
        return
    }

    if (-not (Show-AdminWarning)) { return }

    # --- EJECUCION PASO A PASO ---
    Show-ModuleHeader "MODO AUTOMATICO - EJECUTANDO" "Yellow"

    $errores = @()

    # -------------------------------------------------------------------------
    # PASO 0: PUNTO DE RESTAURACION
    # -------------------------------------------------------------------------
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║  PASO 0 / 4  -  PUNTO DE RESTAURACION       ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "  Creando punto de restauracion..." -ForegroundColor DarkGray
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "SOPTEC AUTO - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" `
                            -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "  Punto de restauracion creado." -ForegroundColor Green
    } catch {
        $msg = "Punto de restauracion: $_"
        $errores += $msg
        Write-Host "  Advertencia: No se pudo crear el punto de restauracion." -ForegroundColor Yellow
        Write-Host "  $_" -ForegroundColor DarkGray
    }

    Start-Sleep -Seconds 1

    # -------------------------------------------------------------------------
    # PASO 1: LIMPIEZA DE TEMPORALES, CACHE, PREFETCH Y PAPELERA
    # -------------------------------------------------------------------------
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor White
    Write-Host "  ║  PASO 1 / 4  -  ELIMINACION DE TEMPORALES   ║" -ForegroundColor White
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor White
    Write-Host ""

    $rutasLimpiar = @(
        @{ Desc = "Temp del sistema";  Ruta = $env:SystemRoot + "\Temp\*" },
        @{ Desc = "Temp del usuario";  Ruta = $env:TEMP + "\*" },
        @{ Desc = "Cache IE/Edge";     Ruta = $env:LOCALAPPDATA + "\Microsoft\Windows\INetCache\*" },
        @{ Desc = "Prefetch";          Ruta = $env:SystemRoot + "\Prefetch\*" },
        @{ Desc = "Logs de Windows";   Ruta = $env:SystemRoot + "\Logs\*" },
        @{ Desc = "Minidumps";         Ruta = $env:SystemRoot + "\Minidump\*" },
        @{ Desc = "Thumbnails cache";  Ruta = $env:LOCALAPPDATA + "\Microsoft\Windows\Explorer\thumbcache_*.db" }
    )

    $totalLiberado = 0

    foreach ($entrada in $rutasLimpiar) {
        Write-Host "  Limpiando: " -ForegroundColor DarkGray -NoNewline
        Write-Host $entrada.Desc -ForegroundColor White -NoNewline
        Write-Host "..." -ForegroundColor DarkGray

        try {
            $items = Get-ChildItem -Path $entrada.Ruta -Force -Recurse -ErrorAction SilentlyContinue
            $tamano = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            $totalLiberado += [int64]$tamano
            Remove-Item -Path $entrada.Ruta -Force -Recurse -ErrorAction SilentlyContinue
            $mb = [math]::Round([int64]$tamano / 1MB, 1)
            Write-Host "    Liberado: $mb MB" -ForegroundColor Green
        } catch {
            Write-Host "    (saltado)" -ForegroundColor DarkGray
        }
    }

    # Vaciar Papelera
    Write-Host "  Vaciando Papelera de Reciclaje..." -ForegroundColor DarkGray
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Host "    Papelera vaciada." -ForegroundColor Green
    } catch {
        Write-Host "    (saltado)" -ForegroundColor DarkGray
    }

    $totalMB = [math]::Round($totalLiberado / 1MB, 1)
    Write-Host ""
    Write-Host "  Total liberado en este paso: " -ForegroundColor White -NoNewline
    Write-Host "$totalMB MB" -ForegroundColor Green

    Start-Sleep -Seconds 1

    # -------------------------------------------------------------------------
    # PASO 2: TRIM EN SSD
    # -------------------------------------------------------------------------
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║  PASO 2 / 4  -  OPTIMIZACION SSD (TRIM)     ║" -ForegroundColor Yellow
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""

    try {
        $discos = Get-PhysicalDisk | Where-Object { $_.MediaType -eq "SSD" }
        if ($discos) {
            foreach ($disco in $discos) {
                Write-Host "  Aplicando TRIM a: " -ForegroundColor DarkGray -NoNewline
                Write-Host $disco.FriendlyName -ForegroundColor White
            }
            & Optimize-Volume -DriveType SSD -ReTrim -ErrorAction SilentlyContinue
            Write-Host "  TRIM completado en todos los SSD." -ForegroundColor Green
        } else {
            Write-Host "  No se detectaron discos SSD. Paso omitido." -ForegroundColor DarkGray
        }
    } catch {
        $errores += "TRIM: $_"
        Write-Host "  Error al ejecutar TRIM: $_" -ForegroundColor Yellow
    }

    Start-Sleep -Seconds 1

    # -------------------------------------------------------------------------
    # PASO 3: SFC + DISM
    # -------------------------------------------------------------------------
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║  PASO 3 / 4  -  REPARACION SFC + DISM       ║" -ForegroundColor Yellow
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "  [3a] Ejecutando SFC /scannow (puede tardar varios minutos)..." -ForegroundColor Cyan
    Write-Host ""
    try {
        & sfc /scannow
        Write-Host ""
        Write-Host "  SFC completado." -ForegroundColor Green
    } catch {
        $errores += "SFC: $_"
        Write-Host "  Error en SFC: $_" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  [3b] Ejecutando DISM /RestoreHealth (requiere Internet)..." -ForegroundColor Cyan
    Write-Host ""
    try {
        & DISM /Online /Cleanup-Image /RestoreHealth
        Write-Host ""
        Write-Host "  DISM completado." -ForegroundColor Green
    } catch {
        $errores += "DISM: $_"
        Write-Host "  Error en DISM: $_" -ForegroundColor Yellow
    }

    Start-Sleep -Seconds 1

    # -------------------------------------------------------------------------
    # PASO 4: RESET DE REDES
    # -------------------------------------------------------------------------
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "  ║  PASO 4 / 4  -  RESET DE REDES              ║" -ForegroundColor Red
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""

    Write-Host "  Reseteando IP..." -ForegroundColor DarkGray
    & ipconfig /release 2>&1 | Out-Null
    & ipconfig /renew   2>&1 | Out-Null
    Write-Host "  IP renovada." -ForegroundColor Green

    Write-Host "  Limpiando cache DNS..." -ForegroundColor DarkGray
    & ipconfig /flushdns 2>&1 | Out-Null
    Write-Host "  DNS limpiado." -ForegroundColor Green

    Write-Host "  Reseteando Winsock..." -ForegroundColor DarkGray
    & netsh winsock reset 2>&1 | Out-Null
    Write-Host "  Winsock restablecido." -ForegroundColor Green

    Start-Sleep -Seconds 1

    # -------------------------------------------------------------------------
    # RESUMEN FINAL
    # -------------------------------------------------------------------------
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║          MODO AUTOMATICO FINALIZADO          ║" -ForegroundColor Green
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""

    Write-Host "  Pasos completados: 0, 1, 2, 3, 4" -ForegroundColor Green

    if ($errores.Count -gt 0) {
        Write-Host ""
        Write-Host "  Advertencias durante la ejecucion:" -ForegroundColor Yellow
        foreach ($e in $errores) {
            Write-Host "    - $e" -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    Write-Host "  Se recomienda REINICIAR el equipo para aplicar todos los cambios." -ForegroundColor Yellow
    Write-Host ""

    if ($eleccion -eq "2") {
        Write-Host "  Cerrando SOPTEC AUTO..." -ForegroundColor Red
        Start-Sleep -Seconds 2
        exit 0
    }

    Pause-Menu
}

# =============================================================================
#  FUNCIONES INDIVIDUALES DE LIMPIEZA
# =============================================================================

function Invoke-LimpiarTemporales {
    Show-ModuleHeader "LIMPIAR ARCHIVOS TEMPORALES" "White"

    $rutasLimpiar = @(
        @{ Desc = "Temp del sistema";  Ruta = $env:SystemRoot + "\Temp\*" },
        @{ Desc = "Temp del usuario";  Ruta = $env:TEMP + "\*" },
        @{ Desc = "Cache IE/Edge";     Ruta = $env:LOCALAPPDATA + "\Microsoft\Windows\INetCache\*" },
        @{ Desc = "Prefetch";          Ruta = $env:SystemRoot + "\Prefetch\*" },
        @{ Desc = "Thumbnails cache";  Ruta = $env:LOCALAPPDATA + "\Microsoft\Windows\Explorer\thumbcache_*.db" }
    )

    $totalLiberado = 0

    foreach ($entrada in $rutasLimpiar) {
        Write-Host "  Limpiando " -ForegroundColor DarkGray -NoNewline
        Write-Host $entrada.Desc -ForegroundColor White -NoNewline
        Write-Host "..." -ForegroundColor DarkGray

        $items  = Get-ChildItem -Path $entrada.Ruta -Force -Recurse -ErrorAction SilentlyContinue
        $tamano = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        $totalLiberado += [int64]$tamano
        Remove-Item -Path $entrada.Ruta -Force -Recurse -ErrorAction SilentlyContinue
        $mb = [math]::Round([int64]$tamano / 1MB, 1)
        Write-Host "    Liberado: $mb MB" -ForegroundColor Green
    }

    $totalMB = [math]::Round($totalLiberado / 1MB, 1)
    Write-Host ""
    Write-Host "  Total liberado: " -ForegroundColor White -NoNewline
    Write-Host "$totalMB MB" -ForegroundColor Green
    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function Invoke-VaciarPapelera {
    Show-ModuleHeader "VACIAR PAPELERA DE RECICLAJE" "White"

    Write-Host "  Vaciando Papelera de todos los usuarios..." -ForegroundColor DarkGray
    try {
        Clear-RecycleBin -Force -ErrorAction Stop
        Write-Host "  Papelera vaciada correctamente." -ForegroundColor Green
    } catch {
        Write-Host "  Error: $_" -ForegroundColor Red
    }

    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function Invoke-TRIM {
    Show-ModuleHeader "OPTIMIZAR SSD CON TRIM" "Yellow"

    if (-not (Show-AdminWarning)) { return }

    $ssds = Get-PhysicalDisk | Where-Object { $_.MediaType -eq "SSD" }
    if (-not $ssds) {
        Write-Host "  No se detectaron discos SSD en este equipo." -ForegroundColor Yellow
        Write-Host ""
        Pause-Menu
        return
    }

    Write-Host "  Discos SSD detectados:" -ForegroundColor Cyan
    foreach ($s in $ssds) {
        Write-Host "    - $($s.FriendlyName) [$([math]::Round($s.Size/1GB)) GB]" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "  Ejecutando TRIM..." -ForegroundColor DarkGray

    try {
        Get-Volume | Where-Object { $_.DriveType -eq "Fixed" } | ForEach-Object {
            Optimize-Volume -DriveLetter $_.DriveLetter -ReTrim -Verbose -ErrorAction SilentlyContinue
        }
        Write-Host "  TRIM completado." -ForegroundColor Green
    } catch {
        Write-Host "  Error al ejecutar TRIM: $_" -ForegroundColor Red
    }

    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function New-PuntoRestauracion {
    Show-ModuleHeader "CREAR PUNTO DE RESTAURACION" "White"

    if (-not (Show-AdminWarning)) { return }

    $descripcion = "SOPTEC AUTO - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    Write-Host "  Creando punto de restauracion..." -ForegroundColor DarkGray
    Write-Host "  Descripcion: $descripcion" -ForegroundColor DarkGray
    Write-Host ""

    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description $descripcion -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "  Punto de restauracion creado correctamente." -ForegroundColor Green
    } catch {
        Write-Host "  Error: $_" -ForegroundColor Red
        Write-Host "  Asegurate de que la Restauracion del Sistema este habilitada en C:" -ForegroundColor DarkGray
    }

    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function Invoke-LimpiarLogs {
    Show-ModuleHeader "LIMPIAR LOGS DEL SISTEMA" "Yellow"

    if (-not (Show-AdminWarning)) { return }

    Write-Host "  Esta operacion limpiara los registros de eventos de Windows." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Confirmar? " -ForegroundColor White -NoNewline
    Write-Host "[S/N]: " -ForegroundColor Cyan -NoNewline
    $confirm = (Read-Host).Trim().ToUpper()

    if ($confirm -ne "S") {
        Write-Host "  Cancelado." -ForegroundColor DarkGray
        Pause-Menu
        return
    }

    $logsLimpiar = @("Application", "System", "Security", "Setup")

    foreach ($log in $logsLimpiar) {
        Write-Host "  Limpiando log: " -ForegroundColor DarkGray -NoNewline
        Write-Host $log -ForegroundColor White -NoNewline
        Write-Host "..." -ForegroundColor DarkGray
        try {
            & wevtutil cl $log 2>&1 | Out-Null
            Write-Host "    Limpiado." -ForegroundColor Green
        } catch {
            Write-Host "    (error: $_)" -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    Write-Host "  Logs del sistema limpiados." -ForegroundColor Green
    Write-Host ""
    Pause-Menu
}
