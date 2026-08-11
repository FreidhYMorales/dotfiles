# Auditoría — Optimización (scripts de instalación + estructura del repo)

**Fecha:** 2026-08-05
**Alcance:** `dotfiles/bootstrap.sh` y `dotfiles/deploy.sh` (idempotencia, orden, manejo de errores, redundancia); estructura general del repo (`dotfiles/` vs `backup/` vs `system/`, documentación en `backup/references/`, `.gitignore`, convenciones de nombres).
**Fuera de alcance** (ya auditado/cerrado en otro lado, no re-tocar acá): código QML de Quickshell (performance/arquitectura), paquetes/apps instalados vs bootstrap.sh (`auditorias/paquetes/`), cadena de autenticación PAM/fprintd/polkit (`auditorias/autenticacion/`).
**Estado:** cerrada por completo — todos los hallazgos de scripts/estructura resueltos o descartados con criterio explícito, incluido P1 (ver abajo). Queda solo la vigencia de la documentación de Quickshell sin tocar (fuera de alcance).

---

## 0. Metodología

Verificado contra el estado real del repo, no asumido desde `CLAUDE.md`:
- Lectura completa de `dotfiles/bootstrap.sh` (652 líneas) y `dotfiles/deploy.sh` (65 líneas)
- Recorrido de los 27 paquetes Stow en `dotfiles/`, estructura de carpetas de cada uno
- `du -sh` y diff directo de `backup/*` contra sus contrapartes en `dotfiles/`
- `git log -1` sobre cada archivo de `backup/references/` para fecha de última modificación real
- `git status --ignored`, `git ls-files`, y grep de patrones tipo secreto sobre el historial completo (`git grep` en `git rev-list --all`)

---

## Pendientes diferidos (fuera del ciclo normal de esta auditoría)

### P1 — API key filtrada en el historial de git (`backup/zsh/.zshenv:18`) — **resuelto (2026-08-11)**

**Qué se encontró:** `GEMINI_API_KEY` real en texto plano, trackeada por git (no cubierta por `.gitignore` — solo `dotfiles/zsh/.config/zsh/secrets.zsh` está ignorado, esta copia vieja en `backup/zsh/.zshenv` no). Presente en 20+ commits del historial completo, incluido `HEAD` en su momento, y pusheada a `origin/main` — repo `FreidhYMorales/dotfiles` confirmado **público** (`gh repo view` → `isPrivate: false`).

**Cómo se resolvió:** key ya estaba **revocada por el usuario** (2026-08-05) desde antes de esta limpieza, sin riesgo activo. Se confirmó primero (`git grep` sobre `git rev-list --all`) que la key **solo** aparece en `backup/zsh/.zshenv` — ningún otro archivo del historial la contiene. Se ejecutó el plan diseñado:
1. `git-filter-repo` instalado (`sudo pacman -S git-filter-repo`)
2. Backup de seguridad (`git clone --mirror`) + clon de trabajo separado, ninguno de los dos sobre el working directory real
3. Decisión sobre el archivo completo (no solo la línea de la key): **borrar `backup/zsh/.zshenv` entero del historial** (`git filter-repo --path backup/zsh/.zshenv --invert-paths`) — el resto del archivo era puro boilerplate ya obsoleto (duplicado muerto de `dotfiles/zsh`), sin nada más que valiera la pena preservar
4. Verificado: `git log --all -p | rg AIzaSy` → cero resultados; `git log --oneline -- backup/zsh/.zshenv` → vacío; árbol de archivos de HEAD idéntico al repo real (única diferencia: hashes de commit, esperado); 123 commits preservados
5. Force-push a `origin` (`90193c1` → `6e35676` como nuevo HEAD de `main`)
6. Working directory real resincronizado (`git fetch` + `git reset --hard origin/main`, sobre árbol ya limpio) + `git gc --prune=now --aggressive` local para purgar el blob viejo con la key

**Limitación conocida, sin acción pendiente:** GitHub puede cachear por un tiempo commits ya no alcanzables desde `main` (accesibles todavía por SHA directo hasta que el GC de GitHub los limpie) — irrelevante acá porque la key ya estaba revocada antes de esta limpieza, así que no hay ventana de riesgo real.

