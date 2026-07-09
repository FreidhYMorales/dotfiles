-- Envirorment Configs

-- Variables
local env = hl.env

-- Mouse
env("XCURSOR_SIZE", "24")
env("HYPRCURSOR_SIZE", "24")
env("env = LIBVIRT_DEFAULT_URI", "qemu:///system")

-- Force Term File Chooser
env("GTK_USE_PORTAL", "1")
env("QT_QPA_PLATFORMTHEME", "xdgdesktopportal")
