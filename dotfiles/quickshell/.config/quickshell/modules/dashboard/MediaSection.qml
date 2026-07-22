pragma ComponentBehavior: Bound

import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    property bool _expanded: false
    property real localPos:  0

    implicitHeight: col.implicitHeight + 16
    implicitWidth:  parent?.width ?? 300

    function _syncPos() { root.localPos = Mpris.position }

    Connections {
        target: Mpris
        function onPositionChanged() { root.localPos = Mpris.position }
        function onTitleChanged()    { root._syncPos() }
        function onPlayerChanged()   { root._syncPos() }
    }

    Timer {
        interval: 1000
        running:  Mpris.playing
        repeat:   true
        onTriggered: root.localPos = Math.min(root.localPos + 1, Mpris.length > 0 ? Mpris.length : root.localPos + 1)
    }

    function _fmtTime(secs) {
        if (isNaN(secs) || secs < 0) return "0:00"
        const s = Math.floor(secs)
        const m = Math.floor(s / 60)
        const r = s % 60
        return m + ":" + (r < 10 ? "0" + r : r)
    }

    Column {
        id:  col
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
        spacing:      8
        leftPadding:  8
        rightPadding: 8

        // ── Art + metadata ────────────────────────────────────────────
        Row {
            width: parent.width - parent.leftPadding - parent.rightPadding
            spacing: 12

            Item {
                width: 56; height: 56

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color:  Colours.m3surfaceContainerHigh
                    clip:   true
                    Behavior on color { CAnim {} }

                    Image {
                        anchors.fill: parent
                        source:       Mpris.artUrl
                        fillMode:     Image.PreserveAspectCrop
                        visible:      Mpris.artUrl !== ""
                        smooth:       true
                    }

                    Text {
                        anchors.centerIn: parent
                        visible:          Mpris.artUrl === ""
                        text:             "󰝚"
                        color:            Colours.m3onSurfaceVariant
                        font.family:      Style.fontFamily
                        font.pixelSize:   24
                        Behavior on color { CAnim {} }
                    }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width:   parent.width - 56 - 12
                spacing: 4

                Text {
                    width:       parent.width
                    text:        Mpris.title.length > 0 ? Mpris.title : "Unknown"
                    color:       Colours.m3onSurface
                    font.family: Style.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    elide:       Text.ElideRight
                    Behavior on color { CAnim {} }
                }

                Text {
                    width:       parent.width
                    text:        Mpris.artist.length > 0 ? Mpris.artist : "Unknown Artist"
                    color:       Colours.m3onSurfaceVariant
                    font.family: Style.fontFamily
                    font.pixelSize: 11
                    elide:       Text.ElideRight
                    Behavior on color { CAnim {} }
                }
            }
        }

        // ── Progress bar + time ───────────────────────────────────────
        Column {
            visible: Mpris.length > 0
            width:   parent.width - parent.leftPadding - parent.rightPadding
            spacing: 4

            Item {
                width: parent.width; height: 4

                // Track — visible destination color
                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color:  Qt.alpha(Colours.m3primary, 0.2)
                    Behavior on color { CAnim {} }
                }

                // Fill — progress
                Rectangle {
                    height: parent.height
                    radius: 2
                    color:  Colours.m3primary
                    Behavior on color { CAnim {} }
                    Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.Linear } }
                    width: Mpris.length > 0
                           ? Math.max(radius * 2, (root.localPos / Mpris.length) * parent.width)
                           : 0
                }
            }

            Row {
                width: parent.width

                Text {
                    id:             posLabel
                    text:           root._fmtTime(root.localPos)
                    color:          Colours.m3onSurfaceVariant
                    font.family:    Style.fontFamily
                    font.pixelSize: 10
                    Behavior on color { CAnim {} }
                }

                Item { width: parent.width - posLabel.width - durLabel.width; height: 1 }

                Text {
                    id:             durLabel
                    text:           root._fmtTime(Mpris.length)
                    color:          Colours.m3onSurfaceVariant
                    font.family:    Style.fontFamily
                    font.pixelSize: 10
                    Behavior on color { CAnim {} }
                }
            }
        }

        // ── Controls (left) + expanding selector (right) ──────────────
        Item {
            width:  parent.width - parent.leftPadding - parent.rightPadding
            height: 36

            // Controls
            Row {
                id:      ctrlRow
                spacing: 4
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }

                Item {
                    width: 32; height: 32
                    HoverHandler { id: prevHov }
                    Rectangle {
                        anchors.fill: parent; radius: 16
                        color: prevHov.hovered ? Qt.alpha(Colours.m3onSurface, 0.1) : "transparent"
                        Behavior on color { CAnim {} }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"; font.family: Style.fontFamily; font.pixelSize: 16
                        color: Mpris.canPrev ? Colours.m3onSurface : Colours.m3onSurfaceVariant
                        Behavior on color { CAnim {} }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: Mpris.canPrev; onClicked: Mpris.previous() }
                }

                Item {
                    width: 32; height: 32
                    HoverHandler { id: playHov }
                    Text {
                        anchors.centerIn: parent
                        text: Mpris.playing ? "󰏤" : "󰐊"
                        font.family: Style.fontFamily; font.pixelSize: 22
                        color: playHov.hovered ? Colours.m3onSurface : Colours.m3primary
                        Behavior on color { CAnim {} }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Mpris.togglePlay() }
                }

                Item {
                    width: 32; height: 32
                    HoverHandler { id: nextHov }
                    Rectangle {
                        anchors.fill: parent; radius: 16
                        color: nextHov.hovered ? Qt.alpha(Colours.m3onSurface, 0.1) : "transparent"
                        Behavior on color { CAnim {} }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"; font.family: Style.fontFamily; font.pixelSize: 16
                        color: Mpris.canNext ? Colours.m3onSurface : Colours.m3onSurfaceVariant
                        Behavior on color { CAnim {} }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: Mpris.canNext; onClicked: Mpris.next() }
                }
            }

            // ── Horizontal expanding selector ─────────────────────────
            Item {
                id: selectorItem
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                height: 28

                // Natural content width, capped to available space left of the controls
                readonly property real _naturalW: playerList.contentWidth
                readonly property real _maxW:     Math.max(0, parent.width - handleArea.width - ctrlRow.width - 8)
                readonly property real _listW:    Math.min(_naturalW, _maxW)

                width: handleArea.width + (root._expanded && Mpris.playerCount > 1 ? _listW : 0)
                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                // Pill background
                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color:  Colours.m3surfaceContainerLow
                    Behavior on color { CAnim {} }
                }

                // Scrollable player list
                Item {
                    id:  listClip
                    anchors { left: parent.left; right: handleDivider.left; top: parent.top; bottom: parent.bottom }
                    clip: true

                    ListView {
                        id:          playerList
                        anchors.fill: parent
                        orientation: ListView.Horizontal
                        interactive: selectorItem._naturalW > selectorItem._maxW
                        snapMode:    ListView.SnapToItem
                        boundsBehavior: Flickable.StopAtBounds
                        model:       Mpris.otherCount

                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: event => {
                                const delta = -event.angleDelta.y * 0.5
                                playerList.contentX = Math.max(0,
                                    Math.min(playerList.contentX + delta,
                                             playerList.contentWidth - playerList.width))
                            }
                        }

                        delegate: Item {
                            id:     chip
                            height: playerList.height

                            required property int index

                            readonly property var entry: Mpris.otherPlayers[index] ?? {}

                            TextMetrics {
                                id:             tm
                                text:           Mpris.playerDisplayName(chip.entry.mp ?? null)
                                font.family:    Style.fontFamily
                                font.pixelSize: 11
                            }

                            width: tm.advanceWidth + 24

                            Rectangle {
                                visible: index > 0
                                width: 1; height: 14
                                color: Qt.alpha(Colours.m3onSurface, 0.2)
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            }

                            Text {
                                anchors.centerIn: parent
                                text:        tm.text
                                font.family: Style.fontFamily
                                font.pixelSize: 11
                                color: Colours.m3onSurfaceVariant
                                Behavior on color { CAnim {} }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape:  Qt.PointingHandCursor
                                onClicked: { Mpris.selectPlayer(chip.entry.idx); root._expanded = false }
                            }
                        }
                    }

                    // ‹ indicator — covers left edge when scrolled
                    Rectangle {
                        visible: playerList.contentX > 0
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width:  22
                        radius: 14
                        color:  Colours.m3surfaceContainerLow
                        z:      1

                        Text {
                            anchors.centerIn: parent
                            text:        "‹"
                            font.pixelSize: 14
                            color: Colours.m3onSurfaceVariant
                        }
                    }
                }

                // Divider
                Rectangle {
                    id:     handleDivider
                    visible: root._expanded && Mpris.playerCount > 1
                    width:  1; height: 14
                    color:  Qt.alpha(Colours.m3onSurface, 0.2)
                    anchors { right: handleArea.left; verticalCenter: parent.verticalCenter }
                }

                // Handle — always visible
                Item {
                    id:     handleArea
                    height: 28
                    width:  handleRow.implicitWidth + 20
                    anchors { right: parent.right }

                    Row {
                        id:      handleRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text:        Mpris.playerName
                            font.family: Style.fontFamily
                            font.pixelSize: 11
                            color: Colours.m3onSurfaceVariant
                            Behavior on color { CAnim {} }
                        }

                        Text {
                            visible:     Mpris.playerCount > 1
                            text:        root._expanded ? "▸" : "◂"
                            font.pixelSize: 9
                            color: Colours.m3onSurfaceVariant
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled:      Mpris.playerCount > 1
                        cursorShape:  Mpris.playerCount > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            root._expanded = !root._expanded
                            if (!root._expanded) playerList.contentX = 0
                        }
                    }
                }
            }
        }
    }
}
