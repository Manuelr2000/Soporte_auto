# =============================================================================
#  MODULO: reparacion.ps1
#  Descripcion: Reparacion y solucion de errores del sistema
#  Requiere: Show-Banner, Show-ModuleHeader, Pause-Menu (definidos en soptec.ps1)
# =============================================================================

function Invoke-Reparacion {
    do {
        Show-ModuleHeader "REPARACION Y SOLUCION DE ERRORES" "White"

        Write-Host "   1. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Reparar archivos del sistema  " -ForegroundColor White -NoNewline
        Write-Host "(SFC /scannow)" -ForegroundColor DarkGray

        Write-Host "   2. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Reparar imagen de Windows     " -ForegroundColor Yellow -NoNewline
        Write-Host "(DISM /RestoreHealth)" -ForegroundColor DarkGray

        Write-Host "   3. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Reparar Microsoft Store y apps" -ForegroundColor White

        Write-Host "   4. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Resetear iconos del escritorio" -ForegroundColor Yellow

        Write-Host "   5. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Solucionar problemas de impresoras" -ForegroundColor White

        Write-Host ""
        Show-Separator
        Write-Host ""
        Write-Host "   0. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Volver al Menu Principal" -ForegroundColor Red
        Write-Host ""

        Write-Host "  + Opcion: " -ForegroundColor Cyan -NoNewline
        $op = (Read-Host).Trim()

        switch ($op) {
            "1" { Invoke-SFC             }
            "2" { Invoke-DISM            }
            "3" { Invoke-RepararStore    }
            "4" { Invoke-ResetIconos     }
            "5" { Invoke-RepararImpresoras }
            "0" { break }
            default {
                Write-Host "  Opcion no valida." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($op -ne "0")
}

# -----------------------------------------------------------------------------

function Invoke-SFC {
    Show-ModuleHeader "REPARAR ARCHIVOS DEL SISTEMA - SFC" "White"

    if (-not (Show-AdminWarning)) { return }

    Write-Host "  Este proceso puede tardar varios minutos." -ForegroundColor DarkGray
    Write-Host "  No cierres la ventana hasta que termine." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Iniciando SFC /scannow..." -ForegroundColor Yellow
    Write-Host ""

    & sfc /scannow

    Write-Host ""
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  SFC completado." -ForegroundColor Green
        Write-Host "  Revisa el log en: %WinDir%\Logs\CBS\CBS.log" -ForegroundColor DarkGray
    } else {
        Write-Host "  SFC termino con codigo: $LASTEXITCODE" -ForegroundColor Yellow
    }

    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function Invoke-DISM {
    Show-ModuleHeader "REPARAR IMAGEN DE WINDOWS - DISM" "Yellow"

    if (-not (Show-AdminWarning)) { return }

    Write-Host "  ADVERTENCIA: Este proceso requiere conexion a Internet." -ForegroundColor Yellow
    Write-Host "  Puede tardar entre 10 y 30 minutos." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Pasos que se ejecutaran:" -ForegroundColor DarkGray
    Write-Host "    1. DISM /Online /Cleanup-Image /CheckHealth" -ForegroundColor DarkGray
    Write-Host "    2. DISM /Online /Cleanup-Image /ScanHealth" -ForegroundColor DarkGray
    Write-Host "    3. DISM /Online /Cleanup-Image /RestoreHealth" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Confirmar? " -ForegroundColor White -NoNewline
    Write-Host "[S/N]: " -ForegroundColor Cyan -NoNewline
    $confirm = (Read-Host).Trim().ToUpper()

    if ($confirm -ne "S") {
        Write-Host "  Operacion cancelada." -ForegroundColor DarkGray
        Pause-Menu
        return
    }

    Write-Host ""
    Write-Host "  [1/3] Verificando estado de la imagen..." -ForegroundColor Cyan
    & DISM /Online /Cleanup-Image /CheckHealth
    Write-Host ""

    Write-Host "  [2/3] Escaneando imagen (puede tardar varios minutos)..." -ForegroundColor Cyan
    & DISM /Online /Cleanup-Image /ScanHealth
    Write-Host ""

    Write-Host "  [3/3] Restaurando imagen (requiere Internet)..." -ForegroundColor Cyan
    & DISM /Online /Cleanup-Image /RestoreHealth
    Write-Host ""

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  DISM completado correctamente." -ForegroundColor Green
    } else {
        Write-Host "  DISM termino con codigo: $LASTEXITCODE" -ForegroundColor Yellow
        Write-Host "  Revisa: %WinDir%\Logs\DISM\dism.log" -ForegroundColor DarkGray
    }

    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function Invoke-RepararStore {
    Show-ModuleHeader "REPARAR MICROSOFT STORE Y APPS" "White"

    if (-not (Show-AdminWarning)) { return }

    Write-Host "  Operaciones:" -ForegroundColor DarkGray
    Write-Host "    - Limpiar cache de la Store (wsreset)" -ForegroundColor DarkGray
    Write-Host "    - Re-registrar todas las apps de la Store" -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  [1/2] Limpiando cache de Microsoft Store..." -ForegroundColor Cyan
    Start-Process "wsreset.exe" -Wait -NoNewWindow
    Write-Host "  Cache limpiado." -ForegroundColor Green
    Write-Host ""

    Write-Host "  [2/2] Re-registrando apps universales (puede tardar)..." -ForegroundColor Cyan
    try {
        Get-AppXPackage -AllUsers | ForEach-Object {
            try {
                Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue
            } catch {}
        }
        Write-Host "  Re-registro completado." -ForegroundColor Green
    } catch {
        Write-Host "  Advertencia durante re-registro: $_" -ForegroundColor Yellow
    }

    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function Invoke-ResetIconos {
    Show-ModuleHeader "RESETEAR ICONOS DEL ESCRITORIO" "Yellow"

    Write-Host "  Esta operacion restablece la cache de iconos de Windows." -ForegroundColor DarkGray
    Write-Host "  El explorador se reiniciara brevemente." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Confirmar? " -ForegroundColor White -NoNewline
    Write-Host "[S/N]: " -ForegroundColor Cyan -NoNewline
    $confirm = (Read-Host).Trim().ToUpper()

    if ($confirm -ne "S") {
        Write-Host "  Cancelado." -ForegroundColor DarkGray
        Pause-Menu
        return
    }

    Write-Host ""
    Write-Host "  [1/4] Deteniendo explorador..." -ForegroundColor Cyan
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    Write-Host "  [2/4] Eliminando cache de iconos..." -ForegroundColor Cyan
    $cachePaths = @(
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*.db",
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache*.db"
    )
    foreach ($p in $cachePaths) {
        Remove-Item $p -Force -ErrorAction SilentlyContinue
    }

    Write-Host "  [3/4] Eliminando cache de miniaturas..." -ForegroundColor Cyan
    & ie4uinit.exe -show 2>$null

    Write-Host "  [4/4] Reiniciando explorador..." -ForegroundColor Cyan
    Start-Process explorer.exe
    Start-Sleep -Seconds 2

    Write-Host ""
    Write-Host "  Cache de iconos restablecida." -ForegroundColor Green
    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function Invoke-RepararImpresoras {
    Show-ModuleHeader "SOLUCIONAR PROBLEMAS DE IMPRESORAS" "White"

    Write-Host "  Opciones disponibles:" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   1. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Reiniciar servicio de cola de impresion (Spooler)" -ForegroundColor White
    Write-Host "   2. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Limpiar trabajos de impresion pendientes" -ForegroundColor White
    Write-Host "   3. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Listar impresoras instaladas" -ForegroundColor White
    Write-Host "   0. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Volver" -ForegroundColor Red
    Write-Host ""

    Write-Host "  + Opcion: " -ForegroundColor Cyan -NoNewline
    $sub = (Read-Host).Trim()

    switch ($sub) {
        "1" {
            if (-not (Show-AdminWarning)) { return }
            Write-Host "  Reiniciando Spooler..." -ForegroundColor Cyan
            Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Start-Service -Name Spooler -ErrorAction SilentlyContinue
            $svc = Get-Service -Name Spooler
            Write-Host "  Estado del Spooler: " -ForegroundColor White -NoNewline
            Write-Host $svc.Status -ForegroundColor Green
        }
        "2" {
            if (-not (Show-AdminWarning)) { return }
            Write-Host "  Limpiando cola de impresion..." -ForegroundColor Cyan
            Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue
            Remove-Item "$env:SystemRoot\System32\spool\PRINTERS\*" -Force -Recurse -ErrorAction SilentlyContinue
            Start-Service -Name Spooler -ErrorAction SilentlyContinue
            Write-Host "  Cola limpiada y servicio reiniciado." -ForegroundColor Green
        }
        "3" {
            Write-Host ""
            Write-Host "  Impresoras instaladas:" -ForegroundColor Cyan
            Get-Printer | Format-Table Name, PrinterStatus, DriverName, PortName -AutoSize
        }
    }

    Write-Host ""
    Pause-Menu
}
