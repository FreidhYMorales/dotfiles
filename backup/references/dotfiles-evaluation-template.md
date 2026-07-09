# Dotfiles Evaluation Template

Fill this out when exploring a new dotfiles setup.
Goal: extract the patterns worth keeping, not a full inventory.

Completed evaluations:
- [ii (end_4)](end-4/ii-patterns-reference.md) — Hyprland + Quickshell + matugen

---

## Metadata

| Field | Value |
|---|---|
| **Author / Repo** | |
| **Explored on** | |
| **Base WM** | |
| **Shell / Bar** | |
| **Distro target** | |
| **Theme system** | |
| **Source** | `~/.config/` live / git clone / screenshot reverse-engineered |

---

## 1. Shell / Bar Architecture

**What handles the shell bar?**
> waybar / ags / eww / Quickshell / other

**Is it one process or multiple?**
> (e.g. ii: one Quickshell process handles bar + notifications + lock + sidebars)

**How does it communicate with the WM?**
- [ ] Hyprland socket / hyprctl polling
- [ ] `hl.dsp.global()` push (Quickshell GlobalShortcut)
- [ ] D-Bus
- [ ] Named pipe / IPC file
- [ ] None (reads config only)

**Is there a crash-resilience / fallback pattern?**
> (e.g. ii: `qsIsAlive || fuzzel-fallback` companion bind)

**Notes:**

---

## 2. Color / Theming System

**Color source:**
- [ ] matugen (M3 from wallpaper)
- [ ] pywal / wal (dominant colors from wallpaper)
- [ ] Manual palette
- [ ] Hard-coded per theme

**How do colors reach each app?**
```
Source →
  ├─► shell bar config: 
  ├─► Hyprland borders: 
  ├─► GTK:              
  ├─► terminal:         
  ├─► launcher:         
  └─► lock screen:      
```

**Is there a semantic elevation / layer system?**
> (e.g. ii: colLayer0–4, each computed via mix(), hover/active variants derived)

**Is there auto-transparency based on wallpaper?**
> (e.g. ii: quadratic formula from vibrancy value)

**Bootstrap order issues?**
> (e.g. ii: matugen must run before kde-material-you-colors or color.txt doesn't exist)

**Notes:**

---

## 3. Hyprland Config Structure

**Config format:**
- [ ] Raw hyprland.conf (declarative DSL)
- [ ] Lua API (`hl.*`)
- [ ] Mixed

**Override / customization layer?**
> (e.g. ii: upstream in `hyprland/`, user in `custom/` — never edit upstream files)

**Keybind layer philosophy:**

| Modifier | Domain |
|---|---|
| `SUPER` | |
| `SUPER+SHIFT` | |
| `SUPER+ALT` | |
| `CTRL+SUPER` | |
| Tap `SUPER` | |

**Blur strategy:**
- [ ] Blur on all windows
- [ ] Blur only on layer-shell surfaces (shell/bar)
- [ ] No blur

**Tearing:**
- [ ] Global allow_tearing
- [ ] Opt-in via window rule (`immediate`)
- [ ] Not configured

**Interesting window rules:**

**Notes:**

---

## 4. Animation System

**Bezier curves defined:**

| Name | Points | Used for |
|---|---|---|
| | | |

**Key animation decisions:**
> (e.g. ii: `stall` on fadeLayersOut creates hang-then-disappear feel; `menu_decel` speed 7 on workspaces = instant-feeling slide)

**Notes:**

---

## 5. Startup / Boot Sequence

**Order of exec-once / execs:**
```
1. 
2. 
3. 
4. 
```

**Any dependency order gotchas?**
> (e.g. ii: dbus-update-activation-environment must run before apps that need D-Bus activation)

**Notes:**

---

## 6. Scripts Worth Stealing

| Script | What it does | Location |
|---|---|---|
| | | |

---

## 7. Config Portability

**Does it work on a fresh install or does it require prior setup?**

**Missing pieces on first boot:**
> (e.g. ii: matugen never run → all colors are fallback; no monitor config → auto-detect only)

**Does it use git submodules or external deps?**

**Notes:**

---

## 8. Interesting Patterns (non-obvious decisions)

List anything that surprised you or that you wouldn't have thought of yourself.

- 
- 
- 

---

## 9. What NOT to replicate

List anything that's too specific, too heavy, or too opinionated to port to your own setup.

- 
- 

---

## 10. What to read first in the source

| File / Path | Why |
|---|---|
| | |

---

## Verdict

**Overall quality:**
- [ ] Production-grade, very polished
- [ ] Good ideas, rough edges
- [ ] Interesting for specific patterns only
- [ ] Not worth referencing

**Top 3 patterns to bring to your own dots:**
1. 
2. 
3. 

**Reference file created at:**
> `references/<author>/<name>-patterns-reference.md`
