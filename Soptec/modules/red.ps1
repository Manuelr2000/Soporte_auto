# =============================================================================
#  MODULO: red.ps1
#  Descripcion: Redes y conectividad
#  Requiere: Show-Banner, Show-ModuleHeader, Pause-Menu (definidos en soptec.ps1)
# =============================================================================

function Invoke-Red {
    do {
        Show-ModuleHeader "REDES Y CONECTIVIDAD" "Cyan"

        Write-Host "   1. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Test de conectividad          " -ForegroundColor White -NoNewline
        Write-Host "(ping multiple servidores)" -ForegroundColor DarkGray

        Write-Host "   2. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Renovar IP y limpiar DNS      " -ForegroundColor White -NoNewline
        Write-Host "(ipconfig /release /renew /flushdns)" -ForegroundColor DarkGray

        Write-Host "   3. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Reset completo de red         " -ForegroundColor Red -NoNewline
        Write-Host "(Winsock + IP stack)" -ForegroundColor DarkGray

        Write-Host "   4. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Exportar configuracion de red " -ForegroundColor White -NoNewline
        Write-Host "(TXT)" -ForegroundColor DarkGray

        Write-Host ""
        Show-Separator
        Write-Host ""
        Write-Host "   0. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Volver al Menu Principal" -ForegroundColor Red
        Write-Host ""

        Write-Host "  + Opcion: " -ForegroundColor Cyan -NoNewline
        $op = (Read-Host).Trim()

        switch ($op) {
            "1" { Invoke-TestConectividad  }
            "2" { Invoke-RenovarIP         }
            "3" { Invoke-ResetRed          }
            "4" { Export-ConfigRed         }
            "0" { break }
            default {
                Write-Host "  Opcion no valida." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($op -ne "0")
}

# -----------------------------------------------------------------------------

function Invoke-TestConectividad {
    Show-ModuleHeader "TEST DE CONECTIVIDAD" "Cyan"

    $servidores = [ordered]@{
        "Google DNS"        = "8.8.8.8"
        "Cloudflare DNS"    = "1.1.1.1"
        "Microsoft"         = "microsoft.com"
        "Google"            = "google.com"
        "Gateway local"     = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
                                Sort-Object RouteMetric | Select-Object -First 1).NextHop
    }

    Write-Host "  Probando conectividad a multiples destinos..." -ForegroundColor DarkGray
    Write-Host ""

    $hayFallo = $false

    foreach ($nombre in $servidores.Keys) {
        $destino = $servidores[$nombre]
        if (-not $destino) {
            Write-Host "  $($nombre.PadRight(20)) " -ForegroundColor White -NoNewline
            Write-Host "[SKIP] No detectado" -ForegroundColor DarkGray
            continue
        }

        $resultado = Test-Connection -ComputerName $destino -Count 3 -ErrorAction SilentlyContinue

        if ($resultado) {
            $avg = [math]::Round(($resultado | Measure-Object -Property ResponseTime -Average).Average)
            Write-Host "  $($nombre.PadRight(20)) " -ForegroundColor White -NoNewline
            Write-Host "[OK] " -ForegroundColor Green -NoNewline
            Write-Host "$destino  ~${avg}ms" -ForegroundColor DarkGray
        } else {
            Write-Host "  $($nombre.PadRight(20)) " -ForegroundColor White -NoNewline
            Write-Host "[FALLO] " -ForegroundColor Red -NoNewline
            Write-Host $destino -ForegroundColor DarkGray
            $hayFallo = $true
        }
    }

    Write-Host ""
    Show-Separator
    Write-Host ""

    if ($hayFallo) {
        Write-Host "  Resultado: " -ForegroundColor White -NoNewline
        Write-Host "Conectividad parcial o sin internet." -ForegroundColor Yellow
        Write-Host "  Sugerencia: Usa la opcion 2 para renovar IP/DNS." -ForegroundColor DarkGray
    } else {
        Write-Host "  Resultado: " -ForegroundColor White -NoNewline
        Write-Host "Conectividad correcta en todos los destinos." -ForegroundColor Green
    }

    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function Invoke-RenovarIP {
    Show-ModuleHeader "RENOVAR IP Y LIMPIAR DNS" "White"

    if (-not (Show-AdminWarning)) { return }

    Write-Host "  Operaciones que se realizaran:" -ForegroundColor DarkGray
    Write-Host "    - ipconfig /release  (liberar IP actual)" -ForegroundColor DarkGray
    Write-Host "    - ipconfig /renew    (solicitar nueva IP)" -ForegroundColor DarkGray
    Write-Host "    - ipconfig /flushdns (limpiar cache DNS)" -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  [1/3] Liberando IP..." -ForegroundColor Cyan
    & ipconfig /release 2>&1 | Out-Null
    Write-Host "  IP liberada." -ForegroundColor Green

    Write-Host "  [2/3] Renovando IP..." -ForegroundColor Cyan
    & ipconfig /renew 2>&1 | Out-Null
    Write-Host "  IP renovada." -ForegroundColor Green

    Write-Host "  [3/3] Limpiando cache DNS..." -ForegroundColor Cyan
    & ipconfig /flushdns 2>&1 | Out-Null
    Write-Host "  Cache DNS limpiado." -ForegroundColor Green

    Write-Host ""

    # Mostrar nueva configuracion
    Write-Host "  Configuracion IP actual:" -ForegroundColor Cyan
    $adapters = Get-NetIPConfiguration | Where-Object { $_.IPv4Address }
    foreach ($a in $adapters) {
        Write-Host "    Adaptador : $($a.InterfaceAlias)" -ForegroundColor White
        Write-Host "    IP        : $($a.IPv4Address.IPAddress)" -ForegroundColor White
        Write-Host "    Gateway   : $($a.IPv4DefaultGateway.NextHop)" -ForegroundColor White
        Write-Host "    DNS       : $($a.DNSServer.ServerAddresses -join ', ')" -ForegroundColor White
        Write-Host ""
    }

    Pause-Menu
}

# -----------------------------------------------------------------------------

function Invoke-ResetRed {
    Show-ModuleHeader "RESET COMPLETO DE RED" "Red"

    if (-not (Show-AdminWarning)) { return }

    Write-Host "  ADVERTENCIA: Esta operacion restablece toda la configuracion" -ForegroundColor Red
    Write-Host "  de red de Windows. Se requiere reiniciar el equipo." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Operaciones:" -ForegroundColor DarkGray
    Write-Host "    - netsh winsock reset     (catalogo Winsock)" -ForegroundColor DarkGray
    Write-Host "    - netsh int ip reset       (pila TCP/IP)" -ForegroundColor DarkGray
    Write-Host "    - netsh advfirewall reset  (firewall)" -ForegroundColor DarkGray
    Write-Host "    - ipconfig /flushdns" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Confirmar reset completo? " -ForegroundColor Yellow -NoNewline
    Write-Host "[S/N]: " -ForegroundColor Cyan -NoNewline
    $confirm = (Read-Host).Trim().ToUpper()

    if ($confirm -ne "S") {
        Write-Host "  Cancelado." -ForegroundColor DarkGray
        Pause-Menu
        return
    }

    Write-Host ""
    Write-Host "  [1/4] Reseteando Winsock..." -ForegroundColor Cyan
    & netsh winsock reset | Out-Null
    Write-Host "  Winsock restablecido." -ForegroundColor Green

    Write-Host "  [2/4] Reseteando pila IP..." -ForegroundColor Cyan
    & netsh int ip reset "$env:TEMP\ip_reset.log" | Out-Null
    Write-Host "  Pila IP restablecida." -ForegroundColor Green

    Write-Host "  [3/4] Reseteando Firewall..." -ForegroundColor Cyan
    & netsh advfirewall reset | Out-Null
    Write-Host "  Firewall restablecido." -ForegroundColor Green

    Write-Host "  [4/4] Limpiando DNS..." -ForegroundColor Cyan
    & ipconfig /flushdns | Out-Null
    Write-Host "  DNS limpiado." -ForegroundColor Green

    Write-Host ""
    Write-Host "  Reset de red completado." -ForegroundColor Green
    Write-Host "  REINICIA el equipo para aplicar todos los cambios." -ForegroundColor Yellow
    Write-Host ""
    Pause-Menu
}

# -----------------------------------------------------------------------------

function Export-ConfigRed {
    Show-ModuleHeader "EXPORTAR CONFIGURACION DE RED" "White"

    $ruta = "$env:USERPROFILE\Desktop\ConfigRed_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"
    Write-Host "  Recopilando informacion de red..." -ForegroundColor DarkGray

    $sb = [System.Text.StringBuilder]::new()

    $null = $sb.AppendLine("=" * 60)
    $null = $sb.AppendLine("  CONFIGURACION DE RED - SOPTEC AUTO")
    $null = $sb.AppendLine("  Generado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $null = $sb.AppendLine("=" * 60)

    # Adaptadores activos
    $null = $sb.AppendLine("`n[ ADAPTADORES ACTIVOS ]")
    $configs = Get-NetIPConfiguration
    foreach ($c in $configs) {
        $null = $sb.AppendLine("`n  Interfaz  : $($c.InterfaceAlias) [$($c.InterfaceIndex)]")
        if ($c.IPv4Address) {
            $null = $sb.AppendLine("  IPv4      : $($c.IPv4Address.IPAddress)/$($c.IPv4Address.PrefixLength)")
        }
        if ($c.IPv6Address) {
            $null = $sb.AppendLine("  IPv6      : $($c.IPv6Address.IPAddress)")
        }
        if ($c.IPv4DefaultGateway) {
            $null = $sb.AppendLine("  Gateway   : $($c.IPv4DefaultGateway.NextHop)")
        }
        if ($c.DNSServer) {
            $null = $sb.AppendLine("  DNS       : $($c.DNSServer.ServerAddresses -join ', ')")
        }
    }

    # MACs
    $null = $sb.AppendLine("`n[ DIRECCIONES MAC ]")
    Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        $null = $sb.AppendLine("  $($_.Name.PadRight(25)) $($_.MacAddress)  [$($_.LinkSpeed)]")
    }

    # Puertos en escucha
    $null = $sb.AppendLine("`n[ PUERTOS EN ESCUCHA ]")
    try {
        $conexiones = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
                      Sort-Object LocalPort |
                      Select-Object LocalPort, OwningProcess -Unique |
                      Select-Object -First 30
        foreach ($conn in $conexiones) {
            $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            $nombre = if ($proc) { $proc.Name } else { "N/A" }
            $null = $sb.AppendLine("  Puerto $($conn.LocalPort.ToString().PadRight(6)) -> $nombre (PID: $($conn.OwningProcess))")
        }
    } catch {}

    # ipconfig /all
    $null = $sb.AppendLine("`n[ IPCONFIG /ALL ]")
    $ipconfigOutput = & ipconfig /all 2>&1
    foreach ($linea in $ipconfigOutput) {
        $null = $sb.AppendLine("  $linea")
    }

    # Tabla de enrutamiento
    $null = $sb.AppendLine("`n[ TABLA DE RUTAS ]")
    $rutas = & route print 2>&1
    foreach ($r in $rutas) {
        $null = $sb.AppendLine("  $r")
    }

    $null = $sb.AppendLine("`n" + "=" * 60)
    $null = $sb.AppendLine("  FIN DEL REPORTE - SOPTEC AUTO")
    $null = $sb.AppendLine("=" * 60)

    $sb.ToString() | Out-File -FilePath $ruta -Encoding UTF8

    Write-Host ""
    Write-Host "  Configuracion exportada a: " -ForegroundColor Green -NoNewline
    Write-Host $ruta -ForegroundColor White
    Write-Host ""
    Pause-Menu
}
