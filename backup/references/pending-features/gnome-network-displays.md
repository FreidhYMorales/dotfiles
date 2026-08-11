# gnome-network-displays — Configuración Miracast en Hyprland + NVIDIA Optimus

Sistema: ArchLinux · Hyprland 0.54+ · NVIDIA GTX 1660 Ti + Intel UHD (Optimus) · Caelestia shell

---

## Dependencias a instalar

```bash
sudo pacman -S gnome-network-displays xdg-desktop-portal-wlr avahi pipewire-pulse
```

> **IMPORTANTE:** No instalar `pulseaudio`. Si yay/paru lo instala como dependencia de algún paquete AUR, revertir inmediatamente con:
> ```bash
> sudo pacman -S pipewire-pulse
> ```

---

## 1. Habilitar Avahi (descubrimiento de dispositivos)

```bash
sudo systemctl enable --now avahi-daemon
```

---

## 2. Regla polkit para FirewallD

Crear `/etc/polkit-1/rules.d/50-gnome-network-displays.rules`:

```bash
sudo tee /etc/polkit-1/rules.d/50-gnome-network-displays.rules << 'EOF'
polkit.addRule(function(action, subject) {
    if ((action.id == "org.fedoraproject.FirewallD1.all" ||
         action.id == "org.fedoraproject.FirewallD1.config" ||
         action.id == "org.fedoraproject.FirewallD1.policies") &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF
sudo systemctl restart polkit
```

---

## 3. Puerto WiFi P2P en FirewallD

```bash
sudo firewall-cmd --permanent --zone=home --add-port=7236/tcp
sudo firewall-cmd --permanent --zone=home --add-port=7236/udp
sudo firewall-cmd --reload
```

---

## 4. Backends del portal — arquitectura dual

Se usan dos backends según el output a transmitir:

| Output | Backend | Razón |
|--------|---------|-------|
| `eDP-1` (pantalla física) | `xdg-desktop-portal-wlr` | El portal hyprland falla en outputs físicos a 144Hz por agotamiento del pool de buffers wl_shm |
| `HEADLESS-1` (monitor virtual) | `xdg-desktop-portal-hyprland` | El portal wlr falla con `ext_image_copy_capture: duplicate frame` en outputs headless |

El script `nd-select-output` cambia ambos (output + backend) automáticamente.

### `~/.config/xdg-desktop-portal/hyprland-portals.conf`

Estado inicial (eDP-1 activo):
```ini
[preferred]
org.freedesktop.impl.portal.FileChooser=termfilechooser
org.freedesktop.impl.portal.ScreenCast=wlr
org.freedesktop.impl.portal.Screenshot=wlr
```

### `~/.config/xdg-desktop-portal-wlr/config`

```ini
[screencast]
output_name=eDP-1
chooser_type=none
max_fps=30
```

---

## 5. Variable de entorno NVIDIA screencopy

Añadir a `~/.config/hypr/hyprland/env.conf`:

```ini
# NVIDIA screencopy fix — lineal DMA-buf para pipewiresrc bajo NVIDIA+Hyprland
env = AQ_NO_MODIFIERS, 1
```

---

## 6. Override del .desktop de gnome-network-displays

Crear `~/.local/share/applications/org.gnome.NetworkDisplays.desktop`:

```ini
[Desktop Entry]
Name=GNOME Network Displays
Exec=env GDK_BACKEND=wayland gnome-network-displays
Icon=org.gnome.NetworkDisplays
Terminal=false
Type=Application
Categories=AudioVideo;
StartupNotify=true
```

> `GDK_BACKEND=wayland` es obligatorio. Sin él, GTK mezcla backends X11/Wayland y el audio falla al arrancar.

---

## 7. Servicio para pausar sddm-greeter (fix CPU al 99%)

El tema `silent` de SDDM reproduce un video en loop infinito que consume un núcleo de CPU incluso después del login. Este servicio lo pausa automáticamente.

