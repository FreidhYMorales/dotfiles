//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "utils"
import "services"
import "modules/background"
import "modules/bar"
import "modules/launcher"
import "modules/dashboard"
import "modules/lock"
import "modules/notifications"
import "modules/powermenu"
import "modules/screensaver"
ShellRoot {
    // NotificationServer must live here (ShellRoot) to register on DBus
    NotificationServer {
        keepOnReload:     true
        actionsSupported: true
        onNotification: notif => Notifs.receive(notif)
    }

    // Global keybinds via IPC — hyprland keybinds.lua:
    //   local qsIpc = "qs ipc -p /path/to/quickshell call"
    //   keybind(mainMod .. " + SPACE", exec(qsIpc .. " launcher toggle"),      descrip("Toggle Launcher"))
    //   keybind(mainMod .. " + D",     exec(qsIpc .. " dashboard toggle"),     descrip("Toggle Dashboard"))
    //   keybind(mainMod .. " + N",     exec(qsIpc .. " notifications toggle"), descrip("Toggle Notifications"))
    //   keybind(mainMod .. " + C",     exec(qsIpc .. " calendar toggle"),      descrip("Toggle Calendar"))
    IpcHandler {
        target: "launcher"
        function toggle() { Visibilities.toggle("launcher") }
    }
    IpcHandler {
        target: "dashboard"
        function toggle() { Visibilities.toggle("dashboard") }
    }
    IpcHandler {
        target: "notifications"
        function toggle() { Visibilities.toggle("notifications") }
    }
    IpcHandler {
        target: "calendar"
        function toggle() { Visibilities.toggle("calendar") }
    }
    IpcHandler {
        target: "powermenu"
        function toggle() { Visibilities.toggle("powerMenu") }
    }

    Background {}
    Bar {}
    Launcher {}
    Dashboard {}
    CalendarPopout {}
    Osd {}
    BatteryProfileOsd {}
    TrayMenuOsd {}
    RecorderModeOsd {}
    PowerMenuOsd {}
    NotifToast {}
    NotificationPanel {}
    ScreensaverPreview {}

    Lock {}

    // Fires once every module above has finished its initial construction —
    // useful after a reinstall/reboot to know the shell is actually up
    // without watching the terminal log. ShellRoot itself doesn't support
    // the Component attached property, so this lives on a plain child Item.
    Item {
        // The NotificationServer above registers on DBus asynchronously —
        // firing notify-send in the same tick as Component.onCompleted can
        // race ahead of that registration and get silently dropped. A short
        // delay is enough since registration only takes a moment.
        Timer {
            interval: 800
            running: true
            onTriggered: Quickshell.execDetached(
                ["notify-send", "-a", "Quickshell", "-i", "dialog-information", "Quickshell", "Shell loaded"])
        }
    }
}