**Cross-reference:** ligado a la limpieza de redundancia `backup/` vs `dotfiles/` (sección de esta misma auditoría, ya cerrada) — `backup/zsh/.zshenv` era una de las copias viejas pre-Stow encontradas ahí, y ya no existía en el working tree desde esa limpieza (solo quedaba en el historial, que es lo que se resolvió acá).

---

## 1. Hallazgos crudos recolectados (sin revisar con el usuario todavía)

Recolección inicial hecha, pendiente de pasar uno por uno con el usuario y decidir acción. Guardado acá como memoria de trabajo:

### 1.1 `dotfiles/bootstrap.sh`
- Header dice "(33 steps)" pero hay 36 bloques numerados (con sub-pasos 0b/4b/18b) y 69 invocaciones reales de `step "..."` — el conteo no coincide con ninguna forma de contar.
- `pacman -Sy`/`-Syu` aparece una sola vez (L55) — no hay refresh redundante del sistema.
- `fc-cache` una sola vez (L584).
- `pciutils` se instala dos veces (L95 bloque GPU, L141 bloque NPU) — redundante aunque inofensivo por `--needed`.
- **Bug: plugin zsh mal nombrado** — L173 `[zsh-syntax - highlighting]` (con espacios, artefacto de bash tratando el subíndice como aritmético) vs `zsh-syntax-highlighting` real referenciado en `dotfiles/zsh/.zshrc:82` → el plugin nunca carga.
- **Bug de idempotencia**: L552, `sed` agrega `noatime` a fstab sin guard — en cada re-run acumula `noatime,noatime,noatime...`.
- **Dependencia entre pasos sin verificación**: L321-327 salta la copia del tema SDDM si no existe la fuente, pero L333-334 (paso siguiente) asume que el destino ya existe — si el paso anterior se saltó, esto aborta todo el script bajo `set -euo pipefail`.
- **Sobrescritura sin backup/check**: L573-576 borra `.zshrc`/`.zshenv`/`.gitconfig` incondicional (asume fresh install sin verificarlo); L353-355 sobrescribe PAM configs sin backup; L615-617 y L646-648 resetean wallpaper/tema del usuario a default en cada re-run, sin guard.
- **Sin guard de idempotencia**: paso AI tools (L444-451) reinstala Claude Code/OpenCode/Antigravity vía curl en cada corrida, sin `command -v` previo (a diferencia de `yay`, L80, que sí lo tiene).
- Detecciones de hardware presentes: GPU vendor (lspci, L97), NPU Intel (lspci, L142), batería (`/sys/class/power_supply/BAT0`, L260), sesión gráfica activa antes de restart de logind (L374-376).

### 1.2 `dotfiles/deploy.sh`
- Sin argumentos, itera todos los subdirectorios de `dotfiles/*/` excepto `PENDING=(stylus)` — **`chromium-extension` no está en `PENDING`**, así que un deploy sin argumentos symlinkea `~/matugen-vars` (paquete que no sigue el patrón `.config`).
- Conflictos: `stow --adopt` + `git restore` después, para que la versión del repo siempre gane.
- Sin manejo de fallo a mitad de la lista de paquetes (bajo `set -euo pipefail`, aborta sin rollback de lo ya stoweado).

### 1.3 Paquetes Stow — inconsistencias de estructura
- `dotfiles/chromium-extension/` y `dotfiles/stylus/` no siguen el patrón `.config/` (contenido plano). `stylus` está excluido en `PENDING`, `chromium-extension` no.
- Dos paquetes distintos (`systemd` y `matugen`) escriben symlinks al mismo directorio destino `~/.config/systemd/user/`.
- `dotfiles/README.md` desactualizado: lista 17 de los 27 paquetes reales, todos marcados "pendiente de poblar" pero están completamente poblados; `hypr`/`quickshell` marcados "WIP" pero son los sistemas activos y auditados; sección Referencias apunta a un path viejo (`~/Files/Configuraciones/references/`).

