# =============================================================================
#  MODULO: reporte.ps1
#  Descripcion: Generacion de reportes del sistema
#  Requiere: Show-Banner, Show-ModuleHeader, Pause-Menu (definidos en soptec.ps1)
# =============================================================================

function Invoke-Reporte {
    do {
        Show-ModuleHeader "REPORTES DEL SISTEMA" "Cyan"

        Write-Host "   1. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Reporte completo del sistema     " -ForegroundColor White -NoNewline
        Write-Host "(TXT)" -ForegroundColor DarkGray

        Write-Host "   2. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Reporte de rendimiento           " -ForegroundColor White -NoNewline
        Write-Host "(CPU, RAM, Disco)" -ForegroundColor DarkGray

        Write-Host "   3. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Reporte de red                   " -ForegroundColor White -NoNewline
        Write-Host "(adaptadores, IPs, rutas)" -ForegroundColor DarkGray

        Write-Host "   4. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Reporte de software instalado    " -ForegroundColor White -NoNewline
        Write-Host "(TXT)" -ForegroundColor DarkGray

        Write-Host "   5. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Reporte de seguridad             " -ForegroundColor Yellow -NoNewline
        Write-Host "(firewall, antivirus, actualizaciones)" -ForegroundColor DarkGray

        Write-Host ""
        Show-Separator
        Write-Host ""
        Write-Host "   0. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Volver al Menu Principal" -ForegroundColor Red
        Write-Host ""

        Write-Host "  + Opcion: " -ForegroundColor Cyan -NoNewline
        $op = (Read-Host).Trim()

        switch ($op) {
            "1" { New-ReporteCompleto       }
            "2" { New-ReporteRendimiento    }
            "3" { New-ReporteRed            }
            "4" { New-ReporteSoftware       }
            "5" { New-ReporteSeguridad      }
            "0" { break }
            default {
                Write-Host "  Opcion no valida." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($op -ne "0")
}

# -----------------------------------------------------------------------------

function New-ReporteCompleto {
    Show-ModuleHeader "REPORTE COMPLETO DEL SISTEMA" "White"

    $ruta = "$env:USERPROFILE\Desktop\Reporte_Completo_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"
    Write-Host "  Recopilando todos los datos del sistema..." -ForegroundColor DarkGray

    $sb = [System.Text.StringBuilder]::new()

    $null = $sb.AppendLine("=" * 70)
    $null = $sb.AppendLine("   REPORTE COMPLETO - SOPTEC AUTO v1.0")
    $null = $sb.AppendLine("   Generado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $null = $sb.AppendLine("=" * 70)

    # Sistema operativo
    Write-Host "  Recopilando: SO..." -ForegroundColor DarkGray
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $null = $sb.AppendLine("`n[ SISTEMA OPERATIVO ]")
    $null = $sb.AppendLine("  OS         : $($os.Caption) $($os.OSArchitecture)")
    $null = $sb.AppendLine("  Build      : $($os.BuildNumber)")
    $null = $sb.AppendLine("  Version    : $($os.Version)")
    $null = $sb.AppendLine("  Equipo     : $($cs.Name)")
    $null = $sb.AppendLine("  Fabricante : $($cs.Manufacturer)")
    $null = $sb.AppendLine("  Modelo     : $($cs.Model)")
    $uptime = (Get-Date) - $os.LastBootUpTime
    $null = $sb.AppendLine("  Uptime     : $([int]$uptime.TotalDays)d $($uptime.Hours)h $($uptime.Minutes)m")

    # CPU
    Write-Host "  Recopilando: CPU..." -ForegroundColor DarkGray
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $null = $sb.AppendLine("`n[ PROCESADOR ]")
    $null = $sb.AppendLine("  Nombre     : $($cpu.Name.Trim())")
    $null = $sb.AppendLine("  Nucleos    : $($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors) logicos")
    $null = $sb.AppendLine("  Velocidad  : $($cpu.MaxClockSpeed) MHz")
    $null = $sb.AppendLine("  Arquitectura: $($cpu.AddressWidth)-bit")

    # RAM
    Write-Host "  Recopilando: RAM..." -ForegroundColor DarkGray
    $ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    $null = $sb.AppendLine("`n[ MEMORIA ]")
    $null = $sb.AppendLine("  Total      : $ramGB GB")
    Get-CimInstance Win32_PhysicalMemory | ForEach-Object {
        $gb = [math]::Round($_.Capacity / 1GB, 1)
        $null = $sb.AppendLine("  Modulo     : $gb GB - $($_.Manufacturer) - $($_.Speed) MHz - $($_.DeviceLocator)")
    }

    # GPU
    Write-Host "  Recopilando: GPU..." -ForegroundColor DarkGray
    $null = $sb.AppendLine("`n[ TARJETA GRAFICA ]")
    Get-CimInstance Win32_VideoController | ForEach-Object {
        $vram = [math]::Round($_.AdapterRAM / 1MB)
        $null = $sb.AppendLine("  $($_.Name) | VRAM: $vram MB | Res: $($_.CurrentHorizontalResolution)x$($_.CurrentVerticalResolution)")
    }

    # Discos
    Write-Host "  Recopilando: Discos..." -ForegroundColor DarkGray
    $null = $sb.AppendLine("`n[ DISCOS ]")
    Get-PhysicalDisk | ForEach-Object {
        $null = $sb.AppendLine("  $($_.FriendlyName) | $($_.MediaType) | $([math]::Round($_.Size/1GB)) GB | $($_.HealthStatus)")
    }
    Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 } | ForEach-Object {
        $total = [math]::Round(($_.Used + $_.Free) / 1GB, 1)
        $usado = [math]::Round($_.Used / 1GB, 1)
        $null = $sb.AppendLine("  Unidad $($_.Name): $usado GB usados / $total GB total")
    }

    # Red
    Write-Host "  Recopilando: Red..." -ForegroundColor DarkGray
    $null = $sb.AppendLine("`n[ RED ]")
    Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | ForEach-Object {
        $null = $sb.AppendLine("  $($_.InterfaceAlias): $($_.IPv4Address.IPAddress) | GW: $($_.IPv4DefaultGateway.NextHop) | DNS: $($_.DNSServer.ServerAddresses -join ',')")
    }

    # Actualizaciones pendientes
    Write-Host "  Recopilando: Actualizaciones..." -ForegroundColor DarkGray
    $null = $sb.AppendLine("`n[ ULTIMAS ACTUALIZACIONES ]")
    try {
        Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10 | ForEach-Object {
            $null = $sb.AppendLine("  $($_.HotFixID) - $($_.Description) - $($_.InstalledOn)")
        }
    } catch {
        $null = $sb.AppendLine("  No disponible")
    }

    $null = $sb.AppendLine("`n" + "=" * 70)
    $null = $sb.AppendLine("   FIN DEL REPORTE - SOPTEC AUTO")
    $null = $sb.AppendLine("=" * 70)

    $sb.ToString() | Out-File -FilePath $ruta -Encoding UTF8

    Write-Host ""
    Write-Host "  Reporte generado en: " -ForegroundColor Green -NoNewline
    Write-Host $ruta -ForegroundColor White
    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function New-ReporteRendimiento {
    Show-ModuleHeader "REPORTE DE RENDIMIENTO EN TIEMPO REAL" "White"

    Write-Host "  Tomando muestra de rendimiento (5 segundos)..." -ForegroundColor DarkGray
    Write-Host ""

    # CPU usage
    $cpu1 = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    Start-Sleep -Seconds 2
    $cpu2 = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $cpuUso = [math]::Round(($cpu1 + $cpu2) / 2)

    # RAM
    $os      = Get-CimInstance Win32_OperatingSystem
    $ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $ramLibre = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    $ramUsada = [math]::Round($ramTotal - $ramLibre, 1)
    $ramPct   = [math]::Round($ramUsada / $ramTotal * 100)

    # Disco
    $discos = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }

    # Color segun uso
    $cpuColor = if ($cpuUso -ge 80) { "Red" } elseif ($cpuUso -ge 50) { "Yellow" } else { "Green" }
    $ramColor = if ($ramPct -ge 85) { "Red" } elseif ($ramPct -ge 65) { "Yellow" } else { "Green" }

    Write-Host "  USO DE CPU    : " -ForegroundColor White -NoNewline
    Write-Host "$cpuUso%" -ForegroundColor $cpuColor

    Write-Host "  USO DE RAM    : " -ForegroundColor White -NoNewline
    Write-Host "$ramUsada GB / $ramTotal GB ($ramPct%)" -ForegroundColor $ramColor

    Write-Host ""
    Write-Host "  DISCOS:" -ForegroundColor Cyan
    foreach ($d in $discos) {
        $totalGB = [math]::Round(($d.Used + $d.Free) / 1GB, 1)
        $usadoGB = [math]::Round($d.Used / 1GB, 1)
        $libreGB = [math]::Round($d.Free / 1GB, 1)
        $pct     = if ($totalGB -gt 0) { [math]::Round($usadoGB / $totalGB * 100) } else { 0 }
        $dColor  = if ($pct -ge 90) { "Red" } elseif ($pct -ge 75) { "Yellow" } else { "Green" }
        Write-Host "    $($d.Name): $usadoGB GB usados / $libreGB GB libres / $totalGB GB total ($pct%)" -ForegroundColor $dColor
    }

    Write-Host ""
    Write-Host "  PROCESOS TOP (por CPU):" -ForegroundColor Cyan
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 8 | ForEach-Object {
        $cpuP = [math]::Round($_.CPU, 1)
        $ramP = [math]::Round($_.WorkingSet64 / 1MB, 1)
        Write-Host "    $($_.Name.PadRight(25)) CPU: $($cpuP.ToString().PadLeft(8))s  RAM: $ramP MB" -ForegroundColor White
    }

    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function New-ReporteRed {
    Show-ModuleHeader "REPORTE DE RED" "White"
    # Reutiliza la funcion de exportacion del modulo red.ps1
    Export-ConfigRed
}

# -----------------------------------------------------------------------------

function New-ReporteSoftware {
    Show-ModuleHeader "REPORTE DE SOFTWARE INSTALADO" "White"

    $ruta = "$env:USERPROFILE\Desktop\Software_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"
    Write-Host "  Listando programas instalados..." -ForegroundColor DarkGray

    $sb = [System.Text.StringBuilder]::new()
    $null = $sb.AppendLine("=" * 70)
    $null = $sb.AppendLine("   SOFTWARE INSTALADO - SOPTEC AUTO")
    $null = $sb.AppendLine("   Generado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $null = $sb.AppendLine("=" * 70)

    $regPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $programas = @()
    foreach ($path in $regPaths) {
        try {
            $items = Get-ItemProperty $path -ErrorAction SilentlyContinue |
                     Where-Object { $_.DisplayName -and $_.DisplayName.Trim() -ne "" } |
                     Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
            $programas += $items
        } catch {}
    }

    $programas = $programas | Sort-Object DisplayName -Unique

    $null = $sb.AppendLine("`nTotal de programas encontrados: $($programas.Count)")
    $null = $sb.AppendLine("")

    foreach ($p in $programas) {
        $version   = if ($p.DisplayVersion) { "v$($p.DisplayVersion)" } else { "" }
        $publisher = if ($p.Publisher)       { "[$($p.Publisher)]" }      else { "" }
        $null = $sb.AppendLine("  $($p.DisplayName.PadRight(50)) $version  $publisher")
    }

    $null = $sb.AppendLine("`n" + "=" * 70)
    $sb.ToString() | Out-File -FilePath $ruta -Encoding UTF8

    Write-Host ""
    Write-Host "  $($programas.Count) programas encontrados." -ForegroundColor White
    Write-Host "  Exportado a: " -ForegroundColor Green -NoNewline
    Write-Host $ruta -ForegroundColor White
    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function New-ReporteSeguridad {
    Show-ModuleHeader "REPORTE DE SEGURIDAD" "Yellow"

    Write-Host "  Analizando estado de seguridad del sistema..." -ForegroundColor DarkGray
    Write-Host ""

    # Firewall
    Write-Host "  FIREWALL DE WINDOWS:" -ForegroundColor Cyan
    try {
        $perfiles = Get-NetFirewallProfile -ErrorAction Stop
        foreach ($p in $perfiles) {
            $estado = if ($p.Enabled) { "ACTIVO" } else { "DESACTIVADO" }
            $color  = if ($p.Enabled) { "Green" } else { "Red" }
            Write-Host "    $($p.Name.PadRight(12)) : " -ForegroundColor White -NoNewline
            Write-Host $estado -ForegroundColor $color
        }
    } catch {
        Write-Host "    No disponible" -ForegroundColor DarkGray
    }
    Write-Host ""

    # Antivirus / Windows Defender
    Write-Host "  WINDOWS DEFENDER / ANTIVIRUS:" -ForegroundColor Cyan
    try {
        $defender = Get-MpComputerStatus -ErrorAction Stop
        $avColor  = if ($defender.AntivirusEnabled) { "Green" } else { "Red" }
        $rwColor  = if ($defender.RealTimeProtectionEnabled) { "Green" } else { "Red" }
        Write-Host "    Antivirus activo       : " -ForegroundColor White -NoNewline
        Write-Host $defender.AntivirusEnabled -ForegroundColor $avColor
        Write-Host "    Proteccion en tiempo real: " -ForegroundColor White -NoNewline
        Write-Host $defender.RealTimeProtectionEnabled -ForegroundColor $rwColor
        Write-Host "    Ultima definicion      : $($defender.AntivirusSignatureLastUpdated)" -ForegroundColor White
        Write-Host "    Ultimo escaneo completo: $($defender.FullScanEndTime)" -ForegroundColor White
    } catch {
        Write-Host "    Windows Defender no disponible o gestionado por terceros." -ForegroundColor DarkGray
    }
    Write-Host ""

    # UAC
    Write-Host "  CONTROL DE CUENTAS (UAC):" -ForegroundColor Cyan
    try {
        $uac = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
                                -Name "EnableLUA" -ErrorAction Stop
        $color = if ($uac.EnableLUA -eq 1) { "Green" } else { "Red" }
        $texto = if ($uac.EnableLUA -eq 1) { "HABILITADO" } else { "DESHABILITADO" }
        Write-Host "    Estado                 : " -ForegroundColor White -NoNewline
        Write-Host $texto -ForegroundColor $color
    } catch {
        Write-Host "    No disponible" -ForegroundColor DarkGray
    }
    Write-Host ""

    # Actualizaciones pendientes recientes
    Write-Host "  ULTIMAS 5 ACTUALIZACIONES INSTALADAS:" -ForegroundColor Cyan
    try {
        Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5 | ForEach-Object {
            Write-Host "    $($_.HotFixID)  $($_.Description.PadRight(30)) $($_.InstalledOn)" -ForegroundColor White
        }
    } catch {
        Write-Host "    No disponible" -ForegroundColor DarkGray
    }

    Write-Host ""
    Pause-Menu
}
