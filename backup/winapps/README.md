# WinApps — Guía de instalación y migración

Microsoft Excel (y Office 365 completo) como apps nativas en Arch Linux + Hyprland vía KVM/RDP.

## Requisitos del sistema

- CPU Intel con VT-x (módulo `kvm_intel`) o AMD con AMD-V (`kvm_amd`)
- RAM: 16GB mínimo (se asignan 8GB a la VM)
- OS: Arch Linux con Hyprland/Wayland
- ISO de Windows 11 Pro (evaluación o licencia)
- Cuenta Microsoft 365 para activar Office

---

## Paso 1 — Instalar dependencias

```bash
sudo pacman -S qemu-full libvirt virt-manager freerdp dnsmasq swtpm netcat openbsd-netcat
```

---

## Paso 2 — Servicios libvirt (arquitectura modular)

```bash
# NO usar libvirtd (legacy). Usar daemons modulares:
sudo systemctl enable --now virtqemud virtqemud.socket
sudo systemctl enable --now virtnetworkd virtnetworkd.socket
sudo systemctl enable --now virtstoraged virtstoraged.socket
sudo systemctl enable --now virtnodedevd virtnodedevd.socket
sudo systemctl enable --now virtsecretd virtsecretd.socket
```

---

## Paso 3 — Red virtual libvirt

```bash
sudo virsh -c qemu:///system net-start default
sudo virsh -c qemu:///system net-autostart default
```

### Firewalld: zona libvirt

```bash
sudo cp libvirt-firewalld-zone.xml /etc/firewalld/zones/libvirt.xml
sudo firewall-cmd --reload

# Reiniciar red para asignar virbr0 a la zona libvirt
sudo virsh -c qemu:///system net-destroy default
sudo virsh -c qemu:///system net-start default
```

### Firewalld: política NAT para internet en la VM

```bash
sudo firewall-cmd --permanent --new-policy libvirt-to-public
sudo firewall-cmd --permanent --policy libvirt-to-public --add-ingress-zone libvirt
sudo firewall-cmd --permanent --policy libvirt-to-public --add-egress-zone public
sudo firewall-cmd --permanent --policy libvirt-to-public --set-target ACCEPT
sudo firewall-cmd --permanent --policy libvirt-to-public --add-masquerade
sudo firewall-cmd --reload
```

### nftables: permitir forwarding desde virbr0

Agregar en `/etc/nftables.conf` dentro de `chain forward`:

```nft
# VMs libvirt (virbr0)
iifname "virbr0" accept
oifname "virbr0" ct state established,related accept
```

---

## Paso 4 — Grupos de usuario

```bash
sudo usermod -aG libvirt,kvm TU_USUARIO
# CERRAR SESIÓN COMPLETAMENTE y volver a entrar
```

---

## Paso 5 — Variable de entorno libvirt

Agregar en `~/.config/caelestia/hypr-user.conf`:

```ini
env = LIBVIRT_DEFAULT_URI, qemu:///system
```

Y en `~/.zshrc`:

```bash
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

---

## Paso 6 — Crear la VM en virt-manager

1. Nueva VM → Local install media (ISO)
2. Seleccionar ISO de Windows 11
3. RAM: **8192 MiB**, CPUs: **4**
4. Disco: **64 GiB** (qcow2)
5. Nombre: **`WinApps`** (exacto, case-sensitive)
6. Activar "Customize configuration before install"
7. Overview → Firmware: `UEFI x86_64: /usr/share/edk2/x64/OVMF_CODE.secboot.fd`
8. Add Hardware → TPM → Emulated, CRB, version 2.0
9. Begin Installation

### Durante la instalación de Windows:

- "I don't have a product key"
- Edición: **Windows 11 Pro** (no Home)
- Tipo: Custom install
- Para omitir cuenta Microsoft: `Shift+F10` → ejecutar:
    ```cmd
    reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f
    shutdown /r /t 0
    ```

---

## Paso 7 — Configurar red estática en Windows

El adaptador es **VirtIO** (Red Hat VirtIO Ethernet Adapter). En PowerShell como administrador:

```powershell
# Obtener índice del adaptador
Get-NetAdapter

# Sustituir 17 por el índice real
New-NetIPAddress -InterfaceIndex 17 -IPAddress 192.168.122.100 -PrefixLength 24 -DefaultGateway 192.168.122.1
Set-DnsClientServerAddress -InterfaceIndex 17 -ServerAddresses 8.8.8.8,192.168.122.1
```

> **Nota**: El modelo del NIC debe ser `virtio` en virt-manager. Requiere instalar los drivers virtio-win primero (ver Paso 11) si es una instalación nueva. Alternativamente, usar `e1000e` inicialmente y cambiar a `virtio` después.

---

## Paso 8 — Instalar Microsoft 365

Dentro de Windows, ir a `office.com` con la cuenta estudiantil e instalar Microsoft 365.

---

## Paso 9 — Configurar RDP y registro de Windows

En Windows, ejecutar `RDPApps.ps1` como administrador (incluido en este directorio).

Luego hacer **Sign Out** (no Shutdown).

---

## Paso 10 — Instalar WinApps

```bash
git clone https://github.com/winapps-org/winapps.git ~/winapps

# Copiar configuración
mkdir -p ~/.config/winapps
cp winapps.conf ~/.config/winapps/winapps.conf

# Instalar
bash ~/winapps/setup.sh
# Opciones: Install → Current User → Automatic
```

### Agregar sesión de escritorio Windows al launcher:

```bash
cp windows.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/
```

### Eliminar apps no-Office del launcher:

```bash
rm ~/.local/share/applications/{cmd,explorer,iexplorer,powershell,powershell-ide}.desktop
update-desktop-database ~/.local/share/applications/
```

---

## Paso 11 — Drivers VirtIO (optimización)

```bash
wget -P ~/Downloads https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
```

En virt-manager: adjuntar ISO como CDROM → dentro de Windows instalar `virtio-win-gt-x64.msi` → cambiar NIC a `virtio` en virt-manager → reasignar IP estática.

---

## Paso 12 — Snapshot de respaldo

```bash
virsh -c qemu:///system snapshot-create-as WinApps "limpio-office365" --description "Windows 11 Pro + Office 365 + VirtIO" --disk-only --atomic
```

Para restaurar:

```bash
virsh -c qemu:///system snapshot-revert WinApps limpio-office365
```

---

## Configuración actual

| Parámetro         | Valor                                     |
| ----------------- | ----------------------------------------- |
| VM Name           | WinApps                                   |
| IP VM             | 192.168.122.100                           |
| Usuario Windows   | Deadlock                                  |
| NIC VM            | VirtIO                                    |
| RDP Scale         | dinámico (100/140/180 según monitor)      |
| Autopause         | 1 minuto                                  |
| Files compartidos | `/home/deadlock` y `/home/deadlock/Files` |

## Archivos en este directorio

| Archivo                      | Descripción                                            |
| ---------------------------- | ------------------------------------------------------ |
| `winapps.conf`               | Configuración principal de WinApps                     |
| `libvirt-firewalld-zone.xml` | Zona firewalld para libvirt                            |
| `RDPApps.ps1`                | Script PowerShell para configurar RDP en Windows       |
| `scripts/windows-launch`     | Wrapper que detecta el scale del monitor antes de lanzar WinApps. Instalar en PATH (`~/.local/bin/`) |
| `windows.desktop`            | Entrada del launcher para sesión de escritorio Windows |
| `README.md`                  | Esta guía                                              |
