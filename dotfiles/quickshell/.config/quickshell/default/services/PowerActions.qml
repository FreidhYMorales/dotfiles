pragma Singleton
import Quickshell
import QtQuick

// Shared power-menu action list (poweroff/reboot/suspend/lock/logout) —
// previously duplicated verbatim in ProfileSection.qml and PowerMenuOsd.qml.
//
// Entries run either `cmd` (external process, via Quickshell.execDetached)
// or `action` (a same-process call) — never both. Lock uses `action` because
// this singleton already lives in the qs process Lock.qml listens on; there's
// no need to fork `qs ipc` just to talk to itself, unlike the Hyprland
// keybind that also triggers a lock (that one's a real separate process).
Singleton {
    readonly property var actions: [
        { icon: "󰐥", cmd: ["systemctl", "poweroff"] },
        { icon: "󰜉", cmd: ["systemctl", "reboot"] },
        { icon: "󰤄", cmd: ["systemctl", "suspend-then-hibernate"] },
        { icon: "󰌾", action: function() { Visibilities.requestLock(false) } },
        // This Hyprland build routes `dispatch` through a Lua bridge (hl.dispatch) —
        // bare dispatcher names like "exit" are no longer valid, only hl.dsp.* calls.
        { icon: "󰍃", cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] }
    ]
}
