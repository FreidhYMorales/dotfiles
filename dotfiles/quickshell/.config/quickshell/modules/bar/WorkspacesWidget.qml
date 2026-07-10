pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../services"
import "../../components"

Row {
    id: wsRow
    spacing: 5

    // Per-monitor palette (bar/panels only — see Colours.paletteFor).
    // Defaults to the shared global palette so this widget still works
    // wherever else it might be instantiated without a screen context.
    property var colors: Colours.palette

    // Probe: Repeater over Hyprland.workspaces gives reactive .count
    // AND lets us read workspace IDs via itemAt(i).wsId — avoids broken [i] access on ObjectModel
    Repeater {
        id: occupancyRepeater
        model: Hyprland.workspaces
        delegate: Item {
            required property var modelData
            property int wsId: modelData.id
            visible: false; width: 0; height: 0
        }
    }

    property int maxVisible: {
        let max = 5
        const active = Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1
        if (active > max) max = active
        for (let i = 0; i < occupancyRepeater.count; i++) {
            const item = occupancyRepeater.itemAt(i)
            if (item && item.wsId > max) max = item.wsId
        }
        return max
    }

    function wsOccupied(num) {
        for (let i = 0; i < occupancyRepeater.count; i++) {
            const item = occupancyRepeater.itemAt(i)
            if (item && item.wsId === num) return true
        }
        return false
    }

    Repeater {
        model: wsRow.maxVisible
        delegate: Item {
            required property int index

            property bool isActive: (Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1) === (index + 1)
            property bool isOccupied: {
                const _ = occupancyRepeater.count
                return wsRow.wsOccupied(index + 1)
            }

            implicitWidth:  isActive ? 28 : 22
            implicitHeight: 26

            Behavior on implicitWidth { NumberAnimation { duration: 120; easing.type: Easing.InOutCubic } }

            Text {
                anchors.centerIn: parent
                text:           parent.isActive   ? "●" :
                                parent.isOccupied ? "○" : "—"
                color:          parent.isActive   ? wsRow.colors.m3primary :
                                parent.isOccupied ? wsRow.colors.m3onSurfaceVariant :
                                                    Qt.alpha(wsRow.colors.m3onSurface, 0.3)
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: parent.isActive ? 34 : parent.isOccupied ? 26 : 20
                Behavior on color          { CAnim {} }
                Behavior on font.pixelSize { NumberAnimation { duration: 120; easing.type: Easing.InOutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                // Hyprland.dispatch() sends a plain "workspace N" dispatch,
                // but this Hyprland build routes ALL dispatches through a
                // Lua bridge (hl.dsp.*) — bare dispatcher names are dead,
                // same issue already fixed for Lock/Logout in
                // modules/dashboard/ProfileSection.qml/SessionSection.qml.
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch",
                    "hl.dsp.focus({workspace=" + (parent.index + 1) + "})"])
            }
        }
    }
}
