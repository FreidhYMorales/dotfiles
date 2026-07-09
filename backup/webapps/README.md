# webapps

Web apps como launchers nativos usando el modo `--app` de Chromium. Sin barra de tabs, sin UI del browser.

## Deps

Un browser Chromium-based instalado (Brave, Chrome, Chromium). Si el browser default no es Chromium-based, fallbackea a `chromium.desktop`.

## Instalar

```bash
ln -sf ~/Files/Configuraciones/webapps/scripts/webapp-launch  ~/.local/bin/
ln -sf ~/Files/Configuraciones/webapps/scripts/webapp-install ~/.local/bin/
ln -sf ~/Files/Configuraciones/webapps/scripts/webapp-remove  ~/.local/bin/
```

## Restaurar todas las apps (sistema nuevo)

```bash
~/Files/Configuraciones/webapps/restore
```

Lee el archivo `apps`, descarga íconos via Google Favicons y crea los `.desktop` en `~/.local/share/applications/`. Saltea las que ya existen.

## Uso

```bash
webapp-install                          # modo interactivo (pide nombre, URL)
webapp-install "Notion" "https://notion.so"               # scripteable
webapp-install "App" "https://app.com" "https://icon.png" # con ícono custom
webapp-remove                           # picker interactivo
webapp-launch https://youtube.com/      # lanzar directamente
```

## Agregar una app nueva

Añadirla al archivo `apps`:
```
Mi App | https://miapp.com
```
Luego correr `restore` o `webapp-install` manualmente.

## Apps instaladas

Ver archivo `apps` para la lista completa.
