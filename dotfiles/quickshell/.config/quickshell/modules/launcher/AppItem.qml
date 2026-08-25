import QtQuick
import QtQuick.Effects
import "../../services"
import "../../components"

Item {
    id: root

    property string appName:        ""
    property string appExec:        ""
    property string appIcon:        ""
    property bool   appIconMono:    false
    property string appDescription: ""
    property bool   showDivider:    true
    property bool   isSelected:     false

    signal clicked()
    signal hovered()

    implicitHeight: 64

    // Background
    Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius
        color: root.isSelected
               ? Qt.alpha(Colours.m3primaryContainer, 0.45)
               : hov.hovered
                 ? Qt.alpha(Colours.m3onSurface, 0.07)
                 : "transparent"
        Behavior on color { CAnim {} }
    }

    // Left selection accent
    Rectangle {
        anchors {
            left:           parent.left
            leftMargin:     4
            verticalCenter: parent.verticalCenter
        }
        width:   3
        height:  28
        radius: Style.cornerRadius
        visible: root.isSelected
        color:   Colours.m3primary
        Behavior on color { CAnim {} }
    }

    // Icon container (rounded square)
    Item {
        id: iconArea
        width: 36; height: 36
        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }

        Rectangle {
            anchors.fill: parent
            radius: Style.cornerRadius
            color:        root.isSelected
                          ? Colours.m3primary
                          : Colours.m3primaryContainer
            Behavior on color { CAnim {} }
        }

        Image {
            id: iconImg
            anchors { fill: parent; margins: 5 }
            source:   root.appIcon ? ("file://" + root.appIcon) : ""
            fillMode: Image.PreserveAspectFit
            smooth:   true
            mipmap:   true
            // Monochrome-theme icons are recolored live below instead —
            // this raw copy must never be drawn directly, same technique as
            // WallpaperCard.qml's masked source.
            visible:  status === Image.Ready && !root.appIconMono
        }

        // yamis-mono icons carry no color of their own (baked placeholder
        // hex, see bootstrap.sh) — recolor here so they track isSelected the
        // same way the fallback glyph below does, instead of a fixed hue.
        MultiEffect {
            anchors.fill: iconImg
            source:  iconImg
            visible: root.appIconMono && iconImg.status === Image.Ready
            colorization:      1.0
            colorizationColor: root.isSelected ? Colours.m3onPrimary : Colours.m3onPrimaryContainer
            Behavior on colorizationColor { CAnim {} }
        }

        Text {
            anchors.centerIn: parent
            // iconImg.status reflects load success regardless of its own
            // visible flag (it stays hidden-but-loaded for mono icons, whose
            // MultiEffect copy is what actually gets shown) — checking
            // status directly instead of !iconImg.visible keeps this from
            // showing on top of a successfully loaded mono icon.
            visible:        iconImg.status !== Image.Ready
            text:           root.appName.charAt(0).toUpperCase()
            color:          root.isSelected ? Colours.m3onPrimary : Colours.m3onPrimaryContainer
            font.family:    Style.fontFamily
            font.pixelSize: 15
            font.weight:    Font.Medium
            Behavior on color { CAnim {} }
        }
    }

    // Name + description
    Column {
        anchors {
            left:           iconArea.right
            right:          parent.right
            verticalCenter: parent.verticalCenter
            leftMargin:     12
            rightMargin:    14
        }
        spacing: 3

        Text {
            width:          parent.width
            text:           root.appName
            color:          root.isSelected ? Colours.m3primary : Colours.m3onSurface
            font.family:    Style.fontFamily
            font.pixelSize: 15
            font.weight:    Font.Medium
            elide:          Text.ElideRight
            Behavior on color { CAnim {} }
        }

        Text {
            width:          parent.width
            text:           root.appDescription
            visible:        root.appDescription.length > 0
            color:          Qt.alpha(Colours.m3onSurfaceVariant, 0.75)
            font.family:    Style.fontFamily
            font.pixelSize: 11
            elide:          Text.ElideRight
            Behavior on color { CAnim {} }
        }
    }

    // Divider
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
