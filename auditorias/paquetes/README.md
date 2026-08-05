# Auditoría — Paquetes y aplicaciones instaladas

**Fecha:** 2026-08-05
**Alcance:** paquetes explícitos instalados en esta máquina vs. lo que `bootstrap.sh` realmente reproduce, dependencias de binarios en `dotfiles/scripts/`, y recomendaciones de apps nuevas para el stack.
**Máquina de esta sesión:** ThinkPad X1 Carbon Gen 13 (Core Ultra 200V "Lunar Lake", Arc Graphics integrada — confirmado con `lspci`, un solo GPU Intel). **No es** la Dell Intel+AMD que `CLAUDE.md` documenta como máquina principal — importante tenerlo en cuenta al leer los hallazgos de GPU más abajo.
**Estado:** cerrada de punta a punta — §1, §2 y §3 (incluidos los opcionales `atuin`/`bandwhich` y `herdr-bin`) resueltos.

---

## 0. Metodología

Todo verificado contra el sistema real, no asumido desde `bootstrap.sh`:
- `pacman -Qe` (explícitos, nativos+AUR) y `pacman -Qm` (origen AUR) para el inventario real
- `pacman -Qi <pkg>` → campo `Install Reason` para distinguir "explícito a mano" de "instalado como dependencia"
- Extracción programática de todos los `pacman -S`/`yay -S` de `dotfiles/bootstrap.sh` (incluyendo continuaciones de línea con `\`), diffeada contra el inventario real
- `lspci`, `hostnamectl` para confirmar hardware real de esta sesión
- Lectura completa de los 19 scripts en `dotfiles/scripts/.local/bin/` para extraer binarios invocados
- `systemctl list-unit-files --state=enabled` (system + `--user`) para servicios activos

---

## 1. Gap: paquetes instalados a mano, no reflejados en `bootstrap.sh`

13 paquetes explícitos en esta máquina que `bootstrap.sh` no instala. Agrupados por causa probable:

### 1.1 Deuda de reproducibilidad real — regresión de memoria detectada — ✅ RESUELTO 2026-08-05

| Paquete | Qué es | Hallazgo |
|---|---|---|
| `fwupd` | Firmware updater (usado para el umbral de carga de batería del ThinkPad) | **Mismo patrón de "persistence-loss" ya documentado en `auditorias/autenticacion/`**. Hay una memoria de sesión (2026-07-27) que registra la decisión *"ThinkPad battery threshold + fwupd added to bootstrap.sh"* — pero `bootstrap.sh` actual **no tiene ese paso**, ni `fwupd` en ningún `pacman -S`. `rg` sobre `bootstrap.sh` y `CLAUDE.md` para `fwupd`/`battery.*threshold`/`charge_control` no encuentra nada. |

Verificado en vivo: `/etc/tmpfiles.d/battery-thresholds.conf` **sí existe en esta máquina** (fecha 28 jul, contenido correcto: `charge_control_start/end_threshold` 75/80 sobre `BAT0`) — el trabajo se hizo y funciona hoy, pero **no sobrevivía a una reinstalación** porque nunca quedó escrito en `bootstrap.sh`.

**Fix aplicado**: nuevo step **18b** en `bootstrap.sh` (junto al step 18 "System utils", sin renumerar el resto del script) — instala `fwupd`, escribe el mismo `/etc/tmpfiles.d/battery-thresholds.conf` que ya estaba en el sistema, y aplica `systemd-tmpfiles --create` para que el umbral quede activo sin esperar al próximo boot. Gateado por `[[ -d /sys/class/power_supply/BAT0 ]]` — se salta solo en una máquina sin batería (ej. si algún día corre en un desktop). Documentado en `CLAUDE.md` junto al resto de los steps de bootstrap.

### 1.2 Leftovers de la investigación de autenticación (auditoría previa)

| Paquete | Qué es | Decisión |
|---|---|---|
| `clevis` | Framework de desbloqueo automático (LUKS vía TPM2/Tang) | ✅ **Conservar + agregar a bootstrap.sh** — plan a futuro de migración a Secure Boot + TPM2 |
| `tpm2-tools` | CLI para el chip TPM2 | ✅ **Conservar + agregar a bootstrap.sh** — mismo motivo |
| `pamtester` | CLI para probar servicios PAM sin loguear de verdad | ✅ **Conservar + agregar a bootstrap.sh** — además es la herramienta de debug de PAM usada en toda `auditorias/autenticacion/README.md` |
| `evtest` | Inspección de eventos de input crudos (`/dev/input/event*`) | ⏳ investigado — ver abajo |

**2026-08-05 — Resuelto**: aunque `clevis`/`tpm2-tools` pertenecían al enfoque de credencial-cacheada-vía-TPM2 que **se descartó** para el bug del keyring (§0 de `auditorias/autenticacion/`), el usuario confirmó que los quiere conservar de cara a una migración futura a Secure Boot. Se agregaron a `bootstrap.sh` en un step nuevo junto al de fingerprint PAM (comentario explícito de que todavía no están wireados a nada — son prep, no una feature activa).

**`evtest`** — el usuario no recordaba para qué lo había instalado, sospechaba que fue para encontrar el keycode del botón de power del laptop. Verificado: `dotfiles/hypr/.config/hypr/deadlock/keybinds.lua:183` usa `XF86PowerOff` — un keysym estándar de X11/Wayland, no un código custom que hubiera hecho falta descubrir con `evtest`. `rg` de `evtest` en todo el repo (configs, scripts, docs) no encuentra ninguna referencia — no es dependencia de nada. **2026-08-05 — Resuelto**: confirmado como herramienta de diagnóstico puntual sin uso actual. El usuario lo desinstala manualmente (`pacman -R evtest`, esta sesión no tiene permisos sudo) — no requiere cambios en `bootstrap.sh` porque nunca estuvo ahí.

### 1.3 Apps de uso personal, no documentadas como parte del stack

| Paquete | Qué es | Decisión — 2026-08-05 |
|---|---|---|
| `dbeaver` | Cliente GUI de bases de datos | ❌ **No va a bootstrap.sh** — instalación manual para estudios del usuario, fuera del alcance del stack general |
| `steam` | Plataforma de gaming | ✅ **Agregado a bootstrap.sh** (step 16, Apps) — de uso general, no atado a un proyecto puntual |

`steam` necesita el repo `[multilib]` (paquetes de 32 bits) habilitado en `/etc/pacman.conf`, que en esta máquina ya está activo pero **`bootstrap.sh` no lo habilitaba en ningún paso** — otro gap de reproducibilidad real, encontrado al agregar `steam`. Fix: nuevo paso en el step 0 (pacman config) que descomenta `[multilib]`/`Include` de forma idempotente (mismo patrón `sed` que Color/ParallelDownloads/ILoveCandy ahí mismo) y corre `pacman -Sy` antes de que cualquier paso posterior necesite el repo.

### 1.4 Redundancia de paquete (posible limpieza) — ✅ RESUELTO 2026-08-05

| Paquete | Nota |
|---|---|
| `p7zip` + `7zip` | **Ambos instalados explícitamente**, mismo propósito ("File archiver for extremely high compression"). Arch renombró/reemplazó `p7zip` por `7zip` (el 7-Zip real, mismo autor upstream) — es común terminar con los dos si `7zip` se instaló manualmente sin quitar `p7zip` primero. |

**Decisión**: migrar a `7zip`. `bootstrap.sh` (step 6, CLI tools) cambiado de `p7zip` → `7zip`. `p7zip` desinstalado por el usuario en esta máquina.

### 1.5 Marcados como explícitos pero con pinta de dependencia — ✅ RESUELTO 2026-08-05

| Paquete | `Install Reason` | `pactree -r` (qué depende de esto) | Nota |
|---|---|---|---|
| `pyside6` | Explícito | nada — solo se lista a sí mismo | Bindings de Qt para Python |
| `webkit2gtk-4.1` | Explícito | nada | Motor WebKit para GTK |
| `wireless-regdb` | Explícito | nada | Base de datos regulatoria WiFi |
| `ntfsprogs` | Explícito | nada | Herramientas NTFS de bajo nivel — `ntfs-3g` (sí está en `bootstrap.sh`, step 18) ya cubre el uso normal en desktop |

Confirmado con `pactree -r <pkg>` sobre los 4: **nada instalado actualmente depende de ellos**. El usuario los identificó como instalaciones propias para otros proyectos de programación, algunos todavía en uso, otros no — pero en cualquier caso fuera del alcance del stack documentado. **Decisión: quedan fuera de `bootstrap.sh`**, no se tocan en esta máquina (siguen instalados, solo no se agregan al script). Si en el futuro alguno pasa a ser necesario para una app del stack (no un proyecto personal), se agrega en ese momento.

### 1.6 No son gaps reales (verificado, descartado)

- Todo el bloque NVIDIA/AMD (`nvidia*`, `mesa-vdpau`, `vulkan-radeon`, `xf86-video-amdgpu`, `libva-mesa-driver`, `libva-nvidia-driver`) aparece como "en bootstrap.sh pero no instalado" — **correcto**, esta máquina tiene un único GPU Intel (Arc 130V/140V, Lunar Lake), el auto-detect de `lspci` no tiene por qué instalarlos acá. No es un bug.
- `cargo`, `python`, `go`, `gdb`, `cmake`, `lua`, `mesa`, `qt6-base`, `qt6-declarative`, `qt6-svg`, `pipewire`, `wireplumber`, `util-linux`, `sqlite`, `libsecret`, `xdg-utils`, `curl`, `pnpm`, `python-gobject` — todos presentes, solo que como **dependencia** de otro paquete (`Install Reason: Installed as a dependency`), no como explícito. `bootstrap.sh` los pide igual (quedarían explícitos recién si se reinstala desde cero) — no hay gap real, es solo una diferencia de "quién lo pidió primero".
- `acpid` — ✅ **investigado y resuelto 2026-08-05**. Corre con la config default de fábrica del paquete (`/etc/acpi/handler.sh` sin modificar, un solo rule catch-all que solo hace `logger`, sin acciones reales) — no dispara nada de Hyprland/Quickshell, y `pactree -r acpid` confirma que nada depende de él. El usuario confirmó: lo instaló mientras debuggeaba el evento de la tapa (lid) antes de asentarse en el enfoque `logind`-nativo actual (ver `CLAUDE.md`, sección de logind/lid). **Decisión: se queda instalado en esta máquina** como herramienta de debugging a mano para el futuro (ajustar/diagnosticar eventos ACPI si hace falta) — mismo criterio que `dbeaver`/§1.5: herramienta puntual, **no entra a `bootstrap.sh`**.

---

## 2. `dotfiles/scripts/` — dependencias de binarios

Leí los 19 scripts completos (`.local/bin/`). Resultado: **sin gaps** — todo binario que invocan ya está cubierto por `bootstrap.sh`:

| Script | Binarios externos | Cubierto por bootstrap.sh |
|---|---|---|
| `get-location` | `python3` + módulo `gi`/Geoclue, `curl` (fallback ipinfo.io) | ✅ `python`, `python-gobject`, `geoclue` (step 18), `curl` |
| `wsaction` | `fish`, `hyprctl`, `jq` | ✅ `fish` (step 5), `jq` (step 6) |
| `webapp-install`/`-remove` | `gum` (opcional), `curl` | ✅ `gum`, `curl` (step 18) |
| `webapp-launch` | `uwsm-app` (de `uwsm`), `xdg-settings` | ✅ `uwsm` (step 3) |
| `record` | `gpu-screen-recorder`, `slurp`, `jq`, `notify-send`, `xdg-open` | ✅ todos cubiertos |
| `reminder` | `systemd-run`, `notify-send` (vía `notification-send`) | ✅ systemd es del sistema base |
| `screenshot`/`ocr` | `grim`, `slurp`, `hyprpicker`, `satty`, `notify-send` | ✅ step 10 |
| `libreoffice`/`soffice` | `ss` (iproute2, base del sistema) | ✅ implícito en `base`/`iproute2` |
| batería/brillo | `upower`, `brightnessctl`, `swayosd-client` | ✅ steps 12/18 |

No encontré ningún script apuntando a un binario que dependa de una app instalada a mano y ausente en el script.

---

## 3. Recomendaciones de apps/paquetes nuevos

Verificado antes de proponer: ninguno de los candidatos de abajo está instalado hoy (`pacman -Qi` por cada uno), y ninguno tiene ya un bind/config en el repo (`rg` sobre `dotfiles/`) — así que no hay redundancia con algo que ya exista. **Nada de esto se instaló** — son propuestas.

### 3.1 Alta confianza — encajan directo, bajo riesgo — ✅ AGREGADOS 2026-08-05

| Paquete | Por qué encaja | Trade-off | Dónde quedó |
|---|---|---|---|
| `yt-dlp` | Ya tenés `mpv` instalado (bootstrap.sh step 16) — es el combo estándar, `mpv` puede stream directo de una URL vía `yt-dlp` sin bajar el archivo primero | Ninguno relevante — sin dependencias nuevas, no pisa nada existente | `bootstrap.sh` step 16 (Apps), junto a `mpv` |
| `lazydocker` (AUR) | Ya tenés `docker`+`docker-compose` (step 28) y `lazygit` (step 6) — mismo autor/filosofía que `lazygit`, hoy no tenés ningún TUI para Docker (solo `docker ps` a mano) | Un paquete AUR más para mantener, cero config necesaria | `bootstrap.sh` step 28 (Dev: Docker), vía `yay` |
| `direnv` | Encaja con tu setup multi-lenguaje (Python/uv, Node/pnpm, Go, Rust, Docker — todos en bootstrap.sh) — carga env vars por proyecto automáticamente al entrar al directorio | Necesita un hook de shell y agrega un chequeo chico en cada `cd` — despreciable pero es el único con costo de shell startup | `bootstrap.sh` step 28 (Dev tools) + `dotfiles/zsh/.config/zsh/functions/direnv.zsh` (nuevo, mismo patrón `command -v` guard que `duf.zsh`/`eza.zsh`, cargado automáticamente por el loop de `terminal.zsh`) |

Los tres quedaron **en el repo pero no instalados en esta máquina todavía** (esta sesión no tiene sudo) — correr `./deploy.sh` para el hook de zsh, y el `pacman`/`yay` de cada uno a mano cuando puedas.

### 3.2 Visor de imágenes para Wayland — falta uno

Hoy no hay ningún visor de imágenes standalone bindeado en ningún lado — Yazi previea imágenes inline (vía kitty icat) pero abrir una imagen suelta fuera de Yazi (doble-click en el file manager, un `xdg-open foto.png`, un windowrule de Hyprland) no tiene a dónde ir. Dos candidatos, no los agrego ambos — es una decisión de gusto:

| Opción | Estilo |
|---|---|
| `imv` | Más viejo/maduro, keybinds estilo vim, configuración por archivo de texto simple |
| `swayimg` | Nativo de wlr-layer-shell (mismo protocolo que usa tu propia barra Quickshell), más liviano, soporta mostrar el primer frame de GIFs/video |

**2026-08-05 — ✅ Resuelto**: el usuario probó los dos a mano y eligió **`swayimg`** (disponible en `extra`, repo oficial — confirmado con `pacman -Si swayimg`). Agregado a `bootstrap.sh` step 16 (Apps), junto a `mpv`/`yt-dlp`.

### 3.3 Opcional — depende de si te sirve el caso de uso — ✅ AGREGADOS 2026-08-05

| Paquete | Por qué podría encajar | Trade-off | Dónde quedó |
|---|---|---|---|
| `atuin` | Historial de shell buscable/con stats, sincronizable entre máquinas | **Cambia UX de verdad** — reemplaza el historial nativo de zsh. Instalado con el hook activado; el server de sync (opcional, self-hostable) no se configuró — queda apagado hasta que decidas si lo querés | `bootstrap.sh` step 6 (CLI tools) + `dotfiles/zsh/.config/zsh/functions/atuin.zsh` (nuevo, mismo patrón que `direnv.zsh`) |
| `bandwhich` | Monitor de ancho de banda por proceso en terminal — complementa el kit de cybersecurity que ya tenés (`nmap`, `wireshark-qt`, `tcpdump`) | Necesita `cap_net_raw` o correr con sudo cada vez — fricción de uso | `bootstrap.sh` step 32 (Cybersecurity) |

### 3.5 Agregado fuera de lo propuesto — pedido directo del usuario

| Paquete | Qué es | Dónde quedó |
|---|---|---|
| `herdr-bin` (AUR) | "Terminal workspace manager for AI coding agents" (sesiones/worktrees para agentes de código tipo Claude Code) — provee `herdr`, verificado en AUR (`yay -Si herdr-bin`) | `bootstrap.sh`, nuevo step junto al bloque comentado de "AI tools" (step 29) |

Nota: en AUR existen `herdr` (build desde fuente) y `herdr-bin` (binario precompilado) — ambos figuran "out-of-date" al momento de revisar, pero son el mismo proyecto activo (`github.com/ogulcancelik/herdr`). Se eligió `herdr-bin` para no depender de compilar en cada reinstalación, mismo criterio que `zen-browser-bin`.

### 3.4 Descartado (ya cubierto o no encaja)

- `nvtop` — tu propio dashboard de Quickshell ya muestra CPU/RAM/GPU (`PerformanceSection.qml`), sería duplicado
- `ncdu` — `dust` (ya en bootstrap.sh) cubre el mismo caso de uso
- `difftastic` — `git-delta` (ya en bootstrap.sh, usado en `lazygit`) ya cubre diffs
- `age`/`sops`/`rclone` — no vi una necesidad concreta hoy (usás GPG + `backup/backups/` gitignoreado), sería especular sin un caso de uso real

---

## 4. Decisiones tomadas

- **2026-08-05 — Alcance de esta auditoría**: el objetivo final del repo es hacerlo público para que otra gente lo pruebe, así que eventualmente `bootstrap.sh` debería poder correr en cualquier máquina de forma genérica. Pero **por ahora el trabajo real está hecho a medida de esta PC** (Lenovo ThinkPad X1 Carbon Gen 13). Decisión: primero cerrar los gaps de reproducibilidad de **esta máquina** (§1), y recién después separar "genérico vs. específico de esta PC" como un trabajo aparte. No mezclar los dos todavía.
- **2026-08-05 — Criterio para qué entra a `bootstrap.sh`**: el usuario definió el criterio explícitamente — herramientas para proyectos personales/estudio (`dbeaver`, y los 4 paquetes de §1.5) **no van** al script aunque estén instaladas y en uso, salvo que alguna app del stack (fuera de proyectos personales) las necesite de verdad. Apps de uso general como `steam` (gaming) **sí van**. Este criterio queda como referencia para futuros hallazgos de este tipo.
- **2026-08-05 — `evtest` desinstalado** por el usuario (`pacman -R evtest`), confirmado (`pacman -Qi evtest` → "not found"). No requirió cambios en `bootstrap.sh` (nunca estuvo ahí).
- **2026-08-05 — `p7zip` → `7zip`**: `bootstrap.sh` ya actualizado; falta que el usuario corra `sudo pacman -R p7zip` a mano en esta máquina cuando pueda (esta sesión no tiene sudo).
- **2026-08-05 — ⚠️ Gotcha encontrado: `./deploy.sh` puede borrar cambios sin commitear en `dotfiles/`**. Después de aplicar todos los fixes de §1 y §3.1, el usuario corrió `./deploy.sh` (para dejar el hook de `direnv.zsh` symlinkeado) y **`dotfiles/bootstrap.sh` volvió exactamente a la versión del último commit** — confirmado con `md5sum` idéntico contra `git show HEAD:dotfiles/bootstrap.sh` y `git diff HEAD` en cero. Causa raíz: `dotfiles/deploy.sh:60` corre `git restore -- dotfiles/` como parte de su lógica de resolución de conflictos de Stow (comentario en la línea 30 del propio script lo confirma) — esto resetea **todo el subárbol `dotfiles/`** a la versión commiteada, no solo los archivos en conflicto. Sobrevivieron `CLAUDE.md` (vive fuera de `dotfiles/`) y `direnv.zsh` (archivo nuevo sin trackear — `git restore` no toca untracked). **Regla a partir de ahora: commitear cambios en `dotfiles/` antes de correr `./deploy.sh`**, no dejarlos flotando sin commit.
- **2026-08-05 — Step 29 "AI tools" reactivado**: estaba 100% comentado en `bootstrap.sh` (`@anthropic-ai/claude-code`, `@google/gemini-cli`, `opencode`, más un curl a `gentle-ai`). El usuario confirmó que en algún momento se corrió sin comentar y **tumbó el resto del bootstrap** — encontradas dos causas reales al investigar, cualquiera de las dos aborta bajo `set -euo pipefail`: (1) `npm install -g` sin `sudo` falla con EACCES (`npm config get prefix` en esta máquina → `/usr`, root-owned); (2) el nombre de paquete `opencode` no existe en el registro de npm (404 confirmado con `npm view opencode`) — el real es `opencode-ai`.
  - **Primer intento**: `sudo npm install -g @anthropic-ai/claude-code opencode-ai` — parcheaba los dos bugs, pero seguía dependiendo de npm.
  - **Versión final**: el usuario preguntó si convenía el instalador nativo de cada uno en vez de npm. Investigado (WebSearch) — tanto la doc oficial de Anthropic como la de OpenCode recomiendan el instalador nativo sobre npm desde 2026 (binario autocontenido, sin dependencia de Node.js en runtime, sin el problema de permisos que motivó el fix de arriba). Cambiado a `curl -fsSL https://claude.ai/install.sh | bash` y `curl -fsSL https://opencode.ai/install | bash` — sin `sudo`, sin npm.
  - Más: **Antigravity CLI** (`agy`, `curl -fsSL https://antigravity.google/cli/install.sh | bash` — verificado en `antigravity.google/docs/cli/install`, reemplaza a `gemini-cli` que se descartó de la lista) y **Ollama** (paquete oficial `extra`, + `systemctl enable ollama`). El instalador de `gentle-ai` también se sacó de la lista (no pedido).
- **2026-08-05 — Verificación en vivo de las apps instaladas** (post-deploy): 9/10 herramientas nuevas confirmadas funcionando (Claude Code, OpenCode, Antigravity, atuin, direnv, swayimg, yt-dlp, lazydocker, bandwhich, herdr). Faltaba `ollama` — el paso nunca corrió porque el usuario no pudo terminar el bootstrap completo (ver gotcha de `systemd-logind` abajo). Instalado y habilitado a mano (`pacman -S ollama` + `systemctl enable`), pero el servicio quedó `enabled` sin `--now` → `inactive`. Corregido con `systemctl start ollama` a mano; confirmado `active` + `ollama list` responde.
- **2026-08-05 — ⚠️ Gotcha encontrado: `_load_functions`/`_load_completions` nunca se invocaban**. Al verificar que atuin funcionara de punta a punta, se encontró que `terminal.zsh` solo *definía* ambas funciones pero no las llamaba en ningún lado de la cadena de sourcing (`terminal.zsh` → `prompt.zsh` → `user.zsh`, sin zinit snippet que las dispare) — confirmado en vivo: `alias ls` mostraba el default de Oh-My-Zsh (`ls --color=tty`) en vez de `eza -1 --icons=auto` de `aliases.zsh`, y `^R` quedaba en el binding default de zsh en vez del de atuin. Afectaba a los ~10 archivos de `functions/` y a `completions/`, no solo a las apps nuevas — código muerto desde antes de esta sesión. Fix: agregadas las dos llamadas al final de `terminal.zsh` (commit `a2960b4`).
- **2026-08-05 — `^R` en disputa entre fzf y atuin**: una vez arreglado el loader de arriba, `fzf.zsh` (carga después de `atuin.zsh` alfabéticamente) pisaba el bind de `^R` de atuin. Decisión: atuin gana `^R` explícitamente (superset de lo que da fzf ahí — SQLite, dedup real, sync, `^[[A` contextual por directorio — y es la razón por la que se instaló). fzf conserva `^T`/`Alt-C` y los alias propios (`ffec`/`ffcd`/`ffe`/`ffch`). Rebind explícito al final de `terminal.zsh`, no depende del orden de carga (commit `44f514e`).
- **2026-08-05 — ⚠️ Gotcha encontrado: `systemctl restart systemd-logind` en caliente cortaba la sesión**. El paso 25 (`logind: power button config`) escribía el conf.d y reiniciaba `systemd-logind` sin condición — en un re-run del bootstrap sobre un sistema ya instalado y logueado (no una instalación limpia desde TTY), eso mata la sesión gráfica activa (logind trackea el seat/sesión del compositor que levantó SDDM), cortando el resto del script bajo `set -euo pipefail`. Reproducido y confirmado por el usuario: pantalla pide contraseña, instalación se corta a mitad de camino. Fix: detecta con `loginctl` si hay una sesión wayland/x11 activa antes de restartear; si la hay, salta el restart (el conf.d ya quedó escrito, aplica en el próximo reinicio, mismo patrón que GRUB/SDDM); si no hay sesión gráfica (instalación limpia real), restartea como antes.
