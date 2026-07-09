# Kitty — Guía de Migración / Reinstalación

## Estructura de archivos versionados

```
Files/Configuraciones/
├── kitty/
│   ├── kitty.conf                    ← configuración principal (symlinkada a ~/.config/kitty)
│   ├── theme.conf                    ← tema estático de respaldo (usado si caelestia no existe)
│   ├── install.sh                    ← script de instalación automatizado
│   └── SETUP.md                      ← este archivo
├── caelestia/
│   ├── templates/
│   │   └── kitty-theme.conf          ← template dinámico de caelestia
│   └── scripts/
│       └── kitty-theme-reload.sh     ← aplica colores a kitty en vivo via kitten @
└── systemd/
    ├── kitty-theme-reload.path       ← vigilancia del archivo generado
    └── kitty-theme-reload.service    ← dispara el script al detectar cambio
```

Archivos generados (no versionar):
```
~/.local/state/caelestia/theme/kitty-theme.conf   ← generado por caelestia en cada cambio de esquema
```

---

## Instalación en sistema nuevo

```bash
bash ~/Files/Configuraciones/kitty/install.sh
```

El script crea todos los symlinks, habilita el path unit y genera el tema inicial.
Reiniciar kitty una vez tras la instalación.

---

## Cómo funciona el tema dinámico

1. Al cambiar esquema con `caelestia scheme set ...`, caelestia procesa
   `~/.config/caelestia/templates/kitty-theme.conf` y escribe el resultado en
   `~/.local/state/caelestia/theme/kitty-theme.conf`.
2. Caelestia envía OSC sequences a `/dev/pts/*` → colores del terminal en vivo.
3. El path unit detecta el archivo generado → dispara el service →
   `kitty-theme-reload.sh` conecta a cada socket de kitty via `kitten @` →
   tab bars, bordes y UI de kitty se actualizan en vivo.
4. Nuevas ventanas de kitty leen el archivo generado directamente desde `kitty.conf`.

### Sistema de fallback

`kitty.conf` incluye dos archivos en orden:
```
include theme.conf                                          ← colores estáticos base
include ~/.local/state/caelestia/theme/kitty-theme.conf    ← override dinámico de caelestia
```
Si caelestia no está instalado o no ha generado su archivo, `theme.conf` garantiza
que kitty siempre tenga colores funcionales.

---

## Dependencias

| Paquete | Motivo |
|---|---|
| `kitty` | terminal |
| `caelestia` | gestor de esquemas de color |
| `ttf-iosevka-term-nerd` | fuente: IosevkaTerm Nerd Font Mono |

---

## Líneas clave en kitty.conf

```
allow_remote_control socket-only         ← habilita kitten @ desde scripts externos
listen_on unix:/tmp/kitty-{kitty_pid}    ← crea socket por instancia de kitty
```

Sin estas dos líneas, el script de recarga en vivo no puede conectarse a kitty.

---

## Verificación manual

```bash
# Tema generado correctamente
cat ~/.local/state/caelestia/theme/kitty-theme.conf

# Path unit activo
systemctl --user status kitty-theme-reload.path

# Sockets de kitty disponibles
ls /tmp/kitty-*

# Probar recarga manual
~/.config/caelestia/scripts/kitty-theme-reload.sh
```
