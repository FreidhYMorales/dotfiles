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
        border.width: 2
        border.color: Qt.alpha(root.colors.m3primary, 0.9)

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
        id: leftPill
        anchors {
            left:           parent.left
            verticalCenter: parent.verticalCenter
            leftMargin:     2
        }
        height: root.height - 4
        width:  leftPillRow.implicitWidth + 8
        radius: Style.cornerRadius
        color:        "transparent"
        border.width: 2
        antialiasing:  false
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
            PillDivider { pillHeight: leftPill.height; colors: root.colors }
            WorkspacesWidget { colors: root.colors }
            SpecialWorkspacesWidget { colors: root.colors }
        }
    }

    // Center: Clock
    ClockWidget {
        anchors.centerIn: parent
        height: root.height - 4
        colors: root.colors
    }

    // Middle-right: BgApps/CPU/RAM/Recorder pill. Right: system pill
    Row {
        anchors {
            right:          parent.right
            verticalCenter: parent.verticalCenter
            rightMargin:    2
        }
        spacing: 0

        Rectangle {
            id:     midPill
            height: root.height - 4
            width:  midPillRow.implicitWidth + 8
            radius: Style.cornerRadius
            color:        "transparent"
            border.width: 2
            antialiasing:  false
            border.color: Colours.mid(root.colors.m3surfaceContainer, root.colors.m3surfaceContainerHigh)

            Row {
                id: midPillRow
                anchors {
                    left:           parent.left
                    leftMargin:     4
                    verticalCenter: parent.verticalCenter
                }
                spacing: 4

                BgAppsWidget { colors: root.colors }
                PillDivider { pillHeight: midPill.height; colors: root.colors }
                CpuWidget { colors: root.colors }
                PillDivider { pillHeight: midPill.height; colors: root.colors }
                RamWidget { colors: root.colors }
                PillDivider { pillHeight: midPill.height; colors: root.colors }
                RecorderWidget { colors: root.colors }
            }
        }

        Rectangle {
            id:     rightPill
            height: root.height - 4
            width:  pillRow.implicitWidth + 8
            radius: Style.cornerRadius
            color:        "transparent"
            border.width: 2
            antialiasing:  false
            border.color: Colours.mid(root.colors.m3surfaceContainer, root.colors.m3surfaceContainerHigh)

            Row {
                id: pillRow
                anchors.centerIn: parent
                spacing: 4

                VolumeWidget       { id: volWidget; standalone: false; colors: root.colors }
                PillDivider { id: volBatDivider; pillHeight: rightPill.height; colors: root.colors }
                BatteryWidget      { id: batWidget; standalone: false; colors: root.colors }
                PillDivider { pillHeight: rightPill.height; colors: root.colors }
                BluetoothWidget    { standalone: false; colors: root.colors }
                PillDivider { pillHeight: rightPill.height; colors: root.colors }
                WifiWidget         { standalone: false; colors: root.colors }
                PillDivider { pillHeight: rightPill.height; colors: root.colors }
                NotificationButton { standalone: false; colors: root.colors }
                PillDivider { pillHeight: rightPill.height; colors: root.colors }
                DashboardButton    { standalone: false; colors: root.colors }
            }
        }
    }

    Binding { target: Visibilities; property: "volumeBarCenterX"
              value: root.width - rightPill.width / 2 - pillRow.implicitWidth / 2 + volWidget.implicitWidth / 2 }
    Binding { target: Visibilities; property: "batteryBarCenterX"
              value: root.width - rightPill.width / 2 - pillRow.implicitWidth / 2 + volWidget.implicitWidth + pillRow.spacing * 2 + volBatDivider.width + batWidget.implicitWidth / 2 }
}
