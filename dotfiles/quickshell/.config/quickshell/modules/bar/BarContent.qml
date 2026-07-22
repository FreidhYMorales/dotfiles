import Quickshell
import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    required property string screenName
    // This bar's own per-monitor palette — see Colours.paletteFor. Falls
    // back to the shared global palette on screens with no override.
    readonly property var colors: Colours.paletteFor(root.screenName)

    property bool _notifCornerFlat: false
    property bool _dashCornerFlat:  false

    Timer {
        id:       notifCornerTimer
        interval: 350
        onTriggered: root._notifCornerFlat = false
    }

    Timer {
        id:       dashCornerTimer
        interval: 500
        onTriggered: root._dashCornerFlat = false
    }

    Connections {
        target: Visibilities
        function onNotificationsChanged() {
            if (Visibilities.notifications) {
                notifCornerTimer.stop()
                root._notifCornerFlat = true
            } else {
                notifCornerTimer.restart()
            }
        }
        function onDashboardChanged() {
            if (Visibilities.dashboard) {
                dashCornerTimer.stop()
                root._dashCornerFlat = true
            } else {
                dashCornerTimer.restart()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius:            Style.cornerRadius
        bottomRightRadius: (Visibilities.notifToast || root._notifCornerFlat || root._dashCornerFlat) ? 0 : Style.cornerRadius
        color:             root.colors.m3surfaceContainer

        Behavior on color             { CAnim {} }
        Behavior on bottomRightRadius {
            NumberAnimation {
                duration: 350
                easing.type:         Easing.BezierSpline
                easing.bezierCurve:  [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
            }
        }
    }

    // Left: Launcher + Workspaces pill
    Rectangle {
        anchors {
            left:           parent.left
            verticalCenter: parent.verticalCenter
            leftMargin:     8
        }
        height: 26
        width:  leftPillRow.implicitWidth + 8
        radius: Style.cornerRadius
        // Same dark tone as the media-source selector pill (m3surfaceContainerLow)
        // — going lighter than the bar's own background made the pill
        // visible but broke the intended dark/moody look. A subtle outline
        // gives definition instead of relying on fill contrast, since the
        // bar's background is already too close in tone to any darker step.
        color:        root.colors.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.mid(root.colors.m3surfaceContainer, root.colors.m3surfaceContainerHigh)
        clip:   true
        Behavior on color  { CAnim {} }
        Behavior on width  { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Row {
            id:      leftPillRow
            anchors {
                left:           parent.left
                leftMargin:     4
                verticalCenter: parent.verticalCenter
            }
            spacing: 4

            LauncherButton   { standalone: false; colors: root.colors }
            WorkspacesWidget { colors: root.colors }
        }
    }

    // Center: Clock
    ClockWidget {
        anchors.centerIn: parent
        colors: root.colors
    }

    // Right: BgApps + system pill
    Row {
        anchors {
            right:          parent.right
            verticalCenter: parent.verticalCenter
            rightMargin:    8
        }
        spacing: 4

        BgAppsWidget   { colors: root.colors }
        CpuWidget      { colors: root.colors }
        RamWidget      { colors: root.colors }
        RecorderWidget { colors: root.colors }

        Rectangle {
            id:     rightPill
            height: 26
            width:  pillRow.implicitWidth + 8
            radius: Style.cornerRadius
            // Same dark tone as the media-source selector pill (m3surfaceContainerLow)
        // — going lighter than the bar's own background made the pill
        // visible but broke the intended dark/moody look. A subtle outline
        // gives definition instead of relying on fill contrast, since the
        // bar's background is already too close in tone to any darker step.
        color:        root.colors.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.mid(root.colors.m3surfaceContainer, root.colors.m3surfaceContainerHigh)
            Behavior on color { CAnim {} }
            Behavior on width {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            Row {
                id: pillRow
                anchors.centerIn: parent
                // spacing: 2

                VolumeWidget       { id: volWidget; standalone: false; colors: root.colors }
                BatteryWidget      { id: batWidget; standalone: false; colors: root.colors }
                BluetoothWidget    { standalone: false; colors: root.colors }
                WifiWidget         { standalone: false; colors: root.colors }
                NotificationButton { standalone: false; colors: root.colors }
                DashboardButton    { standalone: false; colors: root.colors }
            }
        }
    }

    Binding { target: Visibilities; property: "volumeBarCenterX"
              value: root.width - rightPill.width / 2 - pillRow.implicitWidth / 2 + volWidget.implicitWidth / 2 }
    Binding { target: Visibilities; property: "batteryBarCenterX"
              value: root.width - rightPill.width / 2 - pillRow.implicitWidth / 2 + volWidget.implicitWidth + batWidget.implicitWidth / 2 }
}
