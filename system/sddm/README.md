# system/sddm

Config de SDDM para `/etc/sddm.conf.d/`. No es un paquete Stow: `dotfiles/bootstrap.sh` (paso 24) automatiza todo lo de acá abajo en cada instalación. Esta guía es solo referencia/troubleshooting manual.

El greeter es `notch-lock`, el tema SDDM del notch shell. Vive en el repo del notch (`dotfiles/quickshell/.config/quickshell/notch-repo/sddm/notch/`, con su propio `README.md` para previsualizarlo); acá solo queda cómo se deploya.

## 1. Dependencias

```bash
sudo pacman -S sddm qt6-virtualkeyboard
```

## 2. Directorio compartido del greeter

El notch publica el wallpaper actual y la paleta de matugen a un directorio del usuario que el grupo `sddm` puede leer (setgid, así los archivos nuevos heredan el grupo):

```bash
sudo install -d -o "$USER" -g sddm -m 2750 /var/lib/quickshell-notch-sddm
sudo install -o "$USER" -g sddm -m 640 /dev/null /var/lib/quickshell-notch-sddm/theme.conf.user
mkdir -p ~/.local/state/quickshell-notch
echo /var/lib/quickshell-notch-sddm >~/.local/state/quickshell-notch/sddm-target.txt
```

## 3. Instalar notch-lock

```bash
N=dotfiles/quickshell/.config/quickshell/notch-repo
sudo python3 "$N/scripts/install-sddm-theme.py" /usr/share/sddm/themes /var/lib/quickshell-notch-sddm
```

El instalador nunca reemplaza un tema ya instalado. Para actualizarlo: `sudo python3 "$N/scripts/update-sddm-theme.py" /usr/share/sddm/themes /var/lib/quickshell-notch-sddm` (guarda el anterior en `notch-lock-backup/`).

## 4. Copiar la configuración

```bash
sudo mkdir -p /etc/sddm.conf.d
sudo cp system/sddm/sddm.conf.d/deadlock.conf /etc/sddm.conf.d/
```

`deadlock.conf` selecciona `Current=notch-lock` e incluye `QT_SCREEN_SCALE_FACTORS=eDP-1=2`, que debe coincidir a mano con la escala de `dotfiles/hypr/.config/hypr/monitors.lua` (SDDM arranca antes que Hyprland, no puede leer ese archivo).

## 5. Activar el servicio

```bash
sudo systemctl enable sddm
```

## 6. Si el greeter no carga

El paquete `sddm` trae temas de fábrica (`elarun`, `maldives`, `maya`): cambiar `Current=` a uno de ellos en `/etc/sddm.conf.d/deadlock.conf` desde una TTY recupera el login.

## Notas

| Detalle | Valor |
|---|---|
| Tema activo | `notch-lock` |
| Datos del greeter | `/var/lib/quickshell-notch-sddm/` (publicados por el notch) |
| Config SDDM | `/etc/sddm.conf.d/deadlock.conf` |
| Teclado virtual | `qtvirtualkeyboard` vía Qt6 |
| Autologin | desactivado |
| UID range | 1000 – 60513 |