### 1.4 Redundancia `backup/` vs `dotfiles/` vs `system/`
- Confirmado por diff directo: `backup/nvim`, `backup/zsh`, `backup/hardware/scripts/*` (bit-a-bit idénticos a `dotfiles/scripts`), `backup/git/.gitconfig` (identidad de git distinta: `FreidhYMorales` vs `deadlock`), `backup/kitty`/`starship`/`systemd`/`vesktop`/`ncmpcpp`/`btop`/`zellij`/`mpd`/`spicetify` — todas versiones pre-Stow, congeladas, divergentes de `dotfiles/`.
- `backup/material-you/` referencia Waybar (bar previo a Quickshell). `backup/omarchy/` es el framework reemplazado por la config Hyprland propia.
- `backup/clipboard/`, `launch-or-focus/`, `ocr/`, `reminders/`, `screen-recording/`, `screenshots/`, `webapps/`, `workspace-groups/` — cada uno con README + copia de script que también vive en `dotfiles/scripts/.local/bin/`.
- Sin relación con el setup actual: `backup/winapps/`, `backup/w3m/` (datos de navegación personal), `backup/zen/` (ignorado parcialmente), `backup/obsidian/obsidian.json`.
- `backup/archive/restorations/sddm/` vs `system/sddm/`: mismo tema pero con `etc/`/`INSTALL.md` extra que no existen en `system/sddm`.

### 1.5 `backup/references/` — vigencia de la documentación (en revisión)

**`post-install.md` — corregido de punta a punta:**
- Sección 1 (secrets): removida la instrucción de restaurar SSH/GPG desde `backup/backups/` — usuario confirma que no tiene ese contenido respaldado hoy, directorio no existe.
- Sección 2 (GRUB): corregida — `bootstrap.sh` paso 30 ya instala paquetes/tema/config y corre `grub-mkconfig`; solo `grub-install` (device-specific) sigue siendo genuinamente manual.
- Sección 4 vieja (AUR packages not in bootstrap) — **eliminada completa**, `gpu-screen-recorder-git` ya está en `bootstrap.sh:232`, dato obsoleto.
- Secciones renumeradas (9→8) tras el borrado, cross-reference interno corregido ("step 5"→"step 4").
- Línea de cabecera ("Everything here is manual") suavizada — ya no es 100% cierto tras el fix de GRUB.

**Hallazgo nuevo de paso, fuera de este archivo**: `CLAUDE.md` (sección "Reinstalar desde cero") referencia "`grub-install` (machine-specific — ver instrucciones en bootstrap.sh step 25)" — pero GRUB es el paso **30**, no el 25 (que es logind). Cross-reference desactualizada, pendiente de corregir en el batch final.

**`deploy-strategy.md` — recortado**: era un doc de planificación (2026-06-04, previo a que existiera nada), con tabla de 27 paquetes marcados "pendiente de poblar" (completos hoy) y "Próximos pasos" ya completados (crear repo en GitHub, etc.). Recortado a solo las 2 secciones conceptuales que siguen siendo válidas ("Por qué Stow", "Cómo funciona Stow"), con rutas corregidas (`~/Files/dotfiles/` → genérico) y referencia a `dotfiles/README.md`/`deploy.sh` para el estado real.

**`packages-reference.md` — eliminado completo**: 484 líneas, plan manual de instalación previo a `bootstrap.sh` (mencionaba `polkit-gnome`, reemplazado hace rato; arrancaba desde "instalación Caelestia existente"). Totalmente redundante con `bootstrap.sh`, que es hoy la versión real/automatizada/probada del mismo contenido.

**`matugen-pipeline-reference.md` — reescrito**: 525 líneas mezclaban una sección final (§11, "Pipeline implementado — 2026-07-07") ya precisa y verificada, con 10 secciones anteriores de planificación aspiracional ("Caelestia sistema actual / matugen lo que usaremos") — incluían una sección entera de ANSI escapes a `/dev/pts` que **nunca se implementó** (verificado: `config.toml` no tiene ningún paso que genere `term0`-`term15`). Reescrito a 2 secciones: tabla de tokens M3 (evergreen, trimeada a solo nomenclatura matugen) + el pipeline real. De paso corregido un dato que había quedado desactualizado incluso en la sección "real": decía "6 templates", el `config.toml` actual tiene **8** activos (faltaban `userContent.css` y `obsidian-theme.css` en la lista vieja) — agregados a la tabla de "Apps cubiertas" también (GTK/Electron/Zen color-scheme, LibreOffice, Obsidian, que no estaban documentados ahí pese a estar implementados).