### Script `/usr/local/bin/sddm-greeter-pause.sh`

```bash
sudo tee /usr/local/bin/sddm-greeter-pause.sh << 'EOF'
#!/bin/bash
until ls /run/user/1000/hypr/*/.socket.sock 2>/dev/null | grep -q .; do
    sleep 2
done
sleep 5
GREETER_PID=$(pgrep -f sddm-greeter-qt6)
[ -n "$GREETER_PID" ] && kill -STOP "$GREETER_PID"
exit 0
EOF
sudo chmod +x /usr/local/bin/sddm-greeter-pause.sh
```

> Si el UID del usuario no es 1000, ajustar la ruta `/run/user/1000/` al UID correcto.

### Servicio `/etc/systemd/system/sddm-greeter-pause.service`

```bash
sudo tee /etc/systemd/system/sddm-greeter-pause.service << 'EOF'
[Unit]
Description=Pause SDDM greeter after Hyprland login
After=sddm.service
Wants=sddm.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/sddm-greeter-pause.sh
RemainAfterExit=yes
TimeoutStartSec=120

[Install]
WantedBy=graphical.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable sddm-greeter-pause.service
```

---

## 8. Monitor virtual (HEADLESS-1) en workspace 6

Permite transmitir ventanas específicas sin mostrar la pantalla principal.

### Crear monitor virtual al inicio

Añadir a `~/.config/caelestia/hypr-user.conf`:

```ini
exec-once = hyprctl output create headless
monitor = HEADLESS-1, 1920x1080@60, 1600x0, 1
```

> La posición `1600x0` corresponde al ancho lógico de eDP-1 con scale 1.2 (1920/1.2 = 1600).

### Asignar workspace 6 al monitor virtual

Añadir a `~/.config/caelestia/hyprland/rule.conf`:

```ini
workspace = 6, monitor:HEADLESS-1, default:true
```

### Script de selección de output `~/.local/bin/nd-select-output`

Cambia automáticamente el output del portal y el backend según el monitor seleccionado:

```bash
#!/bin/bash
# Uso: nd-select-output [monitor_name]
# Sin argumento: alterna entre eDP-1 y el monitor virtual
WLR_CONFIG="$HOME/.config/xdg-desktop-portal-wlr/config"
PORTAL_CONFIG="$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"

HEADLESS=$(hyprctl monitors | grep "Monitor HEADLESS" | awk '{print $2}')

if [ -n "$1" ]; then
    SELECTED="$1"
else
    CURRENT=$(grep "^output_name=" "$WLR_CONFIG" | cut -d= -f2)
    if [ "$CURRENT" = "eDP-1" ]; then
        if [ -z "$HEADLESS" ]; then
            notify-send "Network Displays" "No hay monitor virtual activo" 2>/dev/null
            exit 1
        fi
        SELECTED="$HEADLESS"
    else
        SELECTED="eDP-1"
    fi
fi

sed -i "s/^output_name=.*/output_name=$SELECTED/" "$WLR_CONFIG"

if [ "$SELECTED" = "eDP-1" ]; then
    sed -i "s/org.freedesktop.impl.portal.ScreenCast=.*/org.freedesktop.impl.portal.ScreenCast=wlr/" "$PORTAL_CONFIG"
    sed -i "s/org.freedesktop.impl.portal.Screenshot=.*/org.freedesktop.impl.portal.Screenshot=wlr/" "$PORTAL_CONFIG"
    systemctl --user restart xdg-desktop-portal-wlr xdg-desktop-portal
else
    sed -i "s/org.freedesktop.impl.portal.ScreenCast=.*/org.freedesktop.impl.portal.ScreenCast=hyprland/" "$PORTAL_CONFIG"
    sed -i "s/org.freedesktop.impl.portal.Screenshot=.*/org.freedesktop.impl.portal.Screenshot=hyprland/" "$PORTAL_CONFIG"
    systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal
fi

notify-send "Network Displays" "Monitor: $SELECTED" 2>/dev/null
```

