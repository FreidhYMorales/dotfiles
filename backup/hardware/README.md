# Hardware — Configuración de componentes

Laptop: **Intel i7-10750H + NVIDIA GTX 1660 Ti Mobile (híbrida)**

---

## GPU — NVIDIA Optimus / PRIME

### Dispositivos DRM (este sistema)

```
card1  → NVIDIA GTX 1660 Ti Mobile  (pci-0000:01:00.0)  renderD128
card2  → Intel UHD Graphics          (pci-0000:00:02.0)  renderD129
```

La numeración está invertida respecto a lo típico porque el Thunderbolt 3 (JHL7540)
ocupa el slot 0 durante el boot. No es un error — es la enumeración del kernel.

### Driver instalado

```
nvidia-open-dkms   — módulo open source (correcto para Turing: GTX 16xx, RTX 20xx+)
nvidia-utils
lib32-nvidia-utils
```

### Modprobe — `/etc/modprobe.d/nvidia.conf`

**Actual (incompleto):**
```
options nvidia_drm modeset=1
```

**Recomendado (agregar `fbdev=1` y power management):**
```
options nvidia_drm modeset=1 fbdev=1
options nvidia NVreg_DynamicPowerManagement=0x02
```

- `fbdev=1` — habilita framebuffer para la consola (TTY). Sin esto el TTY queda negro al salir de Hyprland.
- `NVreg_DynamicPowerManagement=0x02` — fine-grained power management: la GPU entra en D3cold cuando está inactiva (ahorra batería significativamente en laptop).

**Aplicar:** `sudo nano /etc/modprobe.d/nvidia.conf` → agregar las líneas → reiniciar.

### Variables de entorno Hyprland (ya configuradas)

Ubicación: `~/.config/hypr/hyprland/envs.conf`

```
env = NVD_BACKEND,direct              # VA-API directo (requiere nvidia-vaapi-driver)
env = LIBVA_DRIVER_NAME,nvidia        # VA-API usa NVIDIA
env = __GLX_VENDOR_LIBRARY_NAME,nvidia # GLX usa NVIDIA
env = AQ_NO_MODIFIERS,1              # fix screencopy bajo NVIDIA+Hyprland
```

`AQ_NO_MODIFIERS=1` es el fix más importante para esta configuración — sin él
las capturas de pantalla y el screen sharing fallan bajo Wayland+NVIDIA.

### Modo de renderizado actual

El setup actual usa **NVIDIA como renderer principal** de Hyprland.
Pros: rendimiento consistente, sin overhead de offload.
Contras: mayor consumo de batería.

**Alternativa (Intel como primario, NVIDIA como offload):**
```
# En hyprland/envs.conf, reemplazar por:
env = AQ_DRM_DEVICES,/dev/dri/card2   # usar Intel como primario
# Luego lanzar apps que necesiten GPU con:
# prime-run <app>  o  DRI_PRIME=1 <app>
```

### Diagnóstico útil

```bash
# Verificar que NVIDIA está activo en Hyprland
hyprctl monitors -j | jq '.[].name'

# Ver GPU en uso por una ventana
cat /proc/$(pidof hyprland)/maps | grep nvidia

# Verificar VA-API con NVIDIA
vainfo 2>/dev/null | grep -i nvidia

# Ver consumo de energía de la GPU
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
# "suspended" = GPU apagada (ahorrando batería) / "active" = en uso
```

---

## CPU — Intel i7-10750H

- 6 núcleos, 12 hilos
- Base 2.6 GHz, Boost hasta 5.0 GHz
- TDP: 45W

### Power management (ya configurado)

```
power-profiles-daemon  ← activo, controla el governor automáticamente
thermald               ← activo, protección térmica
```

Perfiles disponibles:
```bash
powerprofilesctl list           # ver perfiles
powerprofilesctl set balanced   # balanced / power-saver / performance
```

El governor actual (`powersave`) es gestionado por `power-profiles-daemon` — no cambiarlo manualmente.

### Optimizaciones opcionales

```bash
# Ver temperatura de CPUs en tiempo real
watch -n1 sensors

# Configurar sensores (una vez por sistema)
sudo sensors-detect

# Si querés governor más agresivo para compile/gaming:
powerprofilesctl set performance
# Volver a balanceado:
powerprofilesctl set balanced
```

---

## WiFi — Intel CNVi (ax201)

Chipset Intel Wi-Fi 6 AX201, controlado por `iwlwifi`.

```bash
# Si hay disconnects o problemas de power save:
sudo iw dev wlan0 set power_save off
# O persistente en /etc/modprobe.d/iwlwifi.conf:
# options iwlwifi power_save=0
```

---

## Thunderbolt 3 — JHL7540 (Titan Ridge)

Para autorizar dispositivos Thunderbolt (docks, monitores externos):

```bash
sudo pacman -S bolt
systemctl enable --now bolt
boltctl list           # ver dispositivos
boltctl enroll <uuid>  # autorizar dispositivo
```

---

## Batería

Scripts en `hardware/scripts/`:
- `battery-remaining` — porcentaje como entero (para widgets)
- `battery-time` — tiempo restante formateado (ej. "2h 15m")
- `battery-status` — línea completa con %, tiempo y watts

Deps: `upower` (ya instalado)

---

## Brillo

Scripts en `hardware/scripts/`:
- `brightness-display` — ajuste de brillo de pantalla con SwayOSD
- `brightness-keyboard` — ajuste de retroiluminación de teclado con SwayOSD

Deps: `brightnessctl`, `swayosd` (ya instalados)

```bash
ln -sf ~/Files/Configuraciones/hardware/scripts/brightness-display  ~/.local/bin/
ln -sf ~/Files/Configuraciones/hardware/scripts/brightness-keyboard ~/.local/bin/
ln -sf ~/Files/Configuraciones/hardware/scripts/battery-remaining   ~/.local/bin/
ln -sf ~/Files/Configuraciones/hardware/scripts/battery-time        ~/.local/bin/
ln -sf ~/Files/Configuraciones/hardware/scripts/battery-status      ~/.local/bin/
```

Bindings sugeridos en Hyprland:
```
binde = , XF86MonBrightnessUp,   exec, brightness-display +5%
binde = , XF86MonBrightnessDown, exec, brightness-display 5%-
binde = , XF86KbdBrightnessUp,   exec, brightness-keyboard up
binde = , XF86KbdBrightnessDown, exec, brightness-keyboard down
binde = SHIFT, XF86KbdBrightnessUp, exec, brightness-keyboard cycle
```
