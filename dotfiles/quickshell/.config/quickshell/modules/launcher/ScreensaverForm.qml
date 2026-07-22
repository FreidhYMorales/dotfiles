pragma ComponentBehavior: Bound

import QtQuick
import "../../services"
import "../../components"
import "../../components/controls"

Item {
    id: root

    readonly property bool showWallpaperPicker: !IdleManager.screensaverUseWallpaper

    readonly property int baseFormH:   200
    readonly property int pickerFormH: baseFormH + 164
    readonly property int formH: root.showWallpaperPicker ? root.pickerFormH : root.baseFormH

    property bool _wallpaperRealMove: false

    function _rearmWallpaperGuard() {
        root._wallpaperRealMove = false
        wallpaperMoveTracker.armed = false
    }

    Connections {
        target: Visibilities
        function onLauncherChanged() {
            if (Visibilities.launcher) root._rearmWallpaperGuard()
        }
    }

    onShowWallpaperPickerChanged: if (root.showWallpaperPicker) root._rearmWallpaperGuard()

    // Inline stepper: [−] value [+]
    component Stepper: Item {
        property int value: 0
        property int min:   0
        property int max:   120
        property int step:  1
        signal moved(int v)

        height: 32

        Row {
            anchors.centerIn: parent
            spacing: 6

            Rectangle {
                width: 28; height: 28; radius: height / 2
                color: decHov.hovered
                       ? Qt.alpha(Colours.m3primary, 0.15)
                       : Qt.alpha(Colours.m3onSurface, 0.08)
                Behavior on color { CAnim {} }

                Text {
                    anchors.centerIn: parent
                    text:           "−"
                    color:          value <= min
                                    ? Qt.alpha(Colours.m3onSurface, 0.25)
                                    : Colours.m3onSurface
                    font.family:    Style.fontFamily
                    font.pixelSize: 16
                    Behavior on color { CAnim {} }
                }
                HoverHandler { id: decHov }
                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    enabled:      value > min
                    onClicked:    moved(Math.max(min, value - step))
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width:               48
                horizontalAlignment: Text.AlignHCenter
                text:                value <= 0 ? "Off" : value + " min"
                color:               Colours.m3onSurface
                font.family:         Style.fontFamily
                font.pixelSize:      12
                Behavior on color { CAnim {} }
            }

            Rectangle {
                width: 28; height: 28; radius: height / 2
                color: incHov.hovered
                       ? Qt.alpha(Colours.m3primary, 0.15)
                       : Qt.alpha(Colours.m3onSurface, 0.08)
                Behavior on color { CAnim {} }

                Text {
                    anchors.centerIn: parent
                    text:           "+"
                    color:          value >= max
                                    ? Qt.alpha(Colours.m3onSurface, 0.25)
                                    : Colours.m3onSurface
                    font.family:    Style.fontFamily
                    font.pixelSize: 16
                    Behavior on color { CAnim {} }
                }
                HoverHandler { id: incHov }
                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    enabled:      value < max
                    onClicked:    moved(Math.min(max, value + step))
                }
            }
        }
    }

    Column {
        anchors {
            left:        parent.left
            right:       parent.right
            top:         parent.top
            topMargin:   16
            leftMargin:  16
            rightMargin: 16
        }
        spacing: 12

        // ── 3 timeout cards ─────────────────────────────────────────────

        Row {
            id: cardsRow
            width:   parent.width
            height:  88
            spacing: 8

            // Screensaver card
            Rectangle {
                width:  Math.floor((cardsRow.width - 16) / 3)
                height: parent.height
                radius: 12
                color:  Colours.m3surfaceContainerHigh
                Behavior on color { CAnim {} }

                Column {
                    anchors { fill: parent; topMargin: 12; bottomMargin: 10; leftMargin: 4; rightMargin: 4 }
                    spacing: 8

                    Text {
                        width:               parent.width
                        text:                "Screensaver"
                        color:               Colours.m3onSurfaceVariant
                        font.family:         Style.fontFamily
                        font.pixelSize:      11
                        horizontalAlignment: Text.AlignHCenter
                        Behavior on color { CAnim {} }
                    }

                    Stepper {
                        width:   parent.width
                        min:     0; max: 60; step: 1
                        value:   IdleManager.screensaverTimeoutMin
                        onMoved: v => IdleManager.screensaverTimeoutMin = v
                    }
                }
            }

            // Lock card
            Rectangle {
                width:  Math.floor((cardsRow.width - 16) / 3)
                height: parent.height
                radius: 12
                color:  Colours.m3surfaceContainerHigh
                Behavior on color { CAnim {} }

                Column {
                    anchors { fill: parent; topMargin: 12; bottomMargin: 10; leftMargin: 4; rightMargin: 4 }
                    spacing: 8

                    Text {
                        width:               parent.width
                        text:                "Lock"
                        color:               Colours.m3onSurfaceVariant
                        font.family:         Style.fontFamily
                        font.pixelSize:      11
                        horizontalAlignment: Text.AlignHCenter
                        Behavior on color { CAnim {} }
                    }

                    Stepper {
                        width:   parent.width
                        min:     0; max: 60; step: 1
                        value:   IdleManager.lockTimeoutMin
                        onMoved: v => IdleManager.lockTimeoutMin = v
                    }
                }
            }

            // Suspend card
            Rectangle {
                width:  Math.floor((cardsRow.width - 16) / 3)
                height: parent.height
                radius: 12
                color:  Colours.m3surfaceContainerHigh
                Behavior on color { CAnim {} }

                Column {
                    anchors { fill: parent; topMargin: 12; bottomMargin: 10; leftMargin: 4; rightMargin: 4 }
                    spacing: 8

                    Text {
                        width:               parent.width
                        text:                "Suspend"
                        color:               Colours.m3onSurfaceVariant
                        font.family:         Style.fontFamily
                        font.pixelSize:      11
                        horizontalAlignment: Text.AlignHCenter
                        Behavior on color { CAnim {} }
                    }

                    Stepper {
                        width:   parent.width
                        min:     0; max: 120; step: 5
                        value:   IdleManager.suspendTimeoutMin
                        onMoved: v => IdleManager.suspendTimeoutMin = v
                    }
                }
            }
        }

        // ── Use desktop wallpaper toggle ─────────────────────────────────

        Item {
            width:  parent.width
            height: 28

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text:           "Same as desktop wallpaper"
                color:          Colours.m3onSurface
                font.family:    Style.fontFamily
                font.pixelSize: 13
                Behavior on color { CAnim {} }
            }

            Toggle {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                checked:   IdleManager.screensaverUseWallpaper
                onToggled: c => IdleManager.screensaverUseWallpaper = c
            }
        }

        // ── Mini wallpaper picker (only when NOT using the desktop one) ───

        Item {
            width:   parent.width
            height:  140
            visible: root.showWallpaperPicker

            PathView {
                id: screensaverWallCarousel
                anchors.fill: parent
                model:   root.showWallpaperPicker ? Wallpapers.entries : []

                pathItemCount: 5
                preferredHighlightBegin: 0.5
                preferredHighlightEnd:   0.5
                highlightRangeMode: PathView.StrictlyEnforceRange
                snapMode: PathView.SnapToItem

                path: Path {
                    startX: 0
                    startY: screensaverWallCarousel.height / 2
                    PathAttribute { name: "itemScale";   value: 0.72 }
                    PathAttribute { name: "itemOpacity"; value: 0.45 }
                    PathLine { x: screensaverWallCarousel.width / 2; y: screensaverWallCarousel.height / 2 }
                    PathAttribute { name: "itemScale";   value: 1.0 }
                    PathAttribute { name: "itemOpacity"; value: 1.0 }
                    PathLine { x: screensaverWallCarousel.width; y: screensaverWallCarousel.height / 2 }
                    PathAttribute { name: "itemScale";   value: 0.72 }
                    PathAttribute { name: "itemOpacity"; value: 0.45 }
                }

                delegate: WallpaperCard {
                    required property var modelData
                    required property int index
                    width:    100
                    height:   110
                    scale:    PathView.itemScale
                    z:        PathView.isCurrentItem ? 1 : 0
                    opacity:  modelData ? PathView.itemOpacity : 0
                    wallName: modelData?.name ?? ""
                    wallPath: modelData?.path ?? ""
                    isVideo:  modelData?.isVideo ?? false
                    isActive: modelData?.path === IdleManager.screensaverPath
                    onHovered: if (root._wallpaperRealMove) screensaverWallCarousel.currentIndex = index
                    onClicked: {
                        if (!modelData) return
                        screensaverWallCarousel.currentIndex = index
                        IdleManager.screensaverPath = modelData.path
                    }
                }
            }

            MouseArea {
                id: wallpaperMoveTracker
                anchors.fill:    screensaverWallCarousel
                hoverEnabled:    true
                acceptedButtons: Qt.NoButton

                property bool armed: false
                property real baseX: 0
                property real baseY: 0
                readonly property real moveThreshold: 4

                onPositionChanged: {
                    if (!armed) {
                        armed = true
                        baseX = mouseX
                        baseY = mouseY
                        return
                    }
                    if (!root._wallpaperRealMove &&
                        (Math.abs(mouseX - baseX) > moveThreshold || Math.abs(mouseY - baseY) > moveThreshold))
                        root._wallpaperRealMove = true
                }
            }
        }

        // ── Preview button ────────────────────────────────────────────────

        Item {
            width:  previewLabel.implicitWidth + 32
            height: 32
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color:  Qt.alpha(Colours.m3onSurface, 0.08)
            }

            Text {
                id: previewLabel
                anchors.centerIn: parent
                text:           "󰈈  Preview"
                color:          Colours.m3onSurfaceVariant
                font.family:    Style.fontFamily
                font.pixelSize: 12
                Behavior on color { CAnim {} }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    Visibilities.screensaverPreview = !Visibilities.screensaverPreview
            }
        }
    }
}