```bash
chmod +x ~/.local/bin/nd-select-output
```

---

## 9. Flujo de uso

### Transmitir pantalla completa (eDP-1)
1. `nd-select-output` → cambia a eDP-1 con backend wlr
2. `GDK_BACKEND=wayland gnome-network-displays` → conectar al TV

### Transmitir ventana específica (HEADLESS-1)
1. `nd-select-output` → cambia a HEADLESS-1 con backend hyprland
2. `GDK_BACKEND=wayland gnome-network-displays` → conectar al TV
3. El TV muestra el wallpaper de HEADLESS-1
4. `Super+Alt+6` sobre la ventana que quieras transmitir → aparece en el TV
5. `Super+Alt+1` para recuperar la ventana de vuelta

---

## 10. Verificación final

```bash
# Avahi corriendo
systemctl is-active avahi-daemon

# pipewire-pulse (no pulseaudio)
pacman -Q pipewire-pulse

# Portal wlr activo
systemctl --user is-active xdg-desktop-portal-wlr

# sddm-greeter-pause habilitado
systemctl is-enabled sddm-greeter-pause.service

# Monitor virtual presente
hyprctl monitors | grep HEADLESS
```

---

## Notas de uso

- Lanzar siempre desde el .desktop o con `GDK_BACKEND=wayland gnome-network-displays`
- El TV LG solo soporta Miracast en **2.4GHz** — latencia inherente de 100-300ms
- Si la app se traba al cerrar (`double free or corruption`): es un bug conocido de gnome-network-displays 0.99 en `nd_pulseaudio_finalize`, no afecta el streaming
- Si la transmisión es poco fluida al conectar: cerrar y reconectar mejora el buffering inicial
- El encoder usado es **x264 por software** (sin hardware encoding disponible — `gst-plugins-bad` en Arch no incluye el plugin VA, y NVENC no está soportado por gnome-network-displays 0.99)

---

## Nota futura — Backend único con perfiles de nwg-displays

Se investigó si bajar el refresh rate de eDP-1 a 60Hz (mediante un perfil de nwg-displays para streaming) permitiría usar `xdg-desktop-portal-hyprland` como backend único para ambos outputs. El resultado fue negativo:

- Con pantalla estática a 60Hz: conecta pero la imagen se congela (no fluye video)
- Con contenido activo a 60Hz: falla igual que a 144Hz por agotamiento de buffers

El bug raíz está en que durante la negociación WFD (RTSP setup), el pipeline GStreamer entra en estado PAUSED y pipewiresrc retiene todos los buffers del pool. En outputs físicos con contenido dinámico (cursor, animaciones de Caelestia), el compositor sigue generando frames que no pueden ser escritos, agotando el pool independientemente de los Hz.

**Si en el futuro se encuentra una solución** (aumento del pool de buffers en PipeWire, fix upstream en xdg-desktop-portal-hyprland, o cambio en el mecanismo de negociación WFD), el perfil de nwg-displays sería:
```ini
# ~/.config/hypr/monitors-streaming.conf
monitor=eDP-1,1920x1080@60.0,0x0,1.2000000000000002
```
Y se activaría con:
```bash
cp ~/.config/hypr/monitors-streaming.conf ~/.config/hypr/monitors.conf
hyprctl reload
```

---

## Bugs conocidos en v0.99.0

| Bug | Causa | Estado |
|-----|-------|--------|
| Crash `double free` al salir | `nd_pulseaudio_finalize` doble liberación | Upstream, sin fix en 0.99 |
| `codec list not initialized` | Inicialización de codec antes de escaneo | Upstream, solo warning |
| `Avahi service: Timeout reached` | mDNS timeout para discovery alternativo | Inofensivo |
| `ext_image_copy_capture: duplicate frame` en headless | Bug en implementación de Hyprland para outputs virtuales con portal wlr | Workaround: usar portal hyprland para headless |