### 1.5b vigencia del resto de `backup/references/` (fuera de alcance — Quickshell)

`quickshell-animation-patterns.md`, `quickshell-audit-2026-06.md`, `quickshell-pending-plugins.md`, `quickshell-vision.md`, `caelestia/`, `end-4/` — no revisados, la auditoría de código/arquitectura QML de Quickshell está explícitamente fuera de alcance de esta sesión (ya auditada aparte). Determinar su vigencia requeriría meterse en ese mismo territorio.
- `deploy-strategy.md`: repo location dado como `~/Files/dotfiles/`, no coincide con la ruta real.
- `post-install.md`: instruye restaurar desde `backup/backups/ssh|gnupg/` — ese directorio **no existe** en disco hoy.
- `post-install.md`: presenta GRUB como "todo manual, bootstrap no lo cubre" — pero `bootstrap.sh` sección 30 ya lo automatiza completo.
- `packages-reference.md`: describe un pipeline conceptual/manual de instalación, pre-existente (2026-07-09) al `bootstrap.sh` real de 69 pasos ya auditado — posible solapamiento/desactualización.

### 1.6 `.gitignore` y seguridad — corregido

**Aplicado**: agregada regla para `dotfiles/fonts/.local/share/fonts/.uuid` (caché runtime de fontconfig, confirmado que ya no aparece en `git status`). Removidas 7 reglas muertas que apuntaban a paths dentro de `backup/` ya eliminados en la limpieza de esta sesión: `backup/backups/`, `backup/quickshell`, `backup/archive/restorations/grub/`, `backup/yazi/plugins/fg.yazi/`, `backup/archive/restorations/probe-os/`, `backup/archive/mysql/`, `backup/zen/profile/`.

Detalle original de los hallazgos:
- Ver P1 arriba (API key).
- `dotfiles/fonts/.local/share/fonts/.uuid` — archivo de caché runtime, untracked, sin regla de `.gitignore` que lo cubra (análogo a otros runtime files que sí están ignorados).
- Dos reglas de `.gitignore` sin efecto (apuntan a paths que no existen en disco): `backup/backups/`, `backup/quickshell` (el symlink documentado en `CLAUDE.md`/`backup/README.md` no existe hoy en el filesystem).

### 1.7 Convenciones de nombres — mayoría resuelta al borrar `backup/`

`BetterDiscord` PascalCase, dos identidades de git, `mimeapps.list` suelto — todos vivían solo en `backup/`, resueltos por la limpieza de la sección 1.5.

**Aplicado**: `dotfiles/git/.gitconfig:5-6` — rutas `safe.directory` viejas (`/home/deadlock/Files/...`) corregidas a la ruta real (`/home/deadlock/Mio/Configuraciones/...`). No estaba bloqueando nada en esta sesión, pero podía rechazar el repo como "dubious ownership" en una reinstalación desde cero.

Detalle original de los hallazgos:
- `backup/BetterDiscord` (PascalCase) vs `dotfiles/betterdiscord` (lowercase).
- Única línea en español dentro de `bootstrap.sh` (L377), resto del script 100% en inglés.
- `dotfiles/xdg-portal` vs `dotfiles/termfilechooser` — mismo dominio (xdg-desktop-portal), nombrados con criterios distintos.
- `backup/mimeapps.list` archivo suelto en la raíz de `backup/`, mientras el resto de configs equivalentes ahí son carpetas.
- Dos identidades de git distintas para el mismo email (`deadlock` vs `FreidhYMorales`) y rutas `safe.directory` obsoletas (`/home/deadlock/Files/...`) en `dotfiles/git/.gitconfig` y `backup/git/.gitconfig`.

