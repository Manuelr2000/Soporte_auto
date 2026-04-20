# =============================================================================
#  MODULO: optimizaciones.ps1
#  Descripcion: Optimizaciones del sistema y accesos directos clasicos
#  Requiere: Show-Banner, Show-ModuleHeader, Pause-Menu (definidos en soptec.ps1)
# =============================================================================

function Invoke-Optimizaciones {
    do {
        Show-ModuleHeader "OPTIMIZACIONES Y ATAJOS CLASICOS" "White"

        Write-Host "   1. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Ajustar efectos visuales           " -ForegroundColor White -NoNewline
        Write-Host "(mejor rendimiento / apariencia)" -ForegroundColor DarkGray

        Write-Host "   2. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Privacidad y Telemetria Windows    " -ForegroundColor Yellow -NoNewline
        Write-Host "(desactivar seguimiento)" -ForegroundColor DarkGray

        Write-Host "   3. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Crear accesos directos clasicos    " -ForegroundColor White -NoNewline
        Write-Host "(herramientas admin en escritorio)" -ForegroundColor DarkGray

        Write-Host "   4. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Ajustes de energia                 " -ForegroundColor Yellow -NoNewline
        Write-Host "(planes, pantalla, suspension)" -ForegroundColor DarkGray

        Write-Host ""
        Show-Separator
        Write-Host ""
        Write-Host "   0. " -ForegroundColor DarkGray -NoNewline
        Write-Host "Volver al Menu Principal" -ForegroundColor Red
        Write-Host ""

        Write-Host "  + Opcion: " -ForegroundColor Cyan -NoNewline
        $op = (Read-Host).Trim()

        switch ($op) {
            "1" { Invoke-EfectosVisuales      }
            "2" { Invoke-PrivacidadTelemetria  }
            "3" { New-AccesosDirectos          }
            "4" { Invoke-AjustesEnergia        }
            "0" { break }
            default {
                Write-Host "  Opcion no valida." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($op -ne "0")
}

# =============================================================================

function Invoke-EfectosVisuales {
    Show-ModuleHeader "AJUSTAR EFECTOS VISUALES" "White"

    # Leer estado actual
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    $actual  = (Get-ItemProperty -Path $regPath -Name "VisualFXSetting" -ErrorAction SilentlyContinue).VisualFXSetting
    $modos   = @{ 0 = "Windows decide"; 1 = "Mejor apariencia"; 2 = "Mejor rendimiento"; 3 = "Personalizado" }

    Write-Host "  Estado actual: " -ForegroundColor DarkGray -NoNewline
    Write-Host $modos[[int]$actual] -ForegroundColor Cyan
    Write-Host ""

    Write-Host "   1. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Mejor rendimiento  " -ForegroundColor Green -NoNewline
    Write-Host "(deshabilita animaciones, sombras, transparencias)" -ForegroundColor DarkGray

    Write-Host "   2. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Mejor apariencia   " -ForegroundColor White -NoNewline
    Write-Host "(activa todos los efectos visuales)" -ForegroundColor DarkGray

    Write-Host "   3. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Equilibrado        " -ForegroundColor Yellow -NoNewline
    Write-Host "(Windows elige automaticamente)" -ForegroundColor DarkGray

    Write-Host "   4. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Solo quitar animaciones     " -ForegroundColor White -NoNewline
    Write-Host "(mantiene transparencia)" -ForegroundColor DarkGray

    Write-Host ""
    Write-Host "  + Opcion: " -ForegroundColor Cyan -NoNewline
    $sub = (Read-Host).Trim()

    $nuevoValor = $null
    switch ($sub) {
        "1" { $nuevoValor = 2 }
        "2" { $nuevoValor = 1 }
        "3" { $nuevoValor = 0 }
        "4" { $nuevoValor = 3 }
        default { Write-Host "  Cancelado." -ForegroundColor DarkGray; Pause-Menu; return }
    }

    # Aplicar VisualFXSetting
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "VisualFXSetting" -Value $nuevoValor

    # Ajustes adicionales de rendimiento via HKCU:\Control Panel\Desktop
    $cpDesktop = "HKCU:\Control Panel\Desktop"
    $cpWindows = "HKCU:\Control Panel\Desktop\WindowMetrics"

    if ($sub -eq "1") {
        # Mejor rendimiento: deshabilitar todo
        Set-ItemProperty -Path $cpDesktop -Name "UserPreferencesMask" `
            -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $cpDesktop -Name "MenuShowDelay" -Value "0" -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $cpDesktop -Name "DragFullWindows" -Value "0" -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            -Name "ListviewAlphaSelect" -Value 0 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            -Name "TaskbarAnimations" -Value 0 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            -Name "ListviewShadow" -Value 0 -ErrorAction SilentlyContinue
    } elseif ($sub -eq "4") {
        # Solo quitar animaciones de ventanas
        Set-ItemProperty -Path $cpDesktop -Name "MenuShowDelay" -Value "0" -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $cpDesktop -Name "DragFullWindows" -Value "1" -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            -Name "TaskbarAnimations" -Value 0 -ErrorAction SilentlyContinue
    }

    Write-Host ""
    Write-Host "  Configuracion aplicada: " -ForegroundColor Green -NoNewline
    Write-Host $modos[$nuevoValor] -ForegroundColor White
    Write-Host "  Los cambios se aplican al cerrar sesion o reiniciar Explorer." -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  Reiniciar Explorer ahora? " -ForegroundColor White -NoNewline
    Write-Host "[S/N]: " -ForegroundColor Cyan -NoNewline
    if ((Read-Host).Trim().ToUpper() -eq "S") {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Start-Process explorer.exe
        Write-Host "  Explorer reiniciado." -ForegroundColor Green
    }

    Write-Host ""
    Pause-Menu
}

# =============================================================================

function Invoke-PrivacidadTelemetria {
    Show-ModuleHeader "PRIVACIDAD Y TELEMETRIA WINDOWS" "Yellow"

    Write-Host "  Esta opcion desactiva el seguimiento de datos de uso" -ForegroundColor DarkGray
    Write-Host "  que Windows envia a Microsoft." -ForegroundColor DarkGray
    Write-Host ""

    # Mostrar estado actual de los servicios clave
    $serviciosTelem = @("DiagTrack", "dmwappushservice", "WerSvc", "PcaSvc")
    Write-Host "  Estado actual de servicios de telemetria:" -ForegroundColor Cyan
    foreach ($svcName in $serviciosTelem) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            $color = if ($svc.Status -eq "Running") { "Red" } else { "Green" }
            Write-Host "    $($svc.DisplayName.PadRight(45)) " -ForegroundColor White -NoNewline
            Write-Host $svc.Status -ForegroundColor $color
        }
    }

    Write-Host ""
    Write-Host "  Opciones:" -ForegroundColor DarkGray
    Write-Host "   1. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Desactivar telemetria y servicios de seguimiento" -ForegroundColor Red
    Write-Host "   2. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Restaurar configuracion predeterminada" -ForegroundColor Yellow
    Write-Host "   0. Volver" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  + Opcion: " -ForegroundColor Cyan -NoNewline
    $sub = (Read-Host).Trim()

    if ($sub -eq "0") { return }

    if (-not (Show-AdminWarning)) { return }

    if ($sub -eq "1") {
        Write-Host ""
        Write-Host "  [1/5] Desactivando servicio DiagTrack (telemetria)..." -ForegroundColor Cyan
        Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
        Set-Service  "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "  Hecho." -ForegroundColor Green

        Write-Host "  [2/5] Desactivando dmwappushservice..." -ForegroundColor Cyan
        Stop-Service "dmwappushservice" -Force -ErrorAction SilentlyContinue
        Set-Service  "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "  Hecho." -ForegroundColor Green

        Write-Host "  [3/5] Configurando politica de telemetria a 0 (Seguridad)..." -ForegroundColor Cyan
        $polPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        if (-not (Test-Path $polPath)) { New-Item -Path $polPath -Force | Out-Null }
        Set-ItemProperty -Path $polPath -Name "AllowTelemetry" -Value 0 -Type DWord
        Write-Host "  Hecho." -ForegroundColor Green

        Write-Host "  [4/5] Desactivando publicidad personalizada..." -ForegroundColor Cyan
        $advPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        if (-not (Test-Path $advPath)) { New-Item -Path $advPath -Force | Out-Null }
        Set-ItemProperty -Path $advPath -Name "Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Write-Host "  Hecho." -ForegroundColor Green

        Write-Host "  [5/5] Desactivando Feedback y reportes de errores..." -ForegroundColor Cyan
        $siufPath = "HKCU:\Software\Microsoft\Siuf\Rules"
        if (-not (Test-Path $siufPath)) { New-Item -Path $siufPath -Force | Out-Null }
        Set-ItemProperty -Path $siufPath -Name "NumberOfSIUFInPeriod" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Stop-Service  "WerSvc" -Force -ErrorAction SilentlyContinue
        Set-Service   "WerSvc" -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "  Hecho." -ForegroundColor Green

        Write-Host ""
        Write-Host "  Telemetria desactivada correctamente." -ForegroundColor Green

    } elseif ($sub -eq "2") {
        Write-Host ""
        Write-Host "  Restaurando servicios a configuracion predeterminada..." -ForegroundColor Cyan
        Set-Service "DiagTrack"        -StartupType Automatic -ErrorAction SilentlyContinue
        Set-Service "dmwappushservice" -StartupType Manual    -ErrorAction SilentlyContinue
        Set-Service "WerSvc"           -StartupType Manual    -ErrorAction SilentlyContinue
        $polPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        Remove-ItemProperty -Path $polPath -Name "AllowTelemetry" -ErrorAction SilentlyContinue
        Write-Host "  Configuracion restaurada." -ForegroundColor Yellow
    }

    Write-Host ""
    Pause-Menu
}

# =============================================================================

function New-AccesosDirectos {
    Show-ModuleHeader "CREAR ACCESOS DIRECTOS CLASICOS" "White"

    $escritorio = [System.Environment]::GetFolderPath("Desktop")
    $shell      = New-Object -ComObject WScript.Shell

    $herramientas = [ordered]@{
        "Administrador de tareas"        = @{ cmd = "taskmgr.exe";                        args = "" }
        "Configuracion del sistema"      = @{ cmd = "msconfig.exe";                       args = "" }
        "Editor de registro"             = @{ cmd = "regedit.exe";                        args = "" }
        "Administrador de dispositivos"  = @{ cmd = "mmc.exe";                            args = "devmgmt.msc" }
        "Servicios"                      = @{ cmd = "mmc.exe";                            args = "services.msc" }
        "Visor de eventos"               = @{ cmd = "mmc.exe";                            args = "eventvwr.msc" }
        "Administracion de equipos"      = @{ cmd = "mmc.exe";                            args = "compmgmt.msc" }
        "Administracion de discos"       = @{ cmd = "mmc.exe";                            args = "diskmgmt.msc" }
        "Monitor de rendimiento"         = @{ cmd = "mmc.exe";                            args = "perfmon.msc" }
        "Programador de tareas"          = @{ cmd = "mmc.exe";                            args = "taskschd.msc" }
        "Opciones de energia"            = @{ cmd = "powercfg.cpl";                       args = "" }
        "Opciones de pantalla"           = @{ cmd = "desk.cpl";                           args = "" }
        "Configuracion de red"           = @{ cmd = "ncpa.cpl";                           args = "" }
        "Firewall de Windows"            = @{ cmd = "wf.msc";                             args = "" }
        "Variables de entorno"           = @{ cmd = "rundll32.exe";                       args = "sysdm.cpl,EditEnvironmentVariables" }
        "Monitor de recursos"            = @{ cmd = "resmon.exe";                         args = "" }
        "Informacion del sistema"        = @{ cmd = "msinfo32.exe";                       args = "" }
        "Directiva de grupo local"       = @{ cmd = "gpedit.msc";                        args = "" }
        "PowerShell (Admin)"             = @{ cmd = "powershell.exe";                     args = "-NoExit -Command Start-Process powershell -Verb RunAs" }
    }

    Write-Host "  Se crearan los siguientes accesos directos en el escritorio:" -ForegroundColor DarkGray
    Write-Host ""

    $i = 1
    foreach ($nombre in $herramientas.Keys) {
        Write-Host "  " -NoNewline
        Write-Host "[$i]".PadRight(5) -ForegroundColor Yellow -NoNewline
        Write-Host $nombre -ForegroundColor White
        $i++
    }

    Write-Host ""
    Write-Host "  Opciones:" -ForegroundColor DarkGray
    Write-Host "   T. " -ForegroundColor DarkGray -NoNewline
    Write-Host "Crear TODOS" -ForegroundColor Green
    Write-Host "   [numero]. Crear uno especifico" -ForegroundColor DarkGray
    Write-Host "   0. Cancelar" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  + Opcion: " -ForegroundColor Cyan -NoNewline
    $eleccion = (Read-Host).Trim().ToUpper()

    if ($eleccion -eq "0") { return }

    $nombresArray = @($herramientas.Keys)
    $aCrear = @()

    if ($eleccion -eq "T") {
        $aCrear = $nombresArray
    } else {
        $num = 0
        if ([int]::TryParse($eleccion, [ref]$num) -and $num -ge 1 -and $num -le $nombresArray.Count) {
            $aCrear = @($nombresArray[$num - 1])
        } else {
            Write-Host "  Seleccion no valida." -ForegroundColor Red
            Pause-Menu
            return
        }
    }

    Write-Host ""
    $creados = 0
    foreach ($nombre in $aCrear) {
        $info   = $herramientas[$nombre]
        $lnkPath = Join-Path $escritorio "$nombre.lnk"

        try {
            $acceso = $shell.CreateShortcut($lnkPath)

            # Resolver ruta del ejecutable si es system32
            $exePath = $info.cmd
            if (-not [System.IO.Path]::IsPathRooted($exePath)) {
                $resolved = Get-Command $exePath -ErrorAction SilentlyContinue
                if ($resolved) { $exePath = $resolved.Source }
                else { $exePath = Join-Path $env:SystemRoot "System32\$($info.cmd)" }
            }

            $acceso.TargetPath       = $exePath
            $acceso.Arguments        = $info.args
            $acceso.WorkingDirectory = "$env:SystemRoot\System32"
            $acceso.WindowStyle      = 1
            $acceso.Save()

            Write-Host "  Creado: " -ForegroundColor DarkGray -NoNewline
            Write-Host $nombre -ForegroundColor Green
            $creados++
        } catch {
            Write-Host "  Error en '$nombre': $_" -ForegroundColor Red
        }
    }

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null

    Write-Host ""
    Write-Host "  $creados acceso(s) directo(s) creado(s) en el escritorio." -ForegroundColor Green
    Write-Host ""
    Pause-Menu
}

# =============================================================================

function Invoke-AjustesEnergia {
    do {
        Show-ModuleHeader "AJUSTES DE ENERGIA" "Yellow"

        # Plan activo
        $planActivo = & powercfg /getactivescheme 2>$null
        Write-Host "  Plan activo: " -ForegroundColor DarkGray -NoNewline
        Write-Host $planActivo -ForegroundColor Cyan
        Write-Host ""

        # Listar todos los planes
        Write-Host "  Planes de energia disponibles:" -ForegroundColor Cyan
        $planesRaw = & powercfg /list 2>$null
        $planes = $planesRaw | Where-Object { $_ -match "Esquema de energia" -or $_ -match "Power Scheme" }
        $i = 1
        $planesObj = @()
        foreach ($linea in $planes) {
            if ($linea -match "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})") {
                $guid   = $Matches[1]
                $nombre = ($linea -split "GUID:|guid:" )[-1].Trim()
                $nombre = ($nombre -split "\*")[0].Trim()
                $esActivo = if ($linea -match "\*") { " <- ACTIVO" } else { "" }
                $colorPlan = if ($esActivo) { "Green" } else { "White" }
                Write-Host "    [$i] " -ForegroundColor Yellow -NoNewline
                Write-Host "$nombre$esActivo" -ForegroundColor $colorPlan
                $planesObj += [PSCustomObject]@{ Num = $i; GUID = $guid; Nombre = $nombre }
                $i++
            }
        }

        Write-Host ""
        Show-Separator
        Write-Host ""

        Write-Host "   [num]  " -ForegroundColor DarkGray -NoNewline
        Write-Host "Activar plan de energia" -ForegroundColor Yellow
        Write-Host "   P     " -ForegroundColor DarkGray -NoNewline
        Write-Host "Configurar apagado de pantalla (minutos)" -ForegroundColor White
        Write-Host "   S     " -ForegroundColor DarkGray -NoNewline
        Write-Host "Configurar suspension del sistema (minutos)" -ForegroundColor White
        Write-Host "   H     " -ForegroundColor DarkGray -NoNewline
        Write-Host "Activar / Desactivar hibernacion" -ForegroundColor Yellow
        Write-Host "   0     " -ForegroundColor DarkGray -NoNewline
        Write-Host "Volver" -ForegroundColor Red
        Write-Host ""

        Write-Host "  + Opcion: " -ForegroundColor Cyan -NoNewline
        $sub = (Read-Host).Trim().ToUpper()

        switch ($sub) {
            "0" { break }

            "P" {
                Write-Host "  Minutos hasta apagar pantalla (0 = nunca): " -ForegroundColor Cyan -NoNewline
                $mins = (Read-Host).Trim()
                $segs = [int]$mins * 60
                & powercfg /change monitor-timeout-ac $mins 2>$null
                & powercfg /change monitor-timeout-dc $mins 2>$null
                Write-Host "  Pantalla configurada a $mins min." -ForegroundColor Green
                Start-Sleep -Seconds 1
            }

            "S" {
                Write-Host "  Minutos hasta suspension (0 = nunca): " -ForegroundColor Cyan -NoNewline
                $mins = (Read-Host).Trim()
                & powercfg /change standby-timeout-ac $mins 2>$null
                & powercfg /change standby-timeout-dc $mins 2>$null
                Write-Host "  Suspension configurada a $mins min." -ForegroundColor Green
                Start-Sleep -Seconds 1
            }

            "H" {
                $hibStatus = & powercfg /availablesleepstates 2>$null
                if ($hibStatus -match "Hibernar|Hibernate") {
                    Write-Host "  Desactivar hibernacion? [S/N]: " -ForegroundColor Cyan -NoNewline
                    if ((Read-Host).Trim().ToUpper() -eq "S") {
                        & powercfg /hibernate off 2>$null
                        Write-Host "  Hibernacion desactivada. (Libera espacio en disco)" -ForegroundColor Green
                    }
                } else {
                    Write-Host "  Activar hibernacion? [S/N]: " -ForegroundColor Cyan -NoNewline
                    if ((Read-Host).Trim().ToUpper() -eq "S") {
                        & powercfg /hibernate on 2>$null
                        Write-Host "  Hibernacion activada." -ForegroundColor Green
                    }
                }
                Start-Sleep -Seconds 1
            }

            default {
                $num = 0
                if ([int]::TryParse($sub, [ref]$num)) {
                    $plan = $planesObj | Where-Object { $_.Num -eq $num } | Select-Object -First 1
                    if ($plan) {
                        & powercfg /setactive $plan.GUID 2>$null
                        Write-Host "  Plan activado: " -ForegroundColor Green -NoNewline
                        Write-Host $plan.Nombre -ForegroundColor White
                    } else {
                        Write-Host "  Numero no valido." -ForegroundColor Red
                    }
                } else {
                    Write-Host "  Opcion no reconocida." -ForegroundColor Red
                }
                Start-Sleep -Seconds 1
            }
        }

    } while ($sub -ne "0")
}
