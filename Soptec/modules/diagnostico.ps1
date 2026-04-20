# =============================================================================
#  MODULO: diagnostico.ps1
#  Descripcion: Diagnostico e informacion del sistema
#  Requiere: Show-Banner, Show-ModuleHeader, Pause-Menu (definidos en soptec.ps1)
# =============================================================================

function Invoke-Diagnostico {
    do {
        Show-ModuleHeader "DIAGNOSTICO E INFO DE SISTEMA" "Cyan"

        Write-Host "   1. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Resumen de Sistema  " -ForegroundColor White -NoNewline
        Write-Host "(Hardware, Alerta Disco, Uptime)" -ForegroundColor DarkGray

        Write-Host "   2. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Estado de Licencia Windows " -ForegroundColor White -NoNewline
        Write-Host "(Activacion real)" -ForegroundColor DarkGray

        Write-Host "   3. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Ver Ultimos Pantallazos Azules " -ForegroundColor Yellow -NoNewline
        Write-Host "(BSOD)" -ForegroundColor DarkGray

        Write-Host "   4. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Ver Salud de Discos y Tipo " -ForegroundColor White -NoNewline
        Write-Host "(SSD/HDD)" -ForegroundColor DarkGray

        Write-Host "   5. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Generar Reporte de Bateria " -ForegroundColor White -NoNewline
        Write-Host "(HTML)" -ForegroundColor DarkGray

        Write-Host "   6. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Exportar Inventario de PC " -ForegroundColor White -NoNewline
        Write-Host "(TXT)" -ForegroundColor DarkGray

        Write-Host "   7. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Ver Historial de Auditoria Local " -ForegroundColor Yellow -NoNewline
        Write-Host "(Logs)" -ForegroundColor DarkGray

        Write-Host ""
        Show-Separator
        Write-Host ""
        Write-Host "   0. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Volver al Menu Principal" -ForegroundColor Red
        Write-Host ""

        Write-Host "  + Opcion: " -ForegroundColor Cyan -NoNewline
        $op = (Read-Host).Trim()

        switch ($op) {
            "1" { Get-ResumenSistema      }
            "2" { Get-LicenciaWindows     }
            "3" { Get-HistorialBSOD       }
            "4" { Get-SaludDiscos         }
            "5" { New-ReporteBateria      }
            "6" { Export-InventarioPC     }
            "7" { Get-AuditoriaLocal      }
            "0" { break }
            default {
                Write-Host "  Opcion no valida." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($op -ne "0")
}

# -----------------------------------------------------------------------------

function Get-ResumenSistema {
    Show-ModuleHeader "RESUMEN DE SISTEMA" "White"

    # CPU
    $cpu    = Get-CimInstance Win32_Processor | Select-Object -First 1
    $ram    = Get-CimInstance Win32_ComputerSystem
    $ramGB  = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
    $os     = Get-CimInstance Win32_OperatingSystem
    $uptime = (Get-Date) - $os.LastBootUpTime

    Write-Host "  PROCESADOR" -ForegroundColor Cyan
    Write-Host "    Nombre    : $($cpu.Name.Trim())" -ForegroundColor White
    Write-Host "    Nucleos   : $($cpu.NumberOfCores) fisicos / $($cpu.NumberOfLogicalProcessors) logicos" -ForegroundColor White
    Write-Host "    Velocidad : $($cpu.MaxClockSpeed) MHz" -ForegroundColor White
    Write-Host ""

    Write-Host "  MEMORIA RAM" -ForegroundColor Cyan
    Write-Host "    Total     : $ramGB GB" -ForegroundColor White
    $ramLibre = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    Write-Host "    Libre     : $ramLibre GB" -ForegroundColor White
    Write-Host ""

    Write-Host "  SISTEMA OPERATIVO" -ForegroundColor Cyan
    Write-Host "    Nombre    : $($os.Caption)" -ForegroundColor White
    Write-Host "    Arq.      : $($os.OSArchitecture)" -ForegroundColor White
    Write-Host "    Version   : $($os.Version)" -ForegroundColor White
    Write-Host "    Uptime    : $([int]$uptime.TotalDays) dias, $($uptime.Hours) horas, $($uptime.Minutes) min" -ForegroundColor White
    Write-Host ""

    Write-Host "  DISCOS - ALERTAS" -ForegroundColor Cyan
    $discos = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }
    foreach ($disco in $discos) {
        $totalGB = [math]::Round(($disco.Used + $disco.Free) / 1GB, 1)
        $usadoGB = [math]::Round($disco.Used / 1GB, 1)
        $pctUso  = if ($totalGB -gt 0) { [math]::Round($usadoGB / $totalGB * 100) } else { 0 }
        $color   = if ($pctUso -ge 90) { "Red" } elseif ($pctUso -ge 75) { "Yellow" } else { "Green" }
        Write-Host "    $($disco.Name):  " -ForegroundColor White -NoNewline
        Write-Host "$usadoGB GB / $totalGB GB ($pctUso% usado)" -ForegroundColor $color
    }

    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function Get-LicenciaWindows {
    Show-ModuleHeader "ESTADO DE LICENCIA WINDOWS" "White"

    Write-Host "  Consultando estado de activacion..." -ForegroundColor DarkGray
    Write-Host ""

    try {
        $licencia = Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" |
                    Where-Object { $_.PartialProductKey } |
                    Select-Object -First 1

        if ($licencia) {
            $estadoMap = @{
                0  = "Desbloqueado"
                1  = "Con licencia"
                2  = "Periodo de gracia OOB"
                3  = "Periodo de gracia adicional"
                4  = "Notificacion no genuina"
                5  = "Notificacion"
                6  = "Gracia extendida"
            }
            $estado = $estadoMap[[int]$licencia.LicenseStatus]
            if (-not $estado) { $estado = "Estado desconocido ($($licencia.LicenseStatus))" }

            $color = if ($licencia.LicenseStatus -eq 1) { "Green" } else { "Yellow" }

            Write-Host "  Nombre        : $($licencia.Name)" -ForegroundColor White
            Write-Host "  Clave parcial : $($licencia.PartialProductKey)" -ForegroundColor White
            Write-Host "  Estado        : " -ForegroundColor White -NoNewline
            Write-Host $estado -ForegroundColor $color
            Write-Host "  Canal         : $($licencia.ProductKeyChannel)" -ForegroundColor White
        } else {
            Write-Host "  No se encontro informacion de licencia." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Error al consultar licencia: $_" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  Salida de slmgr /dli:" -ForegroundColor DarkGray
    Write-Host ""
    & cscript //nologo "$env:SystemRoot\System32\slmgr.vbs" /dli 2>&1 | ForEach-Object {
        Write-Host "    $_" -ForegroundColor DarkGray
    }

    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function Get-HistorialBSOD {
    Show-ModuleHeader "HISTORIAL DE PANTALLAZOS AZULES (BSOD)" "Yellow"
    Write-Host "  Buscando eventos criticos en el Visor de Eventos..." -ForegroundColor DarkGray
    Write-Host ""

    try {
        $eventos = Get-WinEvent -FilterHashtable @{
            LogName   = "System"
            Id        = 41, 1001, 6008
            StartTime = (Get-Date).AddDays(-30)
        } -MaxEvents 20 -ErrorAction SilentlyContinue

        if ($eventos -and $eventos.Count -gt 0) {
            Write-Host "  Ultimos $($eventos.Count) eventos criticos (ultimos 30 dias):" -ForegroundColor Yellow
            Write-Host ""
            foreach ($ev in $eventos) {
                Write-Host "  [$($ev.TimeCreated.ToString('yyyy-MM-dd HH:mm'))] " -ForegroundColor DarkGray -NoNewline
                Write-Host "ID $($ev.Id)" -ForegroundColor Yellow -NoNewline
                Write-Host " - $($ev.Message.Split("`n")[0])" -ForegroundColor White
            }
        } else {
            Write-Host "  No se encontraron BSODs en los ultimos 30 dias." -ForegroundColor Green
            Write-Host "  El sistema parece estable." -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "  Error al leer eventos: $_" -ForegroundColor Red
        Write-Host "  Intenta ejecutar como Administrador." -ForegroundColor DarkGray
    }

    Write-Host ""

    # Buscar archivos de volcado de memoria
    $dumpPath = "$env:SystemRoot\Minidump"
    if (Test-Path $dumpPath) {
        $dumps = Get-ChildItem $dumpPath -Filter "*.dmp" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
        if ($dumps) {
            Write-Host "  Archivos de volcado encontrados en $dumpPath :" -ForegroundColor Yellow
            foreach ($d in $dumps) {
                Write-Host "    $($d.Name)  ($($d.LastWriteTime.ToString('yyyy-MM-dd')))" -ForegroundColor White
            }
        }
    }

    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function Get-SaludDiscos {
    Show-ModuleHeader "SALUD DE DISCOS Y TIPO (SSD/HDD)" "White"

    Write-Host "  Consultando discos fisicos..." -ForegroundColor DarkGray
    Write-Host ""

    try {
        $discos = Get-PhysicalDisk

        foreach ($disco in $discos) {
            $colorSalud = switch ($disco.HealthStatus) {
                "Healthy"  { "Green"  }
                "Warning"  { "Yellow" }
                "Unhealthy"{ "Red"    }
                default    { "White"  }
            }

            Write-Host "  DISCO: " -ForegroundColor Cyan -NoNewline
            Write-Host $disco.FriendlyName -ForegroundColor White
            Write-Host "    Numero      : $($disco.DeviceId)" -ForegroundColor DarkGray
            Write-Host "    Tipo        : " -ForegroundColor White -NoNewline
            $tipoColor = if ($disco.MediaType -eq "SSD") { "Cyan" } else { "White" }
            Write-Host $disco.MediaType -ForegroundColor $tipoColor
            Write-Host "    Tamano      : $([math]::Round($disco.Size / 1GB)) GB" -ForegroundColor White
            Write-Host "    Bus         : $($disco.BusType)" -ForegroundColor White
            Write-Host "    Salud       : " -ForegroundColor White -NoNewline
            Write-Host $disco.HealthStatus -ForegroundColor $colorSalud
            Write-Host "    Estado op.  : $($disco.OperationalStatus)" -ForegroundColor White
            Write-Host ""
        }
    } catch {
        Write-Host "  Error al consultar discos: $_" -ForegroundColor Red
    }

    Pause-Menu
}

# -----------------------------------------------------------------------------

function New-ReporteBateria {
    Show-ModuleHeader "REPORTE DE BATERIA" "White"

    $bateria = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if (-not $bateria) {
        Write-Host "  No se detecto bateria en este equipo (PC de escritorio o sin bateria)." -ForegroundColor Yellow
        Write-Host ""
        Pause-Menu
        return
    }

    Write-Host "  Generando reporte HTML con powercfg..." -ForegroundColor DarkGray

    if (-not (Show-AdminWarning)) { return }

    $ruta = "$env:USERPROFILE\Desktop\BateriaReport_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
    & powercfg /batteryreport /output "$ruta" | Out-Null

    if (Test-Path $ruta) {
        Write-Host "  Reporte generado: " -ForegroundColor Green -NoNewline
        Write-Host $ruta -ForegroundColor White
        Write-Host ""
        Write-Host "  Abriendo reporte en el navegador..." -ForegroundColor DarkGray
        Start-Process $ruta
    } else {
        Write-Host "  No se pudo generar el reporte. Ejecuta como Administrador." -ForegroundColor Red
    }

    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function Export-InventarioPC {
    Show-ModuleHeader "EXPORTAR INVENTARIO DE PC" "White"

    $ruta = "$env:USERPROFILE\Desktop\Inventario_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"
    Write-Host "  Recopilando informacion del sistema..." -ForegroundColor DarkGray

    $sb = [System.Text.StringBuilder]::new()

    $fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $null = $sb.AppendLine("=" * 60)
    $null = $sb.AppendLine("  INVENTARIO DE PC - SOPTEC AUTO")
    $null = $sb.AppendLine("  Generado: $fecha")
    $null = $sb.AppendLine("=" * 60)

    # Sistema
    $os  = Get-CimInstance Win32_OperatingSystem
    $cs  = Get-CimInstance Win32_ComputerSystem
    $null = $sb.AppendLine("`n[ SISTEMA OPERATIVO ]")
    $null = $sb.AppendLine("  OS         : $($os.Caption) $($os.OSArchitecture)")
    $null = $sb.AppendLine("  Version    : $($os.Version)")
    $null = $sb.AppendLine("  Equipo     : $($cs.Name)")
    $null = $sb.AppendLine("  Dominio    : $($cs.Domain)")
    $null = $sb.AppendLine("  Usuario    : $($cs.UserName)")

    # CPU
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $null = $sb.AppendLine("`n[ PROCESADOR ]")
    $null = $sb.AppendLine("  Nombre     : $($cpu.Name.Trim())")
    $null = $sb.AppendLine("  Nucleos    : $($cpu.NumberOfCores) fisicos / $($cpu.NumberOfLogicalProcessors) logicos")
    $null = $sb.AppendLine("  Velocidad  : $($cpu.MaxClockSpeed) MHz")

    # RAM
    $ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    $null = $sb.AppendLine("`n[ MEMORIA RAM ]")
    $null = $sb.AppendLine("  Total      : $ramGB GB")

    # Modulos de RAM
    $ramMods = Get-CimInstance Win32_PhysicalMemory
    foreach ($mod in $ramMods) {
        $modGB = [math]::Round($mod.Capacity / 1GB, 1)
        $null = $sb.AppendLine("  Modulo     : $modGB GB - $($mod.Manufacturer) - $($mod.Speed) MHz - Slot: $($mod.DeviceLocator)")
    }

    # Discos
    $null = $sb.AppendLine("`n[ DISCOS FISICOS ]")
    $discos = Get-PhysicalDisk
    foreach ($d in $discos) {
        $null = $sb.AppendLine("  $($d.FriendlyName) | $($d.MediaType) | $([math]::Round($d.Size/1GB)) GB | Salud: $($d.HealthStatus)")
    }

    # Tarjeta de video
    $gpu = Get-CimInstance Win32_VideoController
    $null = $sb.AppendLine("`n[ TARJETA DE VIDEO ]")
    foreach ($g in $gpu) {
        $vramMB = [math]::Round($g.AdapterRAM / 1MB)
        $null = $sb.AppendLine("  $($g.Name) | VRAM: $vramMB MB | Driver: $($g.DriverVersion)")
    }

    # Red
    $null = $sb.AppendLine("`n[ ADAPTADORES DE RED ]")
    $nics = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }
    foreach ($nic in $nics) {
        $null = $sb.AppendLine("  $($nic.Description)")
        $null = $sb.AppendLine("    IP: $($nic.IPAddress -join ', ')")
        $null = $sb.AppendLine("    MAC: $($nic.MACAddress)")
    }

    $null = $sb.AppendLine("`n" + "=" * 60)
    $null = $sb.AppendLine("  FIN DEL REPORTE - SOPTEC AUTO")
    $null = $sb.AppendLine("=" * 60)

    $sb.ToString() | Out-File -FilePath $ruta -Encoding UTF8

    Write-Host ""
    Write-Host "  Inventario exportado a: " -ForegroundColor Green -NoNewline
    Write-Host $ruta -ForegroundColor White
    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function Get-AuditoriaLocal {
    Show-ModuleHeader "HISTORIAL DE AUDITORIA LOCAL" "Yellow"

    if (-not (Show-AdminWarning)) { return }

    Write-Host "  Consultando eventos de seguridad (ultimos 50)..." -ForegroundColor DarkGray
    Write-Host ""

    try {
        $eventos = Get-WinEvent -LogName Security -MaxEvents 50 -ErrorAction Stop |
                   Select-Object TimeCreated, Id, Message

        $tiposImportantes = @{
            4624 = "Inicio de sesion exitoso"
            4625 = "Inicio de sesion FALLIDO"
            4634 = "Cierre de sesion"
            4648 = "Inicio de sesion con credenciales explicitas"
            4720 = "Cuenta de usuario creada"
            4726 = "Cuenta de usuario eliminada"
            4740 = "Cuenta BLOQUEADA"
        }

        $filtrados = $eventos | Where-Object { $tiposImportantes.ContainsKey($_.Id) }

        if ($filtrados) {
            foreach ($ev in $filtrados | Select-Object -First 20) {
                $desc  = $tiposImportantes[$ev.Id]
                $color = if ($ev.Id -in 4625, 4740) { "Red" } elseif ($ev.Id -in 4720, 4726) { "Yellow" } else { "White" }
                Write-Host "  [$($ev.TimeCreated.ToString('MM-dd HH:mm'))] " -ForegroundColor DarkGray -NoNewline
                Write-Host "[$($ev.Id)] " -ForegroundColor DarkGray -NoNewline
                Write-Host $desc -ForegroundColor $color
            }
        } else {
            Write-Host "  No se encontraron eventos de auditoria relevantes." -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "  No se puede acceder al log de Seguridad." -ForegroundColor Red
        Write-Host "  Requiere permisos de Administrador." -ForegroundColor DarkGray
    }

    Write-Host ""
    Pause-Menu
}
