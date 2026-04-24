$ProgressPreference = 'SilentlyContinue'
$baseUrl = "https://raw.githubusercontent.com/Manuelr2000/Soporte_auto/main/Soptec"
$installPath = "$env:LOCALAPPDATA\SoptecAuto"

New-Item -ItemType Directory -Path $installPath -Force | Out-Null
New-Item -ItemType Directory -Path "$installPath\modules" -Force | Out-Null

Invoke-WebRequest -Uri "$baseUrl/soptec.ps1" -OutFile "$installPath\soptec.ps1" -UseBasicParsing
Invoke-WebRequest -Uri "$baseUrl/modules/diagnostico.ps1" -OutFile "$installPath\modules\diagnostico.ps1" -UseBasicParsing
Invoke-WebRequest -Uri "$baseUrl/modules/reparacion.ps1" -OutFile "$installPath\modules\reparacion.ps1" -UseBasicParsing
Invoke-WebRequest -Uri "$baseUrl/modules/red.ps1" -OutFile "$installPath\modules\red.ps1" -UseBasicParsing
Invoke-WebRequest -Uri "$baseUrl/modules/limpieza.ps1" -OutFile "$installPath\modules\limpieza.ps1" -UseBasicParsing
Invoke-WebRequest -Uri "$baseUrl/modules/reporte.ps1" -OutFile "$installPath\modules\reporte.ps1" -UseBasicParsing

& "$installPath\soptec.ps1"
