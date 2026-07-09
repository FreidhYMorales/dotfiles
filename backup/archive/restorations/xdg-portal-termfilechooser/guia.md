# xdg-desktop-portal-termfilechooser con Yazi

Selector de archivos en terminal usando yazi, integrado via XDG portal.
Entorno: Arch Linux + Hyprland + HyDE Project + Kitty.
Estado: **verificado y funcionando** (apps GTK y Qt).

---

## Paquete

```bash
yay -S xdg-desktop-portal-termfilechooser-hunkyburrito-git
```

---

## Archivos de configuración

### 1. `~/.config/xdg-desktop-portal-termfilechooser/config`

```ini
[filechooser]
cmd=yazi-wrapper.sh
default_dir=$HOME
env=TERMCMD=/usr/bin/kitty --title termfilechooser
open_mode=suggested
save_mode=last
```

**Notas importantes:**
- Usar ruta absoluta para el terminal (`/usr/bin/kitty`), no solo `kitty`, para evitar problemas de PATH en el servicio.
- No usar comillas dobles en el valor de `env=` — el parser INI las trata como corruptas y descarta la línea.
- El archivo debe ser propiedad del usuario (`chown deadlock:deadlock config`), no de root.

### 2. `~/.config/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh`

Copiar desde el paquete:

```bash
cp /usr/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh \
   ~/.config/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
chmod +x ~/.config/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
```

### 3. `~/.config/xdg-desktop-portal/hyprland-portals.conf`

Agregar la línea de FileChooser a la sección `[preferred]`:

```ini
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.ScreenCast=hyprland
org.freedesktop.impl.portal.Screenshot=hyprland
org.freedesktop.impl.portal.FileChooser=termfilechooser
```

---

## Integración con HyDE

HyDE no inicia `xdg-desktop-portal-termfilechooser` por defecto. Se resuelve en dos lugares:

### 4. `~/.config/hypr/userprefs.conf`

Agregar al inicio del archivo (este archivo no lo sobreescribe HyDE):

```ini
exec-once = /usr/lib/xdg-desktop-portal-termfilechooser

# Forzar uso del XDG portal para selectores de archivos
env = GTK_USE_PORTAL, 1
env = QT_QPA_PLATFORMTHEME, xdgdesktopportal
```

**Notas:**
- `GTK_USE_PORTAL=1` fuerza a las apps GTK a usar el portal en lugar de su dialog nativo.
- `QT_QPA_PLATFORMTHEME=xdgdesktopportal` hace que las apps Qt usen el portal para file dialogs. Esto overridea el valor `qt6ct` que pone HyDE porque `userprefs.conf` se carga después. El estilo visual (Kvantum) se mantiene al estar configurado por separado.
- Sin estas variables, la mayoría de apps nativas ignoran el portal y usan sus propios dialogs (GTK nativo, o kdialog de kde-cli-tools en el caso de Qt).

### 5. `~/.local/lib/hyde/resetxdgportal.sh`

Agregar termfilechooser al script de reset de portales:

```bash
app2unit.sh -t service $libDir/xdg-desktop-portal-hyprland
sleep 1
app2unit.sh -t service $libDir/xdg-desktop-portal-termfilechooser &  # <-- agregar
app2unit.sh -t service $libDir/xdg-desktop-portal &
```

---

## Uso en yazi

- **Confirmar selección:** `Enter`
- **Abortar:** `Q` (mayúscula)

---

## Verificación

```bash
GDK_DEBUG=portals zenity --file-selection
```

Debe abrir kitty con yazi como selector de archivos.

Para debug si algo falla:

```bash
killall xdg-desktop-portal-termfilechooser 2>/dev/null
/usr/lib/xdg-desktop-portal-termfilechooser -lDEBUG 2>&1 &
# En otra terminal:
zenity --file-selection
```
