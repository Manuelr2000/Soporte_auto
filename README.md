# Soptec_auto

*Producto en beta*

Herramienta para facilitar los trabajos de soporte técnico y agilizar la respuesta a incidentes. 

Solo ejecuta el comando 

```Powershell
iwr https://raw.githubusercontent.com/Manuelr2000/Soporte_auto/main/Soptec/IWR.ps1 -useb | iex
```

Y luego tendrás una caja de herramientas de para la solución de problemas de primer nivel 

para esto vas a necesitar tener la ejecución de Scripts habilitado en la máquina del usuario.

```Powershell
Set-ExecutionPolicy -ExecutionPolicy unrestricted
```
Al terminar no olvides volver a habilitar la seguridad de ejecucon de scripts  

```Powershell
Set-ExecutionPolicy -ExecutionPolicy Restricted
```
