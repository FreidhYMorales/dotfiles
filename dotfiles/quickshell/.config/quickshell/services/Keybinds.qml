pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Live keybind cheatsheet data — reads Hyprland's own bind registry
// (`hyprctl binds -j`) instead of hand-copying dotfiles/hypr/deadlock/keybinds.lua
// into QML, which would drift out of sync with it exactly like docs/roadmap.md
// already did with the Bluetooth/Wifi widgets. Binds without a `descrip(...)`
// in keybinds.lua (workspace switching, XF86 media keys) come back with an
// empty description and are filtered out — self-evident/hardware binds don't
// need a cheatsheet entry.
Singleton {
    id: root

    property var entries: []

    function _modString(modmask) {
        const parts = []
        if (modmask & 4)  parts.push("Ctrl")
        if (modmask & 8)  parts.push("Alt")
        if (modmask & 1)  parts.push("Shift")
        if (modmask & 64) parts.push("Super")
        return parts.join(" + ")
    }

    function refresh() {
        bindsProc.running = true
    }

    Process {
        id: bindsProc
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            id: bindsStdout
            onStreamFinished: {
                try {
                    const data = JSON.parse(bindsStdout.text)
                    root.entries = data
                        .filter(b => b.description && b.description.length > 0)
                        .map(b => ({
                            mods:        root._modString(b.modmask),
                            key:         b.key,
                            description: b.description
                        }))
                } catch (e) {
                    console.warn("Keybinds: failed to parse hyprctl binds output:", e)
                }
            }
        }
    }

    Component.onCompleted: root.refresh()
}
