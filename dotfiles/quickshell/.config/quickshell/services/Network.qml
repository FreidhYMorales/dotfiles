pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool   connected: false
    property int    signal:    0
    property string ssid:      ""
    property string _iface:   "wlan0"

    Component.onCompleted: ifaceDiscoveryProc.running = true

    // Detects the wireless interface by checking which net device has a 'wireless' sysfs dir
    Process {
        id: ifaceDiscoveryProc
        command: ["bash", "-c", "for d in /sys/class/net/*/wireless; do basename \"$(dirname \"$d\")\" 2>/dev/null; done | head -1"]
        stdout: SplitParser {
            onRead: line => {
                const iface = line.trim()
                if (iface) root._iface = iface
            }
        }
    }

    Timer {
        interval: 3000
        running:  true
        repeat:   true
        triggeredOnStart: true
        onTriggered: networkProc.running = true
    }

    Process {
        id: networkProc
        command: ["iwctl", "station", root._iface, "show"]

        property bool   _connected: false
        property int    _signal:    0
        property string _ssid:      ""

        onRunningChanged: {
            if (running) {
                _connected = false
                _signal    = 0
                _ssid      = ""
                return
            }
            root.connected = _connected
            root.signal    = _signal
            root.ssid      = _ssid
        }

        stdout: SplitParser {
            onRead: line => {
                if (line.includes("Connected network")) {
                    const match = line.match(/Connected network\s+(.+?)\s*$/)
                    if (match) {
                        networkProc._ssid      = match[1].trim()
                        networkProc._connected = networkProc._ssid.length > 0
                    }
                } else if (line.includes("RSSI")) {
                    const match = line.match(/-?\d+/)
                    if (match) {
                        const rssi = parseInt(match[0])
                        networkProc._signal = Math.max(0, Math.min(100, Math.round((rssi + 90) / 60 * 100)))
                    }
                }
            }
        }
    }
}
