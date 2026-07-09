# Ejecutar como Administrador dentro de la VM de Windows
# Habilita RemoteApp para WinApps

# Habilitar RDP
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0

# Habilitar regla de firewall de Windows para RDP
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Deshabilitar allowlist de RemoteApp
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList" -Name "fDisabledAllowList" -Value 1 -Type DWord

# Permitir programas no listados en sesiones RDP
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "fAllowUnlistedRemotePrograms" -Value 1 -Type DWord

# Deshabilitar snap bar de Windows 11
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v EnableSnapBar /t REG_DWORD /d 0 /f

# Reiniciar servicio RDP para aplicar cambios
Restart-Service TermService -Force

Write-Host "Configuracion completada. Haz Sign Out (no Shutdown) antes de ejecutar el instalador de WinApps."
