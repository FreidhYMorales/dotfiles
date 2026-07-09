# ii (illogical-impulse) — Reference Patterns

Patterns and decisions from end_4's ii framework worth replicating in a custom dotfiles setup.
Explored live from `~/.config/` on 2026-06-04.

> All values here are extracted from the actual running config — not docs, not README.
> Source files: `~/.config/hypr/hyprland/general.lua`, `variables.lua`, `rules.lua`, `keybinds.lua`

---

## What ii is

A comprehensive Hyprland + Quickshell framework. Quickshell handles everything above the WM:
bar, sidebars, notifications, lock screen, launcher integration, clipboard UI, OSD, polkit,
session menu, wallpaper selector. No waybar, no ags, no eww — one process.

The Hyprland config is written in Lua via the `hl.*` API, not raw hyprland.conf DSL.

**Entry points:**
- `~/.config/hypr/hyprland.lua` — Hyprland
- `~/.config/quickshell/ii/shell.qml` — Quickshell
- `~/.config/quickshell/ii/modules/config/` — Config, Appearance, GlobalStates singletons

---

## Pattern 1 — Hyprland ↔ Quickshell IPC (the most important one)

Hyprland and Quickshell are fully decoupled. Hyprland pushes events; Quickshell reacts.
No polling, no hyprctl queries from the bar.

**Quickshell side** — declare a `GlobalShortcut`:
```qml
GlobalShortcut {
    name: "sidebarRightToggle"
    onPressed: sidebarRight.open = !sidebarRight.open
}
```

**Hyprland side** — bind to `hl.dsp.global()`:
```lua
hl.bind("SUPER + R", hl.dsp.global("quickshell:sidebarRightToggle"))
```

The namespace prefix (`quickshell:`) is just a convention to avoid collisions with other global shortcut clients.

**Full list of globals in ii:**
`searchToggleRelease`, `workspaceNumber`, `overviewWorkspacesToggle`, `overviewClipboardToggle`,
`overviewEmojiToggle`, `sidebarLeftToggle`, `sidebarLeftToggleDetach`, `sidebarRightToggle`,
`cheatsheetToggle`, `oskToggle`, `mediaControlsToggle`, `overlayToggle`, `sessionToggle`,
`barToggle`, `wallpaperSelectorToggle`, `wallpaperSelectorRandom`, `toggleLightDark`,
`panelFamilyCycle`, `regionScreenshot`, `regionSearch`, `regionOcr`, `screenTranslate`,
`regionRecord`, `lock`, `lockFocus`.

---

## Pattern 2 — Fallback bind (crash resilience)

Every Quickshell IPC keybind has a companion fallback for when Quickshell is dead.

```lua
local qsIsAlive = "qs -c $qsConfig ipc call TEST_ALIVE"

-- primary: tell Quickshell to open clipboard UI
hl.bind("SUPER + V", hl.dsp.global("quickshell:overviewClipboardToggle"))

-- fallback: if qs is dead, use fuzzel directly
hl.bind("SUPER + V", hl.dsp.exec_cmd(
    qsIsAlive .. " || pkill fuzzel || cliphist list | fuzzel --dmenu | wl-copy"
))
```

Hyprland runs both binds — the IPC one fires if qs responds, the fallback fires if it doesn't.
The system keeps working through Quickshell crashes.

---

## Pattern 3 — matugen color pipeline (single source of truth)

One wallpaper → every app updated atomically.

```
Wallpaper path
  └─► matugen apply --wallpaper <path>
        ├─► ~/.local/state/quickshell/user/generated/colors.json     ← Quickshell reads this live
        ├─► ~/.config/hypr/hyprland/colors.lua                       ← border/active colors
        ├─► ~/.config/hypr/hyprlock/colors.conf                      ← lock screen
        ├─► ~/.config/fuzzel/fuzzel_theme.ini                        ← launcher
        ├─► ~/.config/gtk-3.0/gtk.css                                ← GTK apps
        ├─► ~/.config/gtk-4.0/gtk.css
        └─► ~/.local/state/quickshell/user/generated/color.txt       ← accent hex (one line)

color.txt
  └─► kde-material-you-colors-wrapper.sh
        └─► kde-material-you-colors (Python venv)
              ├─► Kvantum Qt theme
              └─► icon theme toggle (breeze-plus / breeze-plus-dark)
```

