-- Environment Configs

local env = hl.env

-- Wayland session
env("XDG_SESSION_TYPE",                    "wayland")
env("XDG_CURRENT_DESKTOP",                "Hyprland")
env("XDG_SESSION_DESKTOP",                "Hyprland")

-- Toolkit backends (prefer Wayland, fall back to X11)
env("GDK_BACKEND",                         "wayland,x11,*")
env("SDL_VIDEODRIVER",                     "wayland")
env("QT_QPA_PLATFORM",                    "wayland;xcb")
env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
env("QT_QPA_PLATFORMTHEME",               "xdgdesktopportal")

-- Cursor
env("XCURSOR_SIZE",                        "24")
env("XCURSOR_THEME",                       "Nordzy-cursors")
env("HYPRCURSOR_SIZE",                     "24")
env("HYPRCURSOR_THEME",                    "Nordzy-hyprcursors")

-- Portals / GTK file chooser
env("GTK_USE_PORTAL",                      "1")

-- Misc
env("LIBVIRT_DEFAULT_URI",                "qemu:///system")