---

## 1.5 Limpieza de `backup/` — completa

Decisión de fondo del usuario: `backup/` fue en su momento fuente de configs de otra laptop, después copia completa de migración, y hoy (proyecto casi terminado) quedó como archivo histórico sin más función — autorizado a eliminar, rescatando antes lo que valiera la pena.

**Eliminado completo** (34 entradas, ~621 archivos del working tree): `archive/` (incluye guías de LAMP/MySQL/gnome-network-displays/mcp-ncmpcpp/xdg-portal-termfilechooser/hypr-pre-omarchy — todas superadas o rescatadas antes, ver abajo), `BetterDiscord/`, `btop/`, `clipboard/`, `fastfetch/`, `fonts/`, `git/` (identidad `FreidhYMorales` vieja), `hardware/`, `hypr/`, `hyprland-options/`, `kitty/`, `launch-or-focus/`, `material-you/`, `mimeapps.list`, `mpd/`, `ncmpcpp/`, `nvim/`, `obsidian/`, `ocr/`, `omarchy/`, `README.md`, `reminders/`, `RESTORE.md`, `screen-recording/`, `screenshots/`, `spicetify/`, `starship/`, `systemd/`, `vesktop/`, `w3m/`, `webapps/`, `winapps/` (confirmado sin uso — LibreOffice + versión web cubren lo que hacía falta), `wiremix/`, `workspace-groups/`, `xcompose/`, `yazi/`, `zellij/`, `zen/`, `zsh/` (incluye la copia de la API key filtrada — el working tree queda limpio, el historial de git sigue pendiente en P1).

**Sobrevive intacto**: `backup/references/` (documentación, auditada aparte más abajo).

**Rescatado antes de borrar** (ver D9-D13 en la tabla de decisiones): config real de Hyprland nunca portada, inventario de webapps, guía de instalación SDDM, preset alternativo de Starship, feature pendiente de Miracast.

## 2. Decisiones tomadas (batch de fixes a aplicar al final)

