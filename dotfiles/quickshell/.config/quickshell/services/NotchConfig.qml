pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../utils"

// Persisted notch layout preference (Phase 9+: whether the notch reserves
// live screen space via WlrLayershell.exclusiveZone or floats over content
// instead). Mirrors IdleManager.qml's persistence mechanism exactly
// (~/.local/state/quickshell/notch.json) — same mkdir -p Process +
// watchChanges:false FileView + _restored gate shape, just for one bool.
Singleton {
    id: root

    property bool reserveSpace: false

    // --- persistence (~/.local/state/quickshell/notch.json) ---
    property bool _restored: false

    onReserveSpaceChanged: if (_restored) _persist()

    Process {
        id: mkStateDirProc
        command: ["mkdir", "-p", Paths.appState]
    }

    FileView {
        id: stateFile
        path: Paths.notchStatePath
        watchChanges: false
        onLoaded: {
            try {
                const saved = JSON.parse(text())
                if (saved.reserveSpace !== undefined) root.reserveSpace = saved.reserveSpace
            } catch (e) {
                console.warn("NotchConfig: failed to parse notch state:", e)
            }
            root._restored = true
        }
        onLoadFailed: root._restored = true
    }

    function _persist() {
        mkStateDirProc.running = true
        stateFile.setText(JSON.stringify({
            reserveSpace: root.reserveSpace
        }))
    }

    Component.onCompleted: mkStateDirProc.running = true
}
