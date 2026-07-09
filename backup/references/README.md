# Referencias de Dotfiles

Dotfiles explorados como referencia para construir mis propios dots con Quickshell.
Cada entrada tiene un archivo de patterns + notas de lo que vale replicar.

---

## Evaluaciones completadas

### [Caelestia — config personal](caelestia/)

**Stack:** Arch Linux + Hyprland + Caelestia shell (Quickshell) + matugen  
**Explorado:** 2026-06-04 (config personal anterior — pre-reinstall)  
**Calidad:** Config propia ajustada, no upstream

**Top patterns:**
1. `cli.json postHook` — hook de theme-change para sincronizar apps externas
2. Multi-app theme sync en un script — Obsidian (multi-vault) + Notion/Zen en el mismo postHook
3. Live kitty reload via sockets — `kitten @ set-colors` sin reiniciar kitty
4. `AQ_NO_MODIFIERS=1` — fix crítico screencopy PipeWire en NVIDIA + Wayland
5. Headless monitor + workspace fijo — WinApps (RDP) en workspace 6 aislado
6. Idle chain escalonada — lock@3min → dpms off@5min → suspend-then-hibernate@10min
7. `app2unit --` en keybinds — cgroup tracking correcto para apps lanzadas desde Hyprland

**Archivos:**
- [`caelestia/caelestia-patterns-reference.md`](caelestia/caelestia-patterns-reference.md) — patterns de config personal (postHook, NVIDIA fixes, window rules, idle chain)
- [`caelestia/caelestia-shell-architecture.md`](caelestia/caelestia-shell-architecture.md) — arquitectura upstream completa (flujo de colores, IPC, drawers, Hyprland config)
- [`caelestia/caelestia-quickshell-patterns.md`](caelestia/caelestia-quickshell-patterns.md) — 13 patterns QML concretos con código para replicar en Quickshell propio
- [`caelestia/config/`](caelestia/config/) — config personal original completa

---

### [ii — illogical-impulse (end_4)](end-4/)

**Stack:** Arch Linux + Hyprland (Lua API) + Quickshell + matugen  
**Explorado:** 2026-06-04 (live desde `~/.config/`)  
**Calidad:** Production-grade, muy pulido

**Top patterns:**
1. `GlobalShortcut` + `hl.dsp.global()` — IPC desacoplado entre Hyprland y Quickshell
2. Pipeline matugen → `colors.json` → `FileView` en vivo (single source of truth para colores)
3. `colLayer0–4` — sistema de elevación semántica M3 con transparencia auto desde vibrancy
4. Fallback bind — cada keybind de QS tiene un companion para cuando QS se cae
5. `Config` singleton con `FileView` — hot-reload sin reiniciar Quickshell

**Archivos:**
- [`end-4/ii-shell-architecture.md`](end-4/ii-shell-architecture.md) — arquitectura completa: entry point, panel families, GlobalStates, visibilidad, Config/Persistent, namespaces
- [`end-4/ii-quickshell-patterns.md`](end-4/ii-quickshell-patterns.md) — 12 patterns QML concretos: colores, AnimatedTabIndexPair, tabs, bar, notifs, lock, animaciones, widgets
- [`end-4/ii-patterns-reference.md`](end-4/ii-patterns-reference.md) — Hyprland: IPC, keybinds Lua, bezier curves, layer rules, window rules
- [`end-4/ii-tools-reference.md`](end-4/ii-tools-reference.md) — stack de herramientas (core vs opcional)

---

## Próximas evaluaciones

Completar este listado cuando explore otros dotfiles. Usar el template para cada uno.

| Autor / Repo | Stack | Estado |
|---|---|---|
| — | — | pendiente |

---

## Visión y planning

- **[`quickshell-vision.md`](quickshell-vision.md)** — visión completa del Quickshell propio: bar layout, paneles, lock screen, arquitectura QML, decisiones clave.
- **[`quickshell-pending-plugins.md`](quickshell-pending-plugins.md)** — plugins C++/Rust pendientes de implementar: M3Shapes (MaterialShape), Tokens, Caelestia.Services. Incluye cómo implementarlos y cuándo activarlos.
- **[`quickshell-audit-2026-06.md`](quickshell-audit-2026-06.md)** — auditoría completa del proyecto vs Caelestia (2026-06-28): bugs, performance, arquitectura, plugins pendientes, lista de pendientes priorizada.

## Pipeline y estrategia

- **[`packages-reference.md`](packages-reference.md)** — lista completa de paquetes del sistema por categoría (pacman + AUR + yay), con one-liners y post-install checklist. Derivada de nvim, yazi, scripts y zsh configs.
- **[`matugen-pipeline-reference.md`](matugen-pipeline-reference.md)** — pipeline completo de colores: generación → scheme.json/colors.json → Quickshell, Hyprland, terminales, apps. Tokens M3, formato de templates, postHook, decisiones para dotfiles propios.
- **[`deploy-strategy.md`](deploy-strategy.md)** — estrategia de deploy con GNU Stow, estructura del repo, flujo de trabajo.

## Herramientas

- **[`dotfiles-evaluation-template.md`](dotfiles-evaluation-template.md)** — template para evaluar cualquier dotfiles nuevo.
  Rellenar una copia por dotfiles, guardar en `references/<autor>/`.

---

## Qué buscar en cualquier dotfiles nuevo

Las preguntas más importantes al explorar un dotfiles desconocido:

1. **¿Cómo habla el bar con el WM?** (polling vs IPC push)
2. **¿De dónde vienen los colores?** (matugen / pywal / manual) y cómo llegan a cada app
3. **¿Tiene un sistema de elevación de color?** (como colLayer0–4)
4. **¿Hay fallback si el bar se cae?**
5. **¿Qué está incompleto o es demasiado específico para replicar?**
