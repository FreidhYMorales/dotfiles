# system/sddm

Tema SDDM [Silent](https://github.com/uiriansan/SilentSDDM) + config, para `/usr/share/sddm/themes/` y `/etc/sddm.conf.d/`. No es un paquete Stow — `dotfiles/bootstrap.sh` (paso 24) ya automatiza todo lo de acá abajo en cada instalación. Esta guía es solo referencia/troubleshooting manual, por si algo falla o hace falta reinstalar el tema a mano sin correr el bootstrap completo.

`themes/silent/README.md` es la documentación propia del tema upstream (presets, showcases) — no la dupliques acá, esto es solo sobre cómo queda deployado en este repo.

## 1. Dependencias

```bash
sudo pacman -S sddm qt6-virtualkeyboard
```

## 2. Copiar el tema

```bash
sudo cp -r system/sddm/themes/silent /usr/share/sddm/themes/
sudo chown -R root:root /usr/share/sddm/themes/silent
sudo chmod -R a+rX /usr/share/sddm/themes/silent
```

## 3. Copiar la configuración

```bash
sudo mkdir -p /etc/sddm.conf.d
sudo cp system/sddm/sddm.conf.d/deadlock.conf /etc/sddm.conf.d/
```

`deadlock.conf` incluye `QT_SCREEN_SCALE_FACTORS=eDP-1=2` — debe coincidir a mano con la escala configurada en `dotfiles/hypr/.config/hypr/monitors.conf` (SDDM arranca antes que Hyprland, no puede leer ese archivo). Si cambia la escala del monitor, actualizar acá también.

## 4. Perfil visual activo

`themes/silent/metadata.desktop` → `ConfigFile=configs/custom.conf`. `custom.conf` **no** es estático — lo reescribe `sddm-theme-sync` (helper privilegiado, ver más abajo) cada vez que corre matugen, con los colores del wallpaper actual. El bootstrap lo bootstrapea al `default.conf` de fábrica en la primera instalación (antes del primer run real de matugen).

## 5. Activar el servicio

```bash
sudo systemctl enable sddm
sudo systemctl start sddm
```

## 6. Probar el tema sin reiniciar

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/silent
```

## 7. Theming dinámico (matugen)

`sddm-theme-sync` (`/usr/local/bin/`, instalado por el bootstrap con una entrada `sudoers` para correr sin password) escribe `configs/custom.conf` y copia el wallpaper actual a `backgrounds/qs-current.<ext>` — se llama desde el post-hook de matugen (`~/.config/matugen/post-hook.sh`), no hay que correrlo a mano.

## Notas

| Detalle | Valor |
|---|---|
| Tema activo | `silent` |
| Perfil visual | `configs/custom.conf` (dinámico, matugen) |
| Config SDDM | `/etc/sddm.conf.d/deadlock.conf` |
| Teclado virtual | `qtvirtualkeyboard` vía Qt6 |
| Autologin | desactivado |
| UID range | 1000 – 60513 |
