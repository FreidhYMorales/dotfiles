pragma ComponentBehavior: Bound

import QtQuick
import "../../services"

// No toggle-switch existed anywhere in the project — the launcher's own
// "light/dark" control is a text label that swaps wording on click, not a
// real switch. New component, borrowing the knob-slide feel of
// modules/bar/BatteryProfileOsd.qml's segmented-pill indicator (same
// duration/easing: 280ms OutCubic).
Item {
    id: root

    property bool  checked:   false
    property color onColor:   Colours.m3primary
    property color offColor:  Colours.m3surfaceContainerHigh
    property color knobColor: Colours.m3onPrimary
    property bool  enabled:   true

    signal toggled(bool checked)

    implicitWidth:  44
    implicitHeight: 24

    opacity: root.enabled ? 1.0 : 0.38
    Behavior on opacity { NumberAnimation { duration: 120 } }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color:  root.checked ? root.onColor : root.offColor
        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.InOutCubic } }
    }

    // Hover wash — HoverHandler.hovered only (never .containsMouse, that
    // exact bug was already fixed project-wide across 15 files).
    Rectangle {
        anchors.fill: parent
        radius:  height / 2
        color:   "white"
        opacity: hov.hovered && root.enabled ? 0.06 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Rectangle {
        id: knob
        width:  parent.height - 4
        height: parent.height - 4
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 2 : 2
        color: root.knobColor
        Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
    }

    HoverHandler {
        id: hov
        enabled: root.enabled
    }

    MouseArea {
        anchors.fill: parent
        enabled:      root.enabled
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.toggled(!root.checked)
    }
}