**Bootstrap order matters:** matugen must run BEFORE kde-material-you-colors.
`color.txt` must exist for the Python script to start.

**To bootstrap from scratch:**
```bash
matugen apply --wallpaper ~/path/to/wallpaper.jpg
```

In ii, wallpaper switching is `quickshell/ii/scripts/colors/switchwall.sh` — wraps matugen and
triggers a Quickshell reload.

---

## Pattern 4 — Semantic color elevation (colLayer0–4)

Instead of hardcoding colors, ii uses Material 3 elevation layers.
`colLayer0` is the base surface; `colLayer4` is the highest elevation (modals, tooltips).

```qml
// Appearance.qml (simplified concept)
property color colLayer0: matugenColors.surface
property color colLayer1: ColorUtils.mix(colLayer0, primary, 0.05)
property color colLayer2: ColorUtils.mix(colLayer0, primary, 0.08)
property color colLayer3: ColorUtils.mix(colLayer0, primary, 0.11)
property color colLayer4: ColorUtils.mix(colLayer0, primary, 0.12)

// Hover and active states computed, not hardcoded
property color colLayer1Hover:  ColorUtils.mix(colLayer1, colOnLayer0, 0.08)
property color colLayer1Active: ColorUtils.mix(colLayer1, colOnLayer0, 0.12)
```

Transparency is auto-calculated from wallpaper vibrancy:
```
alpha = 0.5768 * vibrancy² - 0.759 * vibrancy + 0.2896
alpha = clamp(alpha, 0, 0.22) - 0.12 (light mode)
```

This means the bar becomes more transparent on vibrant wallpapers and more opaque on muted ones.

---

## Pattern 5 — Config singleton with live hot-reload

User config is a JSON file, read live via `FileView + JsonAdapter`. Changes on disk
reload without restarting Quickshell.

```qml
// Config.qml (simplified)
pragma Singleton

FileView {
    path: Directories.configFile   // ~/.config/illogical-impulse/config.json
    onLoaded: JsonAdapter.applyConfig(text)
}

// Usage anywhere in QML:
Config.options.bar.height       // 40
Config.options.bar.cornerStyle  // "float"
```

This pattern is worth replicating for any per-user settings that change often (opacity,
bar height, workspace count, etc.) — avoids a full qs restart for minor tweaks.

---

## Pattern 6 — Persistent singleton tracks Hyprland instance

```qml
// Persistent.qml (simplified)
pragma Singleton

property string hyprlandSignature: ""   // read from HYPRLAND_INSTANCE_SIGNATURE

Component.onCompleted: {
    if (hyprlandSignature !== Hyprland.instanceSignature) {
        // Hyprland restarted (not just qs reload) — reset workspace state
        resetWorkspaceState()
        hyprlandSignature = Hyprland.instanceSignature
    }
}
```

Distinguishes between `qs restart` (just Quickshell reloaded, preserve UI state) and
a full Hyprland restart (reset everything). Without this, workspaces remember stale state.

---

## Pattern 7 — Blur only on layer-shell surfaces

ii disables blur on ALL windows, enables it only on Quickshell layer-shell surfaces.

```lua
-- Disable blur everywhere
hl.window_rule({ match = { class = ".*" }, no_blur = true })

-- Re-enable only on specific Quickshell namespaces
hl.layer_rule({ match = { namespace = "quickshell:sidebarLeft" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:notificationPopup" }, blur = true })
-- ...25+ namespace rules total
```

Result: windows render without blur overhead; the shell UI gets blur. Big perf gain
and cleaner visual separation between app content and shell chrome.

---

## Pattern 8 — Workspace groups (infinite named workspaces)

Instead of static workspaces 1–10, ii uses groups of 10.
Number keys become relative to the current group.

```lua
-- Simplified concept
local function workspace_in_group(n)
    local current_group = math.floor((active_workspace - 1) / 10)
    return current_group * 10 + n
end

-- Bind: SUPER+1 goes to workspace 1 in current group
for i = 1, 10 do
    hl.bind("SUPER " .. i, hl.dispatch.workspace(workspace_in_group(i)))
end

-- SUPER+] next group, SUPER+[ previous group
```

This means you get infinite named workspace groups without remembering workspace numbers.

---

## Pattern 9 — Lua Hyprland config (composable, not DSL)

The `hl.*` API wraps hyprland.conf generation. Instead of static key = value pairs,
you write composable functions.

