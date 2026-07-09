-- Window/layer rules de end-4/dots-hyprland — referencia para Hyprland en Lua
-- Fuente: dots/.config/hypr/hyprland/rules.lua
-- Estas son las más útiles para extraer, adaptadas con comentarios.

-- ══════════════════════════════════════════════════════════
-- WINDOW RULES
-- ══════════════════════════════════════════════════════════

-- Diálogos de archivo flotantes (Open File, Save As, etc.)
hl.window_rule({match = {title = "^(Open File)(.*)$" },   center = true, float = true})
hl.window_rule({match = {title = "^(Select a File)(.*)$"},center = true, float = true})
hl.window_rule({match = {title = "^(Save As)(.*)$" },     center = true, float = true})
hl.window_rule({match = {title = "^(File Upload)(.*)$" }, center = true, float = true})
hl.window_rule({match = {title = "^(.*)(wants to save)$"},center = true, float = true})
hl.window_rule({match = {title = "^(.*)(wants to open)$"},center = true, float = true})
hl.window_rule({match = {title = "^(Library)(.*)$" },     center = true, float = true})

-- Pavucontrol flotante al 45% del monitor
hl.window_rule({match = {class = "^(pavucontrol)$" }, float = true})
hl.window_rule({match = {class = "^(pavucontrol)$" }, size = {"(monitor_w*0.45)", "(monitor_h*0.45)"}})
hl.window_rule({match = {class = "^(pavucontrol)$" }, center = true})

-- Ocultar ventanas que no deben verse sin matarlas
-- (más confiable que nofocus solo — útil para procesos de sistema)
hl.window_rule({match = {class = "^(plasma-changeicons)$"}, float = true})
hl.window_rule({match = {class = "^(plasma-changeicons)$"}, no_initial_focus = true})
hl.window_rule({match = {class = "^(plasma-changeicons)$"}, move = {999999, 999999}})

-- Picture-in-Picture — esquina inferior derecha al 25% del monitor
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"}, float = true})
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"}, keep_aspect_ratio = true})
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"}, pin = true})
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"}, move = {"(monitor_w*0.73)", "(monitor_h*0.72)"}})
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"}, size = {"(monitor_w*0.25)", "(monitor_h*0.25)"}})

-- Screen sharing — indicador centrado horizontalmente, pegado al fondo
hl.window_rule({match = {title = ".*is sharing (a window|your screen).*"}, float = true})
hl.window_rule({match = {title = ".*is sharing (a window|your screen).*"}, pin = true})
hl.window_rule({match = {title = ".*is sharing (a window|your screen).*"}, move = {"(monitor_w*.5-window_w*.5)", "(monitor_h-window_h-12)"}})

-- Tearing selectivo — solo para juegos/wine, no global
-- (global tearing rompe el compositor para uso normal)
hl.window_rule({match = {title = ".*\\.exe"      }, immediate = true})
hl.window_rule({match = {title = ".*minecraft.*" }, immediate = true})
hl.window_rule({match = {class = "^(steam_app).*"}, immediate = true})

-- Sin sombra en ventanas tileadas (ahorra composición)
hl.window_rule({match = {float = 0}, no_shadow = true})

-- ══════════════════════════════════════════════════════════
-- LAYER RULES — Quickshell namespaces
-- ══════════════════════════════════════════════════════════

-- xray global (permite ver a través de layers), luego desactivar para popups
hl.layer_rule({match = {namespace = ".*"},                  xray = true})
hl.layer_rule({match = {namespace = "quickshell:popup"},    xray = false})        -- fix colores raros en tooltips
hl.layer_rule({match = {namespace = "quickshell:popup"},    ignore_alpha = 1})    -- necesario además del xray

-- Blur para layers de Quickshell
hl.layer_rule({match = {namespace = "quickshell:.*"},       blur = true, blur_popups = true, ignore_alpha = 0.79})

-- Animaciones por namespace — cada surface de Quickshell tiene la suya
hl.layer_rule({match = {namespace = "quickshell:bar"},           animation = "slide"})
hl.layer_rule({match = {namespace = "quickshell:sidebarRight"},  animation = "slide right"})
hl.layer_rule({match = {namespace = "quickshell:sidebarLeft"},   animation = "slide left"})
hl.layer_rule({match = {namespace = "quickshell:cheatsheet"},    animation = "slide bottom"})
hl.layer_rule({match = {namespace = "quickshell:dock"},          animation = "slide bottom"})
hl.layer_rule({match = {namespace = "quickshell:osk"},           animation = "slide bottom"})
hl.layer_rule({match = {namespace = "quickshell:screenCorners"}, animation = "popin 120%"})
hl.layer_rule({match = {namespace = "quickshell:notificationPopup"}, animation = "fade"})
hl.layer_rule({match = {namespace = "quickshell:reloadPopup"},   animation = "slide"})

-- Sin animación para layers de rendimiento crítico
hl.layer_rule({match = {namespace = "quickshell:actionCenter"}, no_anim = true})
hl.layer_rule({match = {namespace = "quickshell:overview"},     no_anim = true})
hl.layer_rule({match = {namespace = "quickshell:session"},      no_anim = true})
hl.layer_rule({match = {namespace = "quickshell:osk"},          order = -1})

-- Blur para notificaciones y GTK layer shell
hl.layer_rule({match = {namespace = "notifications"},  blur = true, ignore_alpha = 0.69})
hl.layer_rule({match = {namespace = "gtk-layer-shell"}, blur = true, ignore_alpha = 0})
hl.layer_rule({match = {namespace = "logout_dialog"},  blur = true})

-- Launchers: sin animación (velocidad es prioridad)
hl.layer_rule({match = {namespace = "gtk4-layer-shell"}, no_anim = true})

-- ══════════════════════════════════════════════════════════
-- WORKSPACE RULES
-- ══════════════════════════════════════════════════════════

hl.workspace_rule({workspace = "special:special", gaps_out = 30})
