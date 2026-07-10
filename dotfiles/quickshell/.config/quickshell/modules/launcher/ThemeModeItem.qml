import QtQuick
import QtQuick.Effects
import "../../services"
import "../../components"

// Modeled on AppItem.qml — one matugen scheme type per row. previewPrimary/
// Secondary/Tertiary come from Colours.previewCache (Colours.generatePreviews()
// pre-renders all 9 modes against the current wallpaper when the picker
// opens) — falls back to the generic icon glyph while a mode's preview
// hasn't finished generating yet.
Item {
    id: root

    property string modeName: ""
    property bool   isActive:    false
    property bool   showDivider: true
    property bool   isSelected:  false
    property var    previewColors: undefined // {primary, secondary, tertiary} or undefined
    property bool   isLight:     false // border/divider color — deliberately not one of matugen's own colors, so it stays visible against any generated palette

    signal clicked()
    signal hovered()

    implicitHeight: 64

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: root.isSelected
               ? Qt.alpha(Colours.m3primaryContainer, 0.45)
               : hov.hovered
                 ? Qt.alpha(Colours.m3onSurface, 0.07)
                 : "transparent"
        Behavior on color { CAnim {} }
    }

    Rectangle {
        anchors {
            left:           parent.left
            leftMargin:     4
            verticalCenter: parent.verticalCenter
        }
        width:   3
        height:  28
        radius:  2
        visible: root.isSelected
        color:   Colours.m3primary
        Behavior on color { CAnim {} }
    }

    Item {
        id: iconArea
        width: 36; height: 36
        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }

        Rectangle {
            anchors.fill: parent
            radius:       height / 2
            color:        root.isSelected
                          ? Colours.m3primary
                          : Colours.m3primaryContainer
            Behavior on color { CAnim {} }
        }

        Text {
            anchors.centerIn: parent
            visible:        !root.previewColors
            text:           "󰏘"
            color:          root.isSelected ? Colours.m3onPrimary : Colours.m3onPrimaryContainer
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 16
            Behavior on color { CAnim {} }
        }

        // Real swatch once its preview finishes generating (see
        // Colours.generatePreviews()) — primary/secondary split left/right,
        // clipped to a perfect circle via a mask (same technique as
        // LockAvatar.qml) instead of per-corner radius math, which let the
        // color fills poke past the circular border at the seams. Outer
        // border + center divider use a fixed black (light theme) / white
        // (dark theme) — never one of matugen's own generated colors, so the
        // split stays legible no matter how close primary/secondary land for
        // a given palette.
        Item {
            id: swatchContent
            anchors.fill: parent
            visible: false
            layer.enabled: true
            layer.smooth: true

            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: parent.width / 2
                color: root.previewColors ? root.previewColors.primary : "transparent"
            }
            Rectangle {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                width: parent.width / 2
                color: root.previewColors ? root.previewColors.secondary : "transparent"
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width:  1.5
                height: parent.height
                color:  root.isLight ? "black" : "white"
            }
        }

        Item {
            id: swatchMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            layer.smooth: true
            Rectangle { anchors.fill: parent; radius: height / 2 }
        }

        MultiEffect {
            anchors.fill: parent
            visible:      !!root.previewColors
            source:       swatchContent
            maskEnabled:  true
            maskSource:   swatchMask
            maskSpreadAtMin:  1.0
            maskThresholdMax: 1.0
            maskThresholdMin: 0.5
        }

        Rectangle {
            anchors.fill: parent
            visible: !!root.previewColors
            radius:  height / 2
            color:   "transparent"
            border.width: 1.5
            border.color: root.isLight ? "black" : "white"
        }
    }

    Text {
        anchors {
            left:           iconArea.right
            right:          activeMark.left
            verticalCenter: parent.verticalCenter
            leftMargin:     12
            rightMargin:    8
        }
        text:           root.modeName
        color:          root.isSelected ? Colours.m3primary : Colours.m3onSurface
        font.family:    "Iosevka Term Nerd Font"
        font.pixelSize: 15
        font.weight:    Font.Medium
        elide:          Text.ElideRight
        Behavior on color { CAnim {} }
    }

    Text {
        id: activeMark
        anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 14 }
        text:    "󰄬"
        visible: root.isActive
        color:   Colours.m3primary
        font.family:    "Iosevka Term Nerd Font"
        font.pixelSize: 14
        Behavior on color { CAnim {} }
    }

    Rectangle {
        anchors {
            bottom:      parent.bottom
            left:        parent.left
            right:       parent.right
            leftMargin:  14
            rightMargin: 14
        }
        height:  1
        visible: root.showDivider
        color:   Qt.alpha(Colours.m3outlineVariant, 0.35)
        Behavior on color { CAnim {} }
    }

    HoverHandler {
        id: hov
        onHoveredChanged: if (hovered) root.hovered()
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.clicked()
    }
}