```lua
-- Concise window rule
hl.window_rule({ match = { class = "kitty" }, opacity = 0.92 })

-- Composable keybind
local apps = { "kitty", "foot", "alacritty" }
hl.bind("SUPER + T", hl.dsp.exec_cmd(launch_first_available(apps)))

-- Dynamic animation based on workspace direction
hl.animation({ name = "workspaces", style = "slide", direction = get_swipe_dir() })
```

The full Lua API is in `~/.config/hypr/hyprland/` — worth reading as a reference for
how to structure a custom Lua wrapper if you want similar composability.

---

## Pattern 10 — launch_first_available (portability)

```bash
#!/usr/bin/env bash
# Tries each command in order, launches first available
for cmd in "$@"; do
    if command -v "$cmd" &>/dev/null; then
        exec "$cmd"
    fi
done
```

Use case: `launch_first_available.sh kitty foot alacritty` — works on any machine
regardless of which terminal is installed. Good for configs shared across machines.

---

## Pattern 11 — Clipboard hooked into Quickshell service

```bash
# In startup execs:
wl-paste --watch sh -c 'cliphist store; qs ipc call cliphistService update'
```

Every copy triggers both cliphist (persistence) and a Quickshell IPC call (UI sync).
No polling. The bar clipboard count is always accurate.

---

## Keybind layer structure (worth replicating)

| Modifier | Domain |
|---|---|
| `SUPER` | Focus, workspace navigation, app launch, shell panels |
| `SUPER+SHIFT` | Window operations (move, resize, float, pin, kill) |
| `SUPER+ALT` | Send window to workspace (silently) |
| `CTRL+SUPER` | Compositor controls, shell restart, system |
| `SUPER` tap (release bind) | Search toggle |

Release binds for toggles: use `bindrt` (release + trigger) for `SUPER` tap so it doesn't
conflict with held `SUPER+<key>` combos.

---

## Font stack (ii choices)

| Font | Role |
|---|---|
| Google Sans Flex (variable) | Primary UI — 6-axis variable font |
| JetBrains Mono NF | Monospace + nerd icon glyphs |
| Material Symbols Rounded | Icon font inside Quickshell widgets |
| Readex Pro | Reading / paragraphs |
| Space Grotesk | Expressive / headings |

Note: Google Sans Flex is distributed as a git submodule in the ii repo.
Fonts must be installed before first Quickshell launch or all UI text is blank.

---

## Tearing config (games/video)

```lua
-- Global: allow tearing
hl.config({ general = { allow_tearing = true } })

-- Only apply immediate (full tearing) to specific classes
hl.window_rule({ match = { class = "*.exe" }, immediate = true })
hl.window_rule({ match = { class = "minecraft*" }, immediate = true })
```

Tearing is opt-in per window, not global. Normal apps are unaffected.

---

## Things NOT worth replicating from ii

- **geoclue agent** — only needed if using location-aware features (time-based theming)
- **The full Python venv for kde-material-you-colors** — heavy setup for Qt theming;
  skip if you don't need Qt app integration
- **Video wallpaper via mpvpaper** — high battery/CPU cost; only if you really want it
- **WinApps** — KVM/RDP bridge for Windows apps; very specific use case
- **All AI Neovim plugins simultaneously** — avante + claudecode + codecompanion +
  copilot + gemini is overkill; pick 1-2 that fit your workflow

---

---

## M3 Expressive bezier curves (exact values from general.lua)

These took time to tune. Copy verbatim.

```lua
hl.curve("expressiveFastSpatial",    { type="bezier", points={{0.42,1.67},{0.21,0.90}} })
hl.curve("expressiveSlowSpatial",    { type="bezier", points={{0.39,1.29},{0.35,0.98}} })
hl.curve("expressiveDefaultSpatial", { type="bezier", points={{0.38,1.21},{0.22,1.00}} })
hl.curve("emphasizedDecel",          { type="bezier", points={{0.05,0.7},{0.1,1}}      })
hl.curve("emphasizedAccel",          { type="bezier", points={{0.3,0},{0.8,0.15}}      })
hl.curve("standardDecel",            { type="bezier", points={{0,0},{0,1}}             })
hl.curve("menu_decel",               { type="bezier", points={{0.1,1},{0,1}}           })
hl.curve("menu_accel",               { type="bezier", points={{0.52,0.03},{0.72,0.08}} })
hl.curve("stall",                    { type="bezier", points={{1,-0.1},{0.7,0.85}}     })
```

