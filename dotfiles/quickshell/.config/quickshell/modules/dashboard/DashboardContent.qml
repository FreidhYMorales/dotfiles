pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Shapes
import QtQuick.Controls
import "../../services"
import "../../components"
import "../notifications"

Item {
    id: root

    property bool open:      false
    property bool panelOpen: false
    property int  _stage:    0

    readonly property real _profileH: profileSec.implicitHeight

    property var    _activeNotif: null
    property bool   _notifActive: false
    property string _lastNotifId: ""

    HoverHandler {
        onHoveredChanged: hovered ? dashCloseTimer.stop() : dashCloseTimer.restart()
    }

    Connections {
        target: Visibilities
        function onDashboardChanged() {
            if (Visibilities.dashboard) {
                dashCloseTimer.stop()
                closeTimer.stop()
                cs1.stop(); cs2.stop(); cs3.stop(); cs4.stop()
                root.open      = true
                root.panelOpen = false
                root._stage    = 0
                const list = Notifs.list
                if (list.length > 0) {
                    const n = list[0]
                    if (n && !n.closed && n.popup && n.notificationId !== root._lastNotifId) {
                        root._lastNotifId = n.notificationId
                        root._activeNotif = n
                        root._notifActive = true
                        notifDismissTimer.interval = n.expireTimeout > 0 ? n.expireTimeout : 5000
                        notifDismissTimer.restart()
                    }
                }
                openTimer.restart()
            } else {
                dashCloseTimer.stop()
                openTimer.stop()
                s1.stop(); s2.stop(); s3.stop()
                notifDismissTimer.stop()
                root._notifActive = false
                root._activeNotif = null
                cs1.restart(); cs2.restart(); cs3.restart(); cs4.restart()
                closeTimer.restart()
            }
        }
    }

    Timer { id: openTimer;  interval: 16;  onTriggered: { root.panelOpen = true; s1.restart(); s2.restart(); s3.restart() } }
    Timer { id: closeTimer; interval: 540; onTriggered: root.open = false }
    Timer { id: dashCloseTimer; interval: 1000; onTriggered: Visibilities.dashboard = false }

    Timer { id: s1;  interval: 140; onTriggered: root._stage = 1 }
    Timer { id: s2;  interval: 250; onTriggered: root._stage = 2 }
    Timer { id: s3;  interval: 360; onTriggered: root._stage = 3 }

    Timer { id: cs1; interval: 10;  onTriggered: { if (root._stage > 2) root._stage = 2 } }
    Timer { id: cs2; interval: 120; onTriggered: { if (root._stage > 1) root._stage = 1 } }
    Timer { id: cs3; interval: 230; onTriggered: { if (root._stage > 0) root._stage = 0 } }
    Timer { id: cs4; interval: 340; onTriggered: root.panelOpen = false }

    Timer { id: notifDismissTimer; onTriggered: { root._notifActive = false; root._activeNotif = null } }

    Connections {
        target: Notifs
        function onListChanged() {
            if (!Visibilities.dashboard) return
            const list = Notifs.list
            if (list.length === 0) return
            const n = list[0]
            if (!n || n.closed || !n.popup) return
            if (n.notificationId === root._lastNotifId) return
            root._lastNotifId = n.notificationId
            root._activeNotif = n
            root._notifActive = true
            notifDismissTimer.interval = n.expireTimeout > 0 ? n.expireTimeout : 5000
            notifDismissTimer.restart()
        }
    }

    // Left concave ear — only for the profile panel
    Shape {
        z:      2
        x:      0
        y:      root.panelOpen ? 0 : -14
        width:  14
        height: 14
        Behavior on y {
            NumberAnimation {
                duration: 150; easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
            }
        }
        ShapePath {
            fillColor:   panel.color
            strokeColor: "transparent"
            strokeWidth: 0
            startX: 0; startY: 0
            PathArc  { x: 14; y: 14; radiusX: 14; radiusY: 14; direction: PathArc.Clockwise }
            PathLine { x: 14; y: 0 }
        }
    }

    // ── Profile panel — connected to bar, drops from top ──
    Rectangle {
        id:            panel
        anchors.right: parent.right
        width:         root.width - 14
        height:        root._profileH
        y:             root.panelOpen ? 0 : -root._profileH
        Behavior on y {
            NumberAnimation {
                duration: 150; easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
            }
        }
        radius:         14
        topLeftRadius:  0
        topRightRadius: 0
        color:          Colours.m3surfaceContainer
        clip:           true
        layer.enabled:  true
        Behavior on color { CAnim {} }

        MouseArea { anchors.fill: parent }

        ProfileSection {
            id:    profileSec
            width: parent.width
        }

        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1
            color:  Qt.alpha(Colours.m3outlineVariant, 0.25)
            Behavior on color { CAnim {} }
        }
    }

    // ── Independent capsules — same y-slide animation as profile panel ──
    ScrollView {
        anchors {
            top:        parent.top
            topMargin:  root._profileH + 8
            bottom:     parent.bottom
            left:       parent.left
            right:      parent.right
            leftMargin: 14
        }
        clip:         true
        contentWidth: availableWidth
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff

        Column {
            width:         parent.width
            spacing:       8
            bottomPadding: 10

            // Capsule 0: Active notification
            Item {
                id: notifWrapper
                width: parent.width
                height: root._notifActive ? 82 : 0
                clip: true
                Behavior on height {
                    NumberAnimation {
                        duration: 150; easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                    }
                }

                Rectangle {
                    id:     capNotif
                    width:  parent.width
                    height: 82
                    radius: 12
                    color:  Colours.layer(Colours.m3surfaceContainer, 2)
                    Behavior on color { CAnim {} }

                    Column {
                        id: notifContent
                        anchors {
                            top:    parent.top;   topMargin:  12
                            left:   parent.left;  leftMargin: 14
                            right:  parent.right; rightMargin: 14
                        }
                        spacing: 4

                        Item {
                            width: parent.width
                            height: 20

                            Item {
                                id: notifIcon
                                width: 20; height: 20
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: Colours.m3primaryContainer
                                    Behavior on color { CAnim {} }
                                }

                                Image {
                                    id: notifIconImg
                                    anchors { fill: parent; margins: 2 }
                                    source:   root._activeNotif?.appIcon ? ("file://" + root._activeNotif.appIcon) : ""
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true; mipmap: true
                                    visible: status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible:        !notifIconImg.visible
                                    text:           (root._activeNotif?.appName ?? "?").charAt(0).toUpperCase()
                                    color:          Colours.m3onPrimaryContainer
                                    font.family:    "Iosevka Term Nerd Font"
                                    font.pixelSize: 10
                                    font.weight:    Font.Medium
                                    Behavior on color { CAnim {} }
                                }
                            }

                            Text {
                                anchors {
                                    left:           notifIcon.right; leftMargin:  8
                                    right:          notifDismiss.left; rightMargin: 8
                                    verticalCenter: parent.verticalCenter
                                }
                                text:           root._activeNotif?.appName ?? ""
                                color:          Colours.m3onSurfaceVariant
                                font.family:    "Iosevka Term Nerd Font"
                                font.pixelSize: 11
                                elide:          Text.ElideRight
                                Behavior on color { CAnim {} }
                            }

                            Item {
                                id: notifDismiss
                                width: 20; height: 20
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }

                                Text {
                                    anchors.centerIn: parent
                                    text:           "󰅖"
                                    color:          notifDismissHov.hovered ? Colours.m3onSurface : Colours.m3onSurfaceVariant
                                    font.family:    "Iosevka Term Nerd Font"
                                    font.pixelSize: 13
                                    Behavior on color { CAnim {} }
                                }
                                HoverHandler { id: notifDismissHov }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape:  Qt.PointingHandCursor
                                    onClicked: {
                                        notifDismissTimer.stop()
                                        root._notifActive = false
                                        root._activeNotif = null
                                    }
                                }
                            }
                        }

                        Text {
                            width:    parent.width
                            text:     root._activeNotif?.summary ?? ""
                            visible:  text.length > 0
                            color:    Colours.m3onSurface
                            font.family:    "Iosevka Term Nerd Font"
                            font.pixelSize: 13
                            font.weight:    Font.Medium
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide:    Text.ElideRight
                            Behavior on color { CAnim {} }
                        }

                        Text {
                            width:    parent.width
                            text:     root._activeNotif?.body ?? ""
                            visible:  text.length > 0
                            color:    Colours.m3onSurfaceVariant
                            font.family:    "Iosevka Term Nerd Font"
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide:    Text.ElideRight
                            Behavior on color { CAnim {} }
                        }
                    }
                }
            }

            // Capsule 1: Weather
            Item {
                width:  parent.width
                height: cap1.height
                clip:   true

                Rectangle {
                    id:     cap1
                    width:  parent.width
                    height: 116
                    radius: 12
                    color:  Colours.layer(Colours.m3surfaceContainer, 2)
                    y:      root._stage >= 1 ? 0 : -root.height
                    Behavior on y {
                        NumberAnimation {
                            duration: 100; easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                        }
                    }
                    Behavior on color { CAnim {} }

                    WeatherTab { anchors.fill: parent }
                }
            }

            // Capsule 2: Battery + Performance
            Item {
                width:  parent.width
                height: cap2.height
                clip:   true

                Rectangle {
                    id:     cap2
                    width:  parent.width
                    height: cap2Col.implicitHeight
                    radius: 12
                    color:  Colours.layer(Colours.m3surfaceContainer, 2)
                    y:      root._stage >= 2 ? 0 : -root.height
                    Behavior on y {
                        NumberAnimation {
                            duration: 100; easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                        }
                    }
                    Behavior on color { CAnim {} }

                    Column {
                        id:    cap2Col
                        width: parent.width

                        BatterySection {}

                        Rectangle {
                            width:  parent.width
                            height: 1
                            color:  Qt.alpha(Colours.m3outlineVariant, 0.25)
                            Behavior on color { CAnim {} }
                        }

                        PerformanceSection {}
                    }
                }
            }

            // Capsule 3: Music (only when a player is active)
            Item {
                visible: Mpris.hasPlayer
                width:   parent.width
                height:  cap3.height
                clip:    true

                Rectangle {
                    id:     cap3
                    width:  parent.width
                    height: mediaSec.implicitHeight
                    radius: 12
                    color:  Colours.layer(Colours.m3surfaceContainer, 2)
                    y:      root._stage >= 3 ? 0 : -root.height
                    Behavior on y {
                        NumberAnimation {
                            duration: 100; easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                        }
                    }
                    Behavior on color { CAnim {} }

                    MediaSection {
                        id:    mediaSec
                        width: parent.width
                    }
                }
            }
        }
    }
}
