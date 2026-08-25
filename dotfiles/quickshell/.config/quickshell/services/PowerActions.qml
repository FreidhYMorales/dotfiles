pragma Singleton
import Quickshell
import QtQuick

// Shared power-menu action list (poweroff/reboot/suspend/lock/logout) —
// previously duplicated verbatim in ProfileSection.qml and PowerMenuOsd.qml.
Singleton {
    readonly property var actions: [
        { icon: "󰐥", cmd: ["systemctl", "poweroff"] },
        { icon: "󰜉", cmd: ["systemctl", "reboot"] },
        { icon: "󰤄", cmd: ["systemctl", "suspend-then-hibernate"] },
        { icon: "󰌾", cmd: ["qs", "ipc", "-p", Quickshell.shellDir, "call", "lock", "lock"] },
        // This Hyprland build routes `dispatch` through a Lua bridge (hl.dispatch) —
        // bare dispatcher names like "exit" are no longer valid, only hl.dsp.* calls.
        { icon: "󰍃", cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] }
    ]
}
