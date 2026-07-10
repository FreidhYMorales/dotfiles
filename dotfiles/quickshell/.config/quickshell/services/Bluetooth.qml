pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool   powered:         false
    property bool   connected:        false
    property string connectedDevice:  ""

    Timer {
        interval: 3000
        running:  true
        repeat:   true
        triggeredOnStart: true
        onTriggered: {
            poweredProc.running   = true
            connectedProc.running = true
        }
    }

    Process {
        id: poweredProc
        command: ["bluetoothctl", "show"]

        property bool _powered: false

        onRunningChanged: {
            if (running) { _powered = false; return }
            root.powered = _powered
        }

        stdout: SplitParser {
            onRead: line => {
                if (line.includes("Powered:"))
                    poweredProc._powered = line.includes("yes")
            }
        }
    }

    Process {
        id: connectedProc
        command: ["bluetoothctl", "devices", "Connected"]

        property bool   _connected: false
        property string _device:    ""

        onRunningChanged: {
            if (running) { _connected = false; _device = ""; return }
            root.connected       = _connected
            root.connectedDevice = _device
        }

        stdout: SplitParser {
            onRead: line => {
                const trimmed = line.trim()
                if (trimmed.startsWith("Device ")) {
                    const parts = trimmed.split(" ")
                    if (parts.length >= 3) {
                        connectedProc._connected = true
                        if (connectedProc._device === "")
                            connectedProc._device = parts.slice(2).join(" ")
                    }
                }
            }
        }
    }
}
