pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// System information for display — exposes Caelestia-compatible string properties.
// For numeric CPU/RAM/Disk percentages, use services/SysInfo.qml.
Singleton {
    id: root

    property string osName:        "Arch Linux"
    property string osPrettyName:  "Arch Linux"
    property string osId:          "arch"
    property string osLogo:        ""
    property bool   isDefaultLogo: true
    property string wm:            Quickshell.env("XDG_CURRENT_DESKTOP") || "Hyprland"
    readonly property string user: Quickshell.env("USER")
    property string uptime:        ""
    property string kernel:        ""
    property string hostname:      ""

    FileView {
        path:     "/etc/os-release"
        onLoaded: {
            const lines  = text().split("\n")
            const fd     = key => lines.find(l => l.startsWith(key + "="))?.split("=")[1]?.replace(/"/g, "") ?? ""
            root.osName       = fd("NAME")       || "Arch Linux"
            root.osPrettyName = fd("PRETTY_NAME") || root.osName
            root.osId         = fd("ID")
            const logo = fd("LOGO")
            if (logo) {
                const resolved = Quickshell.iconPath(logo, true)
                if (resolved) {
                    root.osLogo      = resolved
                    root.isDefaultLogo = false
                }
            }
        }
    }

    FileView {
        path:     "/proc/sys/kernel/osrelease"
        onLoaded: root.kernel = text().trim()
    }

    FileView {
        path:     "/proc/sys/kernel/hostname"
        onLoaded: root.hostname = text().trim()
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: {
            const up      = parseInt(text().split(" ")[0] ?? 0)
            const days    = Math.floor(up / 86400)
            const hours   = Math.floor((up % 86400) / 3600)
            const minutes = Math.floor((up % 3600) / 60)
            let str = ""
            if (days    > 0) str += `${days}d `
            if (hours   > 0) str += `${hours}h `
            if (minutes > 0 || !str) str += `${minutes}m`
            root.uptime = str.trim()
        }
    }

    Timer {
        interval: 30000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: uptimeFile.reload()
    }
}
