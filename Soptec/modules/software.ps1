# =============================================================================
#  MODULO: software.ps1
#  Descripcion: Gestor de Software y Arranque
#  Requiere: Show-Banner, Show-ModuleHeader, Pause-Menu (definidos en soptec.ps1)
# =============================================================================

function Invoke-GestorSoftware {
    do {
        Show-ModuleHeader "GESTOR DE SOFTWARE Y ARRANQUE" "White"

        Write-Host "   1. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Listar programas instalados          " -ForegroundColor White -NoNewline
        Write-Host "(registro + filtro)" -ForegroundColor DarkGray

        Write-Host "   2. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Gestionar programas de inicio        " -ForegroundColor Yellow -NoNewline
        Write-Host "(Run keys + Scheduler)" -ForegroundColor DarkGray

        Write-Host "   3. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Habilitar / Deshabilitar servicios   " -ForegroundColor Yellow

        Write-Host "   4. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Eliminar bloatware de Windows        " -ForegroundColor Red -NoNewline
        Write-Host "(AppX)" -ForegroundColor DarkGray

        Write-Host ""
        Show-Separator
        Write-Host ""
        Write-Host "   0. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Volver al Menu Principal" -ForegroundColor Red
        Write-Host ""

        Write-Host "  + Opcion: " -ForegroundColor Cyan -NoNewline
        $op = (Read-Host).Trim()

        switch ($op) {
            "1" { Show-ProgramasInstalados  }
            "2" { Invoke-GestorArranque     }
            "3" { Invoke-GestorServicios    }
            "4" { Invoke-EliminarBloatware  }
            "0" { break }
            default {
                Write-Host "  Opcion no valida." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($op -ne "0")
}

# =============================================================================

function Show-ProgramasInstalados {
    Show-ModuleHeader "PROGRAMAS INSTALADOS" "White"

    Write-Host "  Buscando en el registro..." -ForegroundColor DarkGray

    $regPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $programas = @()
    foreach ($path in $regPaths) {
        $items = Get-ItemProperty $path -ErrorAction SilentlyContinue |
                 Where-Object { $_.DisplayName -and $_.DisplayName.Trim() }
        $programas += $items
    }

    $programas = $programas |
                 Sort-Object DisplayName -Unique |
                 Select-Object DisplayName, DisplayVersion, Publisher

    Write-Host ""
    Write-Host "  Filtrar por nombre (Enter = mostrar todos): " -ForegroundColor Cyan -NoNewline
    $filtro = (Read-Host).Trim()

    if ($filtro) {
        $programas = $programas | Where-Object { $_.DisplayName -like "*$filtro*" }
    }

    Write-Host ""
    Write-Host "  $($programas.Count) programa(s) encontrado(s):" -ForegroundColor White
    Show-Separator
    Write-Host ""

    foreach ($p in $programas) {
        $ver = if ($p.DisplayVersion) { "v$($p.DisplayVersion)" } else { "       " }
        $pub = if ($p.Publisher)      { "[$($p.Publisher)]"      } else { ""        }
        Write-Host "  " -NoNewline
        Write-Host $p.DisplayName.PadRight(45) -ForegroundColor White -NoNewline
        Write-Host $ver.PadRight(14)            -ForegroundColor DarkGray -NoNewline
        Write-Host $pub                         -ForegroundColor DarkGray
    }

    Write-Host ""
    Pause-Menu
}

# =============================================================================

function Invoke-GestorArranque {
    do {
        Show-ModuleHeader "GESTOR DE PROGRAMAS DE INICIO" "Yellow"

        Write-Host "  Recopilando entradas de inicio..." -ForegroundColor DarkGray
        Write-Host ""

        # ---- Recopilar entradas ----
        $entradas = @()
        $idx = 1

        # Run keys de registro
        $runKeys = @(
            @{ Hive = "HKCU"; Path = "Software\Microsoft\Windows\CurrentVersion\Run" },
            @{ Hive = "HKLM"; Path = "SOFTWARE\Microsoft\Windows\CurrentVersion\Run" },
            @{ Hive = "HKCU"; Path = "Software\Microsoft\Windows\CurrentVersion\RunOnce" },
            @{ Hive = "HKLM"; Path = "SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" }
        )

        foreach ($rk in $runKeys) {
            $regPath = "$($rk.Hive):\$($rk.Path)"
            try {
                $props = Get-ItemProperty -Path $regPath -ErrorAction Stop
                $props.PSObject.Properties |
                Where-Object { $_.Name -notlike "PS*" } |
                ForEach-Object {
                    $entradas += [PSCustomObject]@{
                        Num    = $idx
                        Nombre = $_.Name
                        Valor  = $_.Value
                        Origen = "$($rk.Hive)\...\Run"
                        RegPath= $regPath
                        Tipo   = "Registry"
                    }
                    $idx++
                }
            } catch {}
        }

        # Carpeta de inicio del usuario
        $startupFolder = [System.Environment]::GetFolderPath("Startup")
        Get-ChildItem $startupFolder -File -ErrorAction SilentlyContinue | ForEach-Object {
            $entradas += [PSCustomObject]@{
                Num    = $idx
                Nombre = $_.BaseName
                Valor  = $_.FullName
                Origen = "Shell:Startup"
                RegPath= $startupFolder
                Tipo   = "Folder"
            }
            $idx++
        }

        # Mostrar tabla
        if ($entradas.Count -eq 0) {
            Write-Host "  No se encontraron entradas de inicio." -ForegroundColor DarkGray
        } else {
            Write-Host ("  " + "Num".PadRight(5) + "Nombre".PadRight(30) + "Origen".PadRight(22) + "Ruta/Valor") -ForegroundColor Cyan
            Show-Separator
            foreach ($e in $entradas) {
                $valorCorto = if ($e.Valor.Length -gt 45) { $e.Valor.Substring(0,42) + "..." } else { $e.Valor }
                Write-Host "  " -NoNewline
                Write-Host ("[{0}]" -f $e.Num).PadRight(5)       -ForegroundColor Yellow -NoNewline
                Write-Host $e.Nombre.PadRight(30)                  -ForegroundColor White  -NoNewline
                Write-Host $e.Origen.PadRight(22)                  -ForegroundColor DarkGray -NoNewline
                Write-Host $valorCorto                             -ForegroundColor DarkGray
            }
        }

        Write-Host ""
        Show-Separator
        Write-Host ""
        Write-Host "   D. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Deshabilitar entrada (por numero)" -ForegroundColor Red
        Write-Host "   0. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Volver" -ForegroundColor Red
        Write-Host ""

        Write-Host "  + Opcion: " -ForegroundColor Cyan -NoNewline
        $sub = (Read-Host).Trim().ToUpper()

        if ($sub -eq "D") {
            if (-not (Show-AdminWarning)) { continue }
            Write-Host "  Numero de entrada a deshabilitar: " -ForegroundColor Cyan -NoNewline
            $numStr = (Read-Host).Trim()
            $num = 0
            if ([int]::TryParse($numStr, [ref]$num)) {
                $entrada = $entradas | Where-Object { $_.Num -eq $num } | Select-Object -First 1
                if ($entrada) {
                    if ($entrada.Tipo -eq "Registry") {
                        try {
                            Remove-ItemProperty -Path $entrada.RegPath -Name $entrada.Nombre -ErrorAction Stop
                            Write-Host "  Entrada '$($entrada.Nombre)' eliminada del registro." -ForegroundColor Green
                        } catch {
                            Write-Host "  Error: $_" -ForegroundColor Red
                        }
                    } elseif ($entrada.Tipo -eq "Folder") {
                        try {
                            $dest = "$($entrada.RegPath)\Disabled_$($entrada.Nombre)$(Split-Path $entrada.Valor -Extension)"
                            Rename-Item -Path $entrada.Valor -NewName (Split-Path $dest -Leaf) -ErrorAction Stop
                            Write-Host "  Archivo renombrado (prefijo Disabled_)." -ForegroundColor Green
                        } catch {
                            Write-Host "  Error: $_" -ForegroundColor Red
                        }
                    }
                } else {
                    Write-Host "  Numero no encontrado." -ForegroundColor Red
                }
            }
            Pause-Menu
        }

    } while ($sub -ne "0")
}

# =============================================================================

function Invoke-GestorServicios {
    do {
        Show-ModuleHeader "GESTIONAR SERVICIOS DE WINDOWS" "Yellow"

        # Servicios mas relevantes para el usuario
        $serviciosFiltro = @(
            "wuauserv",      # Windows Update
            "DiagTrack",     # Telemetria
            "SysMain",       # Superfetch
            "WSearch",       # Windows Search
            "spooler",       # Cola de impresion
            "Fax",           # Fax
            "XblGameSave",   # Xbox
            "XboxGipSvc",    # Xbox
            "MapsBroker",    # Mapas descargados
            "lfsvc",         # Geolocalizacion
            "wisvc",         # Windows Insider
            "RetailDemo",    # Demo modo tienda
            "RemoteRegistry",# Registro remoto
            "Themes",        # Temas visuales
            "AudioSrv",      # Audio
            "BITS",          # Background transfer
            "W32Time",       # Hora Windows
            "Netlogon",      # Inicio sesion red
            "WinRM",         # Administracion remota
            "TrkWks"         # Seguimiento de vinculos
        )

        $servicios = Get-Service -Name $serviciosFiltro -ErrorAction SilentlyContinue |
                     Sort-Object DisplayName

        Write-Host ("  " + "#".PadRight(4) + "Estado".PadRight(12) + "Nombre corto".PadRight(20) + "Descripcion") -ForegroundColor Cyan
        Show-Separator
        $i = 1
        foreach ($s in $servicios) {
            $color = switch ($s.Status) {
                "Running" { "Green"  }
                "Stopped" { "Red"    }
                default   { "Yellow" }
            }
            Write-Host "  " -NoNewline
            Write-Host "[$i]".PadRight(4)              -ForegroundColor Yellow -NoNewline
            Write-Host $s.Status.ToString().PadRight(12) -ForegroundColor $color -NoNewline
            Write-Host $s.Name.PadRight(20)              -ForegroundColor White -NoNewline
            Write-Host $s.DisplayName                    -ForegroundColor DarkGray
            $i++
        }

        Write-Host ""
        Show-Separator
        Write-Host ""
        Write-Host "   I [num]  " -ForegroundColor DarkGray -NoNewline
        Write-Host "Iniciar servicio" -ForegroundColor Green
        Write-Host "   D [num]  " -ForegroundColor DarkGray -NoNewline
        Write-Host "Detener servicio" -ForegroundColor Red
        Write-Host "   A [num]  " -ForegroundColor DarkGray -NoNewline
        Write-Host "Cambiar a inicio Automatico" -ForegroundColor Yellow
        Write-Host "   M [num]  " -ForegroundColor DarkGray -NoNewline
        Write-Host "Cambiar a inicio Manual" -ForegroundColor Yellow
        Write-Host "   0         " -ForegroundColor DarkGray -NoNewline
        Write-Host "Volver" -ForegroundColor Red
        Write-Host ""

        Write-Host "  + Accion y numero (ej: I 3): " -ForegroundColor Cyan -NoNewline
        $input = (Read-Host).Trim().ToUpper() -split "\s+"
        $accion = $input[0]
        $numStr = if ($input.Count -gt 1) { $input[1] } else { "" }

        if ($accion -eq "0") { break }

        if (-not (Show-AdminWarning)) { continue }

        $num = 0
        if ([int]::TryParse($numStr, [ref]$num) -and $num -ge 1 -and $num -le $servicios.Count) {
            $svc = $servicios[$num - 1]
            switch ($accion) {
                "I" {
                    Start-Service $svc.Name -ErrorAction SilentlyContinue
                    Write-Host "  Iniciado: $($svc.DisplayName)" -ForegroundColor Green
                }
                "D" {
                    Stop-Service $svc.Name -Force -ErrorAction SilentlyContinue
                    Write-Host "  Detenido: $($svc.DisplayName)" -ForegroundColor Red
                }
                "A" {
                    Set-Service $svc.Name -StartupType Automatic -ErrorAction SilentlyContinue
                    Write-Host "  Cambiado a Automatico: $($svc.DisplayName)" -ForegroundColor Yellow
                }
                "M" {
                    Set-Service $svc.Name -StartupType Manual -ErrorAction SilentlyContinue
                    Write-Host "  Cambiado a Manual: $($svc.DisplayName)" -ForegroundColor Yellow
                }
                default { Write-Host "  Accion no reconocida." -ForegroundColor Red }
            }
        } else {
            if ($accion -ne "0") { Write-Host "  Numero fuera de rango." -ForegroundColor Red }
        }

        Start-Sleep -Seconds 1

    } while ($true)
}

# =============================================================================

function Invoke-EliminarBloatware {
    Show-ModuleHeader "ELIMINAR BLOATWARE DE WINDOWS" "Red"

    if (-not (Show-AdminWarning)) { return }

    # Lista de paquetes AppX bloatware comunes en Windows 10/11
    $bloatware = [ordered]@{
        "BingNews"          = "Microsoft.BingNews"
        "BingWeather"       = "Microsoft.BingWeather"
        "GamingApp (Xbox)"  = "Microsoft.GamingApp"
        "GetHelp"           = "Microsoft.GetHelp"
        "Comenzar (Tips)"   = "Microsoft.Getstarted"
        "Office Hub"        = "Microsoft.MicrosoftOfficeHub"
        "Solitaire"         = "Microsoft.MicrosoftSolitaireCollection"
        "Teams (builtin)"   = "Microsoft.MicrosoftTeams"
        "People"            = "Microsoft.People"
        "Skype"             = "Microsoft.SkypeApp"
        "Mail y Calendario" = "Microsoft.WindowsCommunicationsApps"
        "Xbox TCUI"         = "Microsoft.Xbox.TCUI"
        "Xbox App"          = "Microsoft.XboxApp"
        "Xbox Game Bar"     = "Microsoft.XboxGamingOverlay"
        "Xbox Identity"     = "Microsoft.XboxIdentityProvider"
        "Your Phone"        = "Microsoft.YourPhone"
        "Groove Music"      = "Microsoft.ZuneMusic"
        "Peliculas y TV"    = "Microsoft.ZuneVideo"
        "3D Viewer"         = "Microsoft.Microsoft3DViewer"
        "Mixed Reality"     = "Microsoft.MixedReality.Portal"
        "OneNote"           = "Microsoft.Office.OneNote"
        "Feedback Hub"      = "Microsoft.WindowsFeedbackHub"
    }

    # Mostrar cuales estan instalados
    Write-Host "  Detectando paquetes instalados..." -ForegroundColor DarkGray
    Write-Host ""

    $instalados = @()
    $i = 1
    foreach ($nombre in $bloatware.Keys) {
        $paquete = $bloatware[$nombre]
        $existe  = Get-AppxPackage -Name $paquete -ErrorAction SilentlyContinue
        if ($existe) {
            Write-Host "  " -NoNewline
            Write-Host "[$i]".PadRight(5) -ForegroundColor Yellow -NoNewline
            Write-Host $nombre.PadRight(25) -ForegroundColor White -NoNewline
            Write-Host $paquete -ForegroundColor DarkGray
            $instalados += [PSCustomObject]@{ Num = $i; Nombre = $nombre; Paquete = $paquete }
            $i++
        }
    }

    if ($instalados.Count -eq 0) {
        Write-Host "  No se encontro bloatware conocido instalado." -ForegroundColor Green
        Write-Host ""
        Pause-Menu
        return
    }

    Write-Host ""
    Show-Separator
    Write-Host ""
    Write-Host "  Opciones:" -ForegroundColor DarkGray
    Write-Host "   T. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Eliminar TODOS los de la lista" -ForegroundColor Red
    Write-Host "   [numero]. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Eliminar uno especifico" -ForegroundColor Yellow
    Write-Host "   0. Cancelar" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  + Opcion: " -ForegroundColor Cyan -NoNewline
    $eleccion = (Read-Host).Trim().ToUpper()

    if ($eleccion -eq "0") { return }

    $aEliminar = @()
    if ($eleccion -eq "T") {
        $aEliminar = $instalados
    } else {
        $num = 0
        if ([int]::TryParse($eleccion, [ref]$num)) {
            $aEliminar = $instalados | Where-Object { $_.Num -eq $num }
        }
    }

    if ($aEliminar.Count -eq 0) {
        Write-Host "  Seleccion no valida." -ForegroundColor Red
        Pause-Menu
        return
    }

    Write-Host ""
    foreach ($item in $aEliminar) {
        Write-Host "  Eliminando: " -ForegroundColor DarkGray -NoNewline
        Write-Host $item.Nombre -ForegroundColor White -NoNewline
        Write-Host "..." -ForegroundColor DarkGray
        try {
            Get-AppxPackage -Name $item.Paquete -AllUsers -ErrorAction SilentlyContinue |
                Remove-AppxPackage -ErrorAction SilentlyContinue
            # Eliminar tambien el paquete provisionado para nuevos usuarios
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                Where-Object { $_.PackageName -like "*$($item.Paquete)*" } |
                Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
            Write-Host "    Eliminado." -ForegroundColor Green
        } catch {
            Write-Host "    Error: $_" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "  Proceso completado." -ForegroundColor Green
    Write-Host ""
    Pause-Menu
}