**Animation assignments** (which curve goes where):

| Target | In | Out | Speed |
|---|---|---|---|
| Windows | `emphasizedDecel` popin 80% | `emphasizedDecel` popin 90% | 3 / 2 |
| Layers (shell panels) | `emphasizedDecel` popin 93% | `menu_accel` popin 94% | 2.7 / 2.4 |
| Fade layers in/out | `menu_decel` | `stall` | 0.5 / 2.7 |
| Workspaces | `menu_decel` slide | — | 7 |
| Special workspace | `emphasizedDecel` slidevert | `emphasizedAccel` slidevert | 2.8 / 1.2 |
| Border | `emphasizedDecel` | — | 10 |
| Zoom | `standardDecel` | — | 3 |

**Key insight:** `stall` on fadeLayersOut creates the "hang then fast disappear" feel for panels.
`menu_decel` on workspaces (speed 7) is what makes the slide feel instant but not jarring.

---

## Visual tuning values (exact from general.lua)

```lua
-- Rounding
rounding       = 18
rounding_power = 2.5   -- 2=circle, higher=squircle. Author explicitly calls squircles "Apple brainrot"

-- Blur (applied only to layer-shell, not windows)
blur = {
    size              = 10,
    passes            = 3,
    brightness        = 1,
    noise             = 0.05,
    contrast          = 0.89,
    vibrancy          = 0.5,
    vibrancy_darkness = 0.5,
    xray              = true,   -- layer blurs through to wallpaper, not through windows
    popups            = false,
}

-- Shadow (tiled windows get no_shadow rule — only floating)
shadow = { range=20, offset={0,2}, render_power=10, color="rgba(00000020)" }

-- Dim
dim_inactive = true
dim_strength = 0.05    -- subtle, just enough to distinguish focus
dim_special  = 0.2

-- Gaps
gaps_in         = 4
gaps_out        = 5
gaps_workspaces = 50   -- large gap between workspace groups in overview
```

---

## App launching pattern (variables.lua)

Every app category uses `launch_first_available.sh` with a priority-ordered fallback list.

```lua
terminal     = "launch_first_available.sh 'foot' 'kitty -1' 'alacritty' 'wezterm' ..."
fileManager  = "launch_first_available.sh 'dolphin' 'nautilus' 'nemo' 'thunar' 'kitty -1 fish -c yazi'"
browser      = "launch_first_available.sh 'google-chrome-stable' 'zen-browser' 'firefox' 'brave' ..."
codeEditor   = "launch_first_available.sh 'windsurf' 'code' 'codium' 'cursor' 'zed' 'command -v nvim && kitty -1 nvim'"
settingsApp  = "XDG_CURRENT_DESKTOP=gnome launch_first_available.sh 'qs -p .../settings.qml' 'systemsettings' 'gnome-control-center'"
```

Note: `settingsApp` overrides `XDG_CURRENT_DESKTOP=gnome` inline so gnome-control-center opens
correctly even on a Hyprland session.

---

## Layer rules for Quickshell namespaces (exact from rules.lua)

Each Quickshell surface gets its own namespace-scoped rules.

```lua
-- Global: all quickshell surfaces get blur + blur_popups
hl.layer_rule({ match={namespace="quickshell:.*"}, blur=true, blur_popups=true, ignore_alpha=0.79 })

-- Per-surface animations
hl.layer_rule({ match={namespace="quickshell:bar"},            animation="slide"        })
hl.layer_rule({ match={namespace="quickshell:sidebarLeft"},    animation="slide left"   })
hl.layer_rule({ match={namespace="quickshell:sidebarRight"},   animation="slide right"  })
hl.layer_rule({ match={namespace="quickshell:cheatsheet"},     animation="slide bottom" })
hl.layer_rule({ match={namespace="quickshell:dock"},           animation="slide bottom" })
hl.layer_rule({ match={namespace="quickshell:osk"},            animation="slide bottom" })
hl.layer_rule({ match={namespace="quickshell:screenCorners"},  animation="popin 120%"   })
hl.layer_rule({ match={namespace="quickshell:notificationPopup"}, animation="fade"      })
hl.layer_rule({ match={namespace="quickshell:wallpaperSelector"}, animation="slide top" })

-- No animation (must be instant)
hl.layer_rule({ match={namespace="quickshell:actionCenter"},   no_anim=true })
hl.layer_rule({ match={namespace="quickshell:overview"},       no_anim=true })
hl.layer_rule({ match={namespace="quickshell:polkit"},         no_anim=true })
hl.layer_rule({ match={namespace="quickshell:session"},        no_anim=true })
hl.layer_rule({ match={namespace="quickshell:regionSelector"}, no_anim=true })

-- Special: popup and mediaControls need ignore_alpha=1 to avoid color bleed through bar
hl.layer_rule({ match={namespace="quickshell:popup"},          ignore_alpha=1, xray=false })
hl.layer_rule({ match={namespace="quickshell:mediaControls"},  ignore_alpha=1 })
```

