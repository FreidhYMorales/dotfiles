import QtQuick
import "../../services"
import "../../components"

Item {
    id: root
    implicitWidth:  Math.max(26, row.implicitWidth) + (standalone ? 16 : 0)
    implicitHeight: 26

    property bool standalone:   true
    property bool showPercent:  Battery.charging
    property real prevPercent: Battery.percentage
    // Per-monitor palette (bar/panels only — see Colours.paletteFor).
    // Defaults to the shared global palette so this widget still works
    // wherever else it might be instantiated without a screen context.
    property var  colors:      Colours.palette

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: { if (!Battery.charging) root.showPercent = false }
    }

    Connections {
        target: Battery
        function onChargingChanged() {
            root.showPercent = Battery.charging
        }
        function onPercentageChanged() {
            const thresholds = [75, 50, 25]
            const prev = root.prevPercent
            const cur  = Battery.percentage
            const crossed = thresholds.some(t =>
                (prev > t && cur <= t) || (prev < t && cur >= t)
            )
            root.prevPercent = cur
            if (crossed && !Battery.charging) {
                root.showPercent = true
                hideTimer.restart()
            }
        }
    }

    function updateCenterX() {
        if (!standalone) return
        Visibilities.batteryBarCenterX = 8 + mapToItem(null, implicitWidth / 2, 0).x
    }
    Component.onCompleted:  Qt.callLater(updateCenterX)
    onXChanged:             Qt.callLater(updateCenterX)
    onImplicitWidthChanged: Qt.callLater(updateCenterX)

    Rectangle {
        anchors.fill: parent
        visible:      root.standalone
        radius:       height / 2
        color:        root.colors.m3surfaceContainerHigh
        Behavior on color { CAnim {} }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Battery.charging        ? "󰂄" :
                  Battery.percentage > 80 ? "󰁹" :
                  Battery.percentage > 50 ? "󰂀" :
                  Battery.percentage > 20 ? "󰁾" : "󰁺"
            color:          Battery.percentage < 20 && !Battery.charging ? root.colors.m3error : root.colors.m3onSurface
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 13
            Behavior on color { CAnim {} }
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width:  root.showPercent ? percentText.implicitWidth + 10 : 0
            height: percentText.implicitHeight
            clip:   true
            Behavior on width {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            Text {
                id: percentText
                anchors { left: parent.left; leftMargin: 5; verticalCenter: parent.verticalCenter }
                text:           Battery.percentage + "%"
                color:          Battery.percentage < 20 && !Battery.charging ? root.colors.m3error : root.colors.m3onSurface
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 12
                Behavior on color { CAnim {} }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked:    Visibilities.toggle("batteryProfile")
    }
}
