# Guía de migración — SDDM (tema Silent / dragon)

## Estructura del backup

```
sddm/
├── etc/sddm.conf.d/
│   ├── the_hyde_project.conf       ← configuración principal
│   └── backup_the_hyde_project.conf
└── themes/silent/                  ← tema activo
    ├── backgrounds/                ← fondos (incluye red-black-dragon.jpg)
    ├── components/                 ← componentes QML
    ├── configs/dragon.conf         ← perfil visual activo
    ├── Main.qml
    └── metadata.desktop            ← apunta a configs/dragon.conf
```

---

## 1. Dependencias

Instalar los paquetes necesarios (Arch / pacman):

```bash
sudo pacman -S sddm qt6-virtualkeyboard
```

> Para otras distros usar el gestor equivalente. El paquete clave además de `sddm` es el soporte de teclado virtual Qt6 (`qtvirtualkeyboard`).

### Fuente: Red Hat Display

El tema usa la fuente **RedHatDisplay**. Instalarla antes de arrancar SDDM:

```bash
# Opción A — desde AUR
yay -S ttf-redhat-fonts

# Opción B — manual
# Descargar desde https://github.com/RedHatOfficial/RedHatFont
# y copiar los .ttf a /usr/share/fonts/redhat/
sudo fc-cache -fv
```

---

## 2. Copiar el tema

```bash
sudo cp -r themes/silent /usr/share/sddm/themes/
sudo chown -R root:root /usr/share/sddm/themes/silent
```

---

## 3. Copiar la configuración

```bash
sudo cp etc/sddm.conf.d/the_hyde_project.conf /etc/sddm.conf.d/
```

> El archivo `backup_the_hyde_project.conf` es solo una copia de seguridad; no es necesario copiarlo salvo que quieras tenerlo de referencia.

Verificar que el contenido quedó correcto:

```bash
cat /etc/sddm.conf.d/the_hyde_project.conf
```

Debe mostrar:
```ini
[Theme]
Current=silent

[General]
InputMethod=qtvirtualkeyboard
GreeterEnvironment=QML2_IMPORT_PATH=/usr/share/sddm/themes/silent/components/,QT_IM_MODULE=qtvirtualkeyboard
```

---

## 4. Activar el servicio SDDM

```bash
# Deshabilitar el display manager anterior si hubiera uno
sudo systemctl disable gdm lightdm lxdm 2>/dev/null

# Habilitar e iniciar SDDM
sudo systemctl enable sddm
sudo systemctl start sddm
```

---

## 5. Verificar permisos

SDDM corre como root, pero el directorio del tema debe ser legible:

```bash
sudo chmod -R a+rX /usr/share/sddm/themes/silent
```

---

## 6. Probar el tema sin reiniciar

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/silent
```

> Si el comando no existe en la distro destino, puede ser `sddm-greeter --test-mode --theme ...` (versión Qt5).

---

## Notas adicionales

| Detalle | Valor |
|---|---|
| Tema activo | `silent` |
| Perfil visual | `configs/dragon.conf` (fondo `red-black-dragon.jpg`) |
| Teclado virtual | `qtvirtualkeyboard` vía Qt6 |
| Autologin | desactivado |
| UID range | 1000 – 60513 |

Para cambiar el perfil visual (colores, fondo), editar `metadata.desktop` del tema y apuntar `ConfigFile` al `.conf` deseado dentro de `configs/`.