**Pattern:** surfaces that RESPOND to user input (sidebars, cheatsheet) get slide animations.
Surfaces that APPEAR without user intent (notifications, OSD) get fade or no_anim.
Overlays and lock-related surfaces always get no_anim (latency matters more than beauty).

---

## Window rules worth replicating (from rules.lua)

```lua
-- File dialogs: always float + center (covers most apps)
hl.window_rule({match={title="^(Open File)(.*)$"},    float=true, center=true})
hl.window_rule({match={title="^(Save As)(.*)$"},      float=true, center=true})
hl.window_rule({match={title="^(File Upload)(.*)$"},  float=true, center=true})

-- Picture-in-Picture: pin + keep aspect + position bottom-right
hl.window_rule({match={title="^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"},
    float=true, pin=true, keep_aspect_ratio=true,
    move={"(monitor_w*0.73)", "(monitor_h*0.72)"},
    size={"(monitor_w*0.25)", "(monitor_h*0.25)"}
})

-- Screen sharing indicator: pin + bottom-center
hl.window_rule({match={title=".*is sharing (a window|your screen).*"},
    float=true, pin=true,
    move={"(monitor_w*.5-window_w*.5)", "(monitor_h-window_h-12)"}
})

-- Hide plasma-changeicons window (kde-material-you-colors spawns it on theme change)
hl.window_rule({match={class="^(plasma-changeicons)$"},
    float=true, no_initial_focus=true, move={999999,999999}
})

-- No shadow on tiled windows (shadow only makes sense for floating)
hl.window_rule({match={float=0}, no_shadow=true})

-- Tearing: opt-in per class, not global
hl.window_rule({match={title=".*\\.exe"},          immediate=true})
hl.window_rule({match={class="^(steam_app).*"},    immediate=true})
```

---

## Input tuning (exact from general.lua)

```lua
input = {
    repeat_delay = 250,   -- ms before key repeat starts (default 600 — this is much faster)
    repeat_rate  = 35,    -- repeats per second

    touchpad = {
        natural_scroll     = true,
        clickfinger_behavior = true,   -- 2-finger = right click, 3-finger = middle click
        scroll_factor      = 0.7,      -- slightly slower than default
    },

    follow_mouse         = 1,          -- focus follows mouse
    off_window_axis_events = 2,        -- allow scrolling outside focused window edge
}

misc = {
    animate_manual_resizes      = false,   -- resizing is snappier without animation
    animate_mouse_windowdragging = false,  -- dragging too
    vrr                         = 0,       -- VRR off (use per-window tearing instead)
    on_focus_under_fullscreen   = 2,       -- focus stealer raises above fullscreen
    focus_on_activate           = true,
    initial_workspace_tracking  = false,   -- don't remember which workspace apps were on
}

binds = {
    scroll_event_delay          = 0,       -- no delay between scroll events
    hide_special_on_workspace_change = true,
}
```

---

## What to read in the ii source

| File | Why |
|---|---|
| `~/.config/quickshell/ii/modules/config/Appearance.qml` | Full M3 color system + elevation layers |
| `~/.config/quickshell/ii/modules/config/Config.qml` | Live hot-reload config pattern |
| `~/.config/quickshell/ii/modules/config/GlobalStates.qml` | Panel open/close state management |
| `~/.config/quickshell/ii/modules/config/Persistent.qml` | Hyprland instance tracking pattern |
| `~/.config/hypr/hyprland/keybinds.lua` | Full keybind structure + fallback pattern |
| `~/.config/hypr/hyprland/rules.lua` | Blur strategy, tearing, float rules |
| `~/.config/hypr/hyprland/general.lua` | All bezier curves + animation assignments |
| `~/.config/quickshell/ii/modules/common/widgets/` | Widget library (80+ QML components) |
