$baseUrl = "https://raw.githubusercontent.com/Manuelr2000/Soporte_auto/main/Soptec"
$installPath = "$env:LOCALAPPDATA\SoptecAuto"

Write-Host "=================================================" -ForegroundColor Yellow
Write-Host "  Instalador de Soptec" -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "  --> Creando carpeta de instalacion: $installPath"
New-Item -ItemType Directory -Path $installPath -Force | Out-Null

Write-Host "  --> Creando subcarpeta modules"
New-Item -ItemType Directory -Path "$installPath\modules" -Force | Out-Null

Write-Host "  --> Descargando soptec.ps1"
Invoke-WebRequest -Uri "$baseUrl/soptec.ps1" -OutFile "$installPath\soptec.ps1" -UseBasicParsing

Write-Host "  --> Descargando modules/diagnostico.ps1"
Invoke-WebRequest -Uri "$baseUrl/modules/diagnostico.ps1" -OutFile "$installPath\modules\diagnostico.ps1" -UseBasicParsing

Write-Host "  --> Descargando modules/reparacion.ps1"
Invoke-WebRequest -Uri "$baseUrl/modules/reparacion.ps1" -OutFile "$installPath\modules\reparacion.ps1" -UseBasicParsing

Write-Host "  --> Descargando modules/red.ps1"
Invoke-WebRequest -Uri "$baseUrl/modules/red.ps1" -OutFile "$installPath\modules\red.ps1" -UseBasicParsing

Write-Host "  --> Descargando modules/limpieza.ps1"
Invoke-WebRequest -Uri "$baseUrl/modules/limpieza.ps1" -OutFile "$installPath\modules\limpieza.ps1" -UseBasicParsing

Write-Host "  --> Descargando modules/reporte.ps1"
Invoke-WebRequest -Uri "$baseUrl/modules/reporte.ps1" -OutFile "$installPath\modules\reporte.ps1" -UseBasicParsing

Write-Host ""
Write-Host "  Descarga completada. Iniciando Soptec..." -ForegroundColor Green
Write-Host ""

& "$installPath\soptec.ps1"
