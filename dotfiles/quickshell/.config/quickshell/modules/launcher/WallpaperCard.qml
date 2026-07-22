import QtQuick
import QtQuick.Effects
import "../../services"
import "../../components"

// Card delegate for the ">wallpaper" PathView carousel (LauncherContent.qml) —
// vertical card (thumbnail + name overlay) instead of WallpaperItem's row
// layout, since the carousel scrolls horizontally through cards rather than
// a vertical list of rows.
Item {
    id: root

    property string wallName: ""
    property string wallPath: ""
    property bool   isVideo:  false
    property bool   isActive: false

    signal clicked()
    signal hovered()

    // For video wallpapers, a single extracted frame (ffmpegthumbnailer, via
    // Wallpapers.qml's per-path cache) stands in for a live preview — showing
    // literally nothing but a camera-glyph placeholder made the carousel look
    // broken/empty for every video entry.
    readonly property string frameSrc: root.isVideo
        ? (Wallpapers.videoFrameCache[root.wallPath] || "")
        : ""

    function _requestFrame() {
        if (root.isVideo && root.wallPath !== "") Wallpapers.requestVideoFrame(root.wallPath)
    }
    Component.onCompleted: root._requestFrame()
    onWallPathChanged:     root._requestFrame()

    Rectangle {
        anchors.fill: parent
        radius:  12
        color:   Colours.m3surfaceContainerHigh
        border.width: root.isActive ? 2 : 0
        border.color: Colours.m3primary
        Behavior on border.color { CAnim {} }

        // `clip: true` alone only clips children to the item's rectangular
        // bounding box — it ignores `radius`, so the image/scrim below would
        // still show square corners poking past the card's rounded ones.
        // Mask the whole composition instead (same technique as
        // LockAvatar.qml / ThemeModeItem.qml) for a real rounded-rect clip.
        // `visible: false` here — MultiEffect below still reads its layer
        // texture, but this raw (square-cornered) copy must never be drawn
        // directly, or its corners show through the mask's transparent ones.
        Item {
            id: cardContent
            anchors.fill: parent
            visible: false
            layer.enabled: true
            layer.smooth:  true

            Image {
                id: thumb
                anchors.fill: parent
                visible:      (!root.isVideo && root.wallPath !== "") || (root.isVideo && root.frameSrc !== "")
                source:       !root.isVideo && root.wallPath !== "" ? ("file://" + root.wallPath)
                              : root.isVideo && root.frameSrc !== "" ? ("file://" + root.frameSrc)
                              : ""
                fillMode:     Image.PreserveAspectCrop
                asynchronous: true
                smooth:       true
                mipmap:       true
            }

            // Only shown until the frame finishes extracting (or if
            // ffmpegthumbnailer isn't installed) — once frameSrc is ready,
            // the Image above takes over.
            Text {
                anchors.centerIn: parent
                visible:        root.isVideo && root.frameSrc === ""
                text:           "󰃽"
                color:          Colours.m3onSurfaceVariant
                font.family:    Style.fontFamily
                font.pixelSize: 28
            }

            // Name label, pinned to the bottom with a scrim for legibility
            // over whatever thumbnail is behind it.
            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: nameText.implicitHeight + 14
                color:  Qt.alpha("black", 0.45)

                Text {
                    id: nameText
                    anchors.centerIn: parent
                    width:  parent.width - 12
                    text:   root.wallName
                    color:  "white"
                    font.family:    Style.fontFamily
                    font.pixelSize: 12
                    font.weight:    Font.Medium
                    elide:  Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Item {
            id: cardMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            layer.smooth:  true
            Rectangle { anchors.fill: parent; radius: 12 }
        }

        MultiEffect {
            anchors.fill: parent
            source:      cardContent
            maskEnabled: true
            maskSource:  cardMask
            maskSpreadAtMin:  1.0
            maskThresholdMax: 1.0
            maskThresholdMin: 0.5
        }
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
