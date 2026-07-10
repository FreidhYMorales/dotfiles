pragma ComponentBehavior: Bound

import QtQuick
import "../../services"
import "../../components"

// ">keybinds" launcher content — plain scrollable ListView, not part of the
// launcher's selectedIndex/keyboard navigation (mouse-only, same as
// ScreensaverForm.qml). Data comes from services/Keybinds.qml, which reads
// live off `hyprctl binds -j` rather than a hand-maintained copy.
Item {
    id: root

    readonly property int rowH:       40
    readonly property int visibleRows: 8
    // Fixed-constant sizing (same criterion as LauncherContent.qml's
    // carouselH/ScreensaverForm.formH) so the parent's listH stays a simple
    // lookup instead of depending on this item's own layout.
    readonly property int formH: Math.min(Math.max(Keybinds.entries.length, 1), root.visibleRows) * root.rowH

    ListView {
        anchors.fill: parent
        model:        Keybinds.entries
        clip:         true
        spacing:      0
        boundsBehavior: Flickable.StopAtBounds

        delegate: Item {
            id: row
            required property var modelData

            width:  ListView.view.width
            height: root.rowH

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1
                color:  Colours.mid(Colours.m3surfaceContainer, Colours.m3surfaceContainerHigh)
            }

            Rectangle {
                id:     keyPill
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                width:  keyText.implicitWidth + 16
                height: 24
                radius: height / 2
                color:  Colours.m3surfaceContainerHigh
                border.width: 1
                border.color: Colours.mid(Colours.m3surfaceContainer, Colours.m3surfaceContainerHigh)

                StyledText {
                    id: keyText
                    anchors.centerIn: parent
                    text: row.modelData.mods
                              ? row.modelData.mods + " + " + row.modelData.key
                              : row.modelData.key
                    font.pixelSize: 11
                }
            }

            StyledText {
                anchors {
                    left:            keyPill.right
                    leftMargin:      12
                    right:           parent.right
                    rightMargin:     16
                    verticalCenter:  parent.verticalCenter
                }
                text:    row.modelData.description
                color:   Colours.m3onSurfaceVariant
                elide:   Text.ElideRight
                font.pixelSize: 12
            }
        }
    }
}
