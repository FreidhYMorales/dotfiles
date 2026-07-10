pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property alias lock: sessionLock

    // Set when the idle chain (services/IdleManager.qml) triggers the lock,
    // as opposed to a manual lock (dashboard button/keybind). LockSurface
    // uses it to keep showing the screensaver content instead of the theme's
    // own lock background until the first real input.
    property bool lockedViaIdle: false

    IpcHandler {
        target: "lock"
        function lock(): void {
            sessionLock.locked = true
        }
        function lockFromIdle(): void {
            lockedViaIdle = true
            sessionLock.locked = true
        }
    }

    WlSessionLock {
        id: sessionLock
        onLockedChanged: if (!locked) root.lockedViaIdle = false

        LockSurface {
            lock: sessionLock
            lockedViaIdle: root.lockedViaIdle
        }
    }
}