| # | Hallazgo | Decisión |
|---|---|---|
| D1 | `bootstrap.sh:173` — plugin `zsh-syntax-highlighting` mal nombrado (`[zsh-syntax - highlighting]`), nunca carga | **Aplicado** — clave corregida en `bootstrap.sh`; carpeta huérfana con espacios en el nombre borrada también del sistema en vivo |
| D2 | `bootstrap.sh:552` — `sed` de `noatime` en fstab sin guard, se duplica en cada re-run | **Aplicado** — guard `grep -q ... noatime` agregado antes del `sed` |
| D3 | `bootstrap.sh:321-334` — paso SDDM custom.conf asume que el paso anterior (copia de tema) corrió bien, sin chequear destino; si falta, aborta todo el script sin mensaje claro. Riesgo teórico (usuario confirma que `$SDDM_THEME_SRC` difícilmente falte en su flujo real) | **Aplicado** — guard `[[ -f ... ]]` con warning claro en vez de fallo silencioso |
| — | `bootstrap.sh:573-576` — `rm -f .zshrc/.zshenv/.gitconfig` incondicional antes del deploy de Stow, sin verificar fresh install | **Sin acción** — usuario confirma que no toca esos archivos a mano fuera del repo (si modifica algo, lo commitea/pushea siempre); el `rm` es además necesario para que Stow pueda symlinkear limpio en un re-run. No es un bug real dado el flujo de trabajo real |
| — | `bootstrap.sh:353-355` — sobrescribe configs de PAM (`sddm`, `quickshell-fprint`, `quickshell-password`) sin backup | **Sin acción** — usuario confirma que siempre modifica estos archivos desde el repo, nunca a mano en `/etc/pam.d/` directamente. Mismo criterio que el ítem anterior |
| D4 | `bootstrap.sh:615-617` + `646-648` — resetea wallpaper/tema a default (`arch.png`, dark) sin condición en cada corrida; pisaría la elección del usuario si el bootstrap se re-corre sobre un sistema ya instalado (no probado todavía, pero escenario real posible — ej. al agregar un paso nuevo al script) | **Aplicado** — nuevo flag `FRESH_WALLPAPER_STATE`, wallpaper.txt/theme.json y el matugen-run final solo corren si no existía estado previo |
| D5 | `bootstrap.sh:444-451` — paso AI tools (Claude Code/OpenCode/Antigravity) sin guard de idempotencia, re-descarga e reinstala en cada re-run | **Aplicado** — `command -v claude/opencode/agy` guard antes de cada curl-install |
| — | `bootstrap.sh:95,141` — `pciutils` instalado dos veces (bloque GPU y bloque NPU) | **Sin acción** — costo real es nulo (`--needed` lo resuelve al instante), y unificarlo acoplaría dos bloques que son independientes a propósito (gateados por detecciones de hardware distintas, cada uno ya fue tocado por separado en el pasado — ver historial de NPU) |
| D6 | `bootstrap.sh:3` — comentario de cabecera dice "(33 steps)", no coincide con los 36 bloques numerados reales ni con las 69 invocaciones de `step "..."` (desactualizado a medida que se agregaron sub-pasos) | **Aplicado** — cuenta sacada del comentario |
| D7 | `deploy.sh:16` — `chromium-extension` no está en `PENDING=(stylus)`, así que un deploy sin argumentos symlinkea `~/matugen-vars` directo al home (no sigue el patrón `.config/` de los demás paquetes). Descuido, no intencional | **Aplicado** — agregado a `PENDING`, symlink `~/matugen-vars` accidental unstoweado del sistema en vivo |
| — | Dos paquetes Stow (`systemd`, `matugen`) escriben symlinks al mismo directorio destino `~/.config/systemd/user/` | **Sin acción** — no genera colisión real con Stow (archivos distintos), solo prolijidad. Usuario prefiere dejarlo así |
| D8 | `dotfiles/README.md` desactualizado — lista 17/27 paquetes, todos marcados "pendiente de poblar" (están completos), `hypr`/`quickshell` marcados WIP (son los sistemas activos y auditados), sección Referencias apunta a un path inexistente | **Aplicado** — reescrito completo, 25 paquetes reales + sección PENDING explicada |
| D9 | `backup/hyprland-options/` — config real de Hyprland (Caelestia) nunca portada al `.lua` actual | **Aplicado ya** — `general.lua` (misc: `middle_click_paste`, `session_lock_xray`, `allow_session_lock_restore`, `on_focus_under_fullscreen`, `mouse/key_press_enables_dpms`), `gestures.lua` (tuning `workspace_swipe_*`), `execs.lua` (`trash-empty 30`, `mpris-proxy`). **Omitido a propósito**: `vrr=1` (dependiente de soporte real de VRR del panel, no verificado, riesgo de parpadeo); gestos de "3 dedos arriba → special workspace" y "4 dedos abajo → suspend" (necesitan un campo `args` en `hl.gesture()` sin precedente probado en el repo — riesgo de error visible o fallo silencioso del bridge Lua, requiere prueba en vivo que no puedo hacer acá). Pendiente para el usuario: probar esos 2 gestos a mano si le interesan |
| — | `backup/hardware/README.md` — tuning NVIDIA Optimus/PRIME nunca aplicado | **Sin acción, eliminar completo** — verificado que documenta una laptop con NVIDIA GTX 1660 Ti que el usuario ya no tiene (ni la Dell ni el ThinkPad de las auditorías previas tienen NVIDIA). No aplica a ningún hardware actual |
| D11b | `backup/xcompose/README.md` — secuencias de emoji via XCompose, nunca activado (falta `kb_options` de tecla compose en `input.lua`) | **Probado en vivo y descartado**: se agregó `kb_options = "compose:caps"` a `dotfiles/hypr/.config/hypr/deadlock/input.lua` (Caps Lock, no AltGr, para no chocar con el layout `altgr-intl`), confirmado funcionando (`hyprctl reload` en vivo, secuencia de prueba OK). Usuario decidió no quedarse con la feature — pierde el toggle normal de Caps Lock siempre-activo, y no usa emojis. **Revertido** `input.lua`, **eliminado el paquete `dotfiles/xcompose/` completo** (unstow + `rm -rf`, symlink `~/.XCompose` removido en vivo) |
| D12 | `backup/archive/restorations/sddm/INSTALL.md` — única guía de instalación del tema SDDM, `system/sddm/` no tenía README | **Aplicado ya** — no se movió tal cual (estaba desactualizada: nombre de conf `the_hyde_project.conf` real es `deadlock.conf`, perfil visual documentado `dragon.conf`/`red-black-dragon.jpg` real es `custom.conf` dinámico vía matugen, sin mención de `QT_SCREEN_SCALE_FACTORS`). Escrita de cero `system/sddm/README.md` verificada contra el `metadata.desktop`/`sddm.conf.d/deadlock.conf` reales y el paso 24 de `bootstrap.sh` |
| D14 | `CLAUDE.md` — "Reinstalar desde cero" referencia `grub-install` en "bootstrap.sh step 25" pero GRUB es el paso 30 (25 es logind) | **Aplicado** — número de paso corregido |
| D13 | `backup/starship/powerline.toml` — preset alternativo de Starship, sin usar | **Aplicado ya** — copiado a `backup/references/starship-powerline-preset.toml` (fuera de cualquier paquete Stow, no se deploya, queda solo como referencia para probar en el futuro) |
| D11 | 7 scripts (`clipboard`, `launch-or-focus`, `ocr`, `reminder`, `record`, `wsaction`, `screenshot`) en `dotfiles/scripts/` verificados sin ningún keybind/caller en Hyprland ni Quickshell — deployados por Stow pero nunca disparados | **Corrección propia**: dije que sin el script `clipboard` no había forma de acceder al historial — falso, `SUPER+V` ya lo hace vía pipeline `cliphist\|fuzzel` (`keybinds.lua:177,180`). El único valor nuevo real del script era el modo `--delete`. **Aplicado**: `SUPER+SHIFT+V` → `clipboard --delete` (nuevo); `SUPER+O` → `ocr` (nuevo, `SUPER+T` ya estaba tomado por Toggle Floating); `SUPER+R` → `reminder show` (nuevo); `PRINT`/`SUPER+PRINT` migrados de grim/slurp crudo al script `screenshot fullscreen`/`region` (gana notificación + editor satty); `SUPER+SHIFT+PRINT` (captura instantánea de ventana activa) se dejó sin tocar — el script no tiene modo equivalente sin interacción; `SUPER+B` migrado a `launch-or-focus` (foco si ya está abierto, si no lanza) solo para el browser, a pedido del usuario — `SUPER+E` (file manager/yazi) se dejó igual. `record` **no se wireó** — redundante con `RecorderWidget` nativo de Quickshell ya existente. `wsaction` **no se wireó** — usuario no lo pidió |
| D10 | `backup/webapps/apps` + `restore` — inventario real de webapps del usuario, sin copia en otro lado, no integrado a `bootstrap.sh` | **Aplicado ya** — filtrado a 5 apps que el usuario confirmó usar (Discord, GitHub, Notion, WhatsApp, YouTube; se descartaron Basecamp, ChatGPT, Figma, Fizzy, Google Contacts/Maps/Messages/Photos, X). Movido a `dotfiles/scripts/.local/share/webapps/apps` + nuevo script `dotfiles/scripts/.local/bin/webapp-restore` (idempotente, salta apps que ya tienen `.desktop`). Nuevo paso en `bootstrap.sh` ("Post-install: restore web apps") justo después del step de MPD, envuelto en `\|\| echo warning` (no aborta el resto del bootstrap si falla). **Bug encontrado y corregido al portar**: el script original de `backup/webapps/restore` usaba trim con sintaxis `extglob` (`${var##*( )}`) sin `shopt -s extglob` — nunca recortaba nada en silencio, dejando un espacio inicial en el campo `url` (por el formato `nombre \| url` del archivo) que rompía la URL al pasarla a `webapp-install`. Corregido agregando `shopt -s extglob` al script nuevo |

## 3. Recomendaciones (pendiente — se arman a medida que revisamos cada hallazgo con el usuario)
