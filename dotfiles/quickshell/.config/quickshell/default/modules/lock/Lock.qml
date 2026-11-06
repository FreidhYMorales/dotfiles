pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"

Scope {
    id: root

    property alias lock: sessionLock

    // Set when the idle chain (services/IdleManager.qml) triggers the lock,
    // as opposed to a manual lock (dashboard button/keybind). LockSurface
    // uses it to keep showing the screensaver content instead of the theme's
    // own lock background until the first real input.
    property bool lockedViaIdle: false

    function doLock(viaIdle) {
        lockedViaIdle = viaIdle
        sessionLock.locked = true
    }

    // External trigger only (Hyprland keybind: `qs ipc call lock lock`,
    // a separate process). Internal callers use Visibilities.requestLock()
    // below instead of forking `qs ipc` to talk to this same process.
    IpcHandler {
        target: "lock"
        function lock(): void {
            root.doLock(false)
        }
        function lockFromIdle(): void {
            root.doLock(true)
        }
    }

    Connections {
        target: Visibilities
        function onLockRequested(viaIdle) {
            root.doLock(viaIdle)
        }
    }

    WlSessionLock {
        id: sessionLock
        onLockedChanged: {
            Visibilities.locked = locked
            if (!locked) root.lockedViaIdle = false
        }

        LockSurface {
            lock: sessionLock
            lockedViaIdle: root.lockedViaIdle
        }
    }
}

