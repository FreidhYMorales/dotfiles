pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import "../../services"
import "../../components"

Variants {
    model: Quickshell.screens

    delegate: Scope {
        id: screenScope
        required property ShellScreen modelData

        PanelWindow {
            id: win
            screen: screenScope.modelData
            color:  "transparent"

            readonly property bool isFocused:
                screenScope.modelData.name === (Hyprland.focusedMonitor?.name ?? "")
            // Per-monitor palette (bar/panels only — see Colours.paletteFor).
            readonly property var colors: Colours.paletteFor(screenScope.modelData.name)

            property bool showVolume:     false
            property bool showBrightness: false
            property bool osdReady:       false
            property real volCardX:       0
            property bool _volVisible:    false
            property bool _brightVisible: false

            Timer { interval: 600; running: true; onTriggered: win.osdReady = true }

            Timer {
                id: volumeTimer
                interval: 1000
                onTriggered: {
                    win.showVolume      = false
                    Visibilities.volume = false
                    volHideTimer.restart()
                }
            }
            Timer { id: volHideTimer;    interval: 400; onTriggered: win._volVisible    = false }

            Timer {
                id: brightnessTimer
                interval: 2000
                onTriggered: {
                    win.showBrightness = false
                    brightHideTimer.restart()
                }
            }
            Timer { id: brightHideTimer; interval: 400; onTriggered: win._brightVisible = false }

            Connections {
                target: Visibilities
                function onVolumeChanged() {
                    if (Visibilities.volume) {
                        if (!win.isFocused) return
                        win.volCardX = Math.max(8, Math.min(
                            Visibilities.volumeBarCenterX - 90,
                            screenScope.modelData.width - 180 - 8
                        ))
                        volumeTimer.stop()
                        volHideTimer.stop()
                        win._volVisible = true
                        win.showVolume  = true
                    } else {
                        volumeTimer.stop()
                        win.showVolume = false
                        volHideTimer.restart()
                    }
                }
            }

            Connections {
                target: Brightness
                function onCurrentChanged() {
                    if (!win.osdReady || !win.isFocused) return
                    brightHideTimer.stop()
                    win._brightVisible = true
                    win.showBrightness = true
                    brightnessTimer.restart()
                }
            }

            visible: isFocused && (win._volVisible || win._brightVisible)

            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.namespace:     "deadlock-osd"
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors { top: true; left: true; right: true }
            margins.top:    43
            implicitHeight: 64

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: {
                    win.showVolume     = false
                    win.showBrightness = false
                    Visibilities.volume = false
                    volumeTimer.stop()
                    brightnessTimer.stop()
                }
            }

            // — Volume OSD ears —
            Shape {
                z: 1; x: volCard.x - 12
                y: win.isFocused && win.showVolume ? 0 : -12
                width: 12; height: 12
                Behavior on y {
                    NumberAnimation {
                        duration: 350; easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                    }
                }
                ShapePath {
                    fillColor: volCard.color; strokeColor: "transparent"; strokeWidth: 0
                    startX: 0; startY: 0
                    PathArc { x: 12; y: 12; radiusX: 12; radiusY: 12; direction: PathArc.Clockwise }
                    PathLine { x: 12; y: 0 }
                }
            }
            Shape {
                z: 1; x: volCard.x + volCard.width
                y: win.isFocused && win.showVolume ? 0 : -12
                width: 12; height: 12
                Behavior on y {
                    NumberAnimation {
                        duration: 350; easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                    }
                }
                ShapePath {
                    fillColor: volCard.color; strokeColor: "transparent"; strokeWidth: 0
                    startX: 12; startY: 0
                    PathArc { x: 0; y: 12; radiusX: 12; radiusY: 12; direction: PathArc.Counterclockwise }
                    PathLine { x: 0; y: 0 }
                }
            }

            Rectangle {
                id:     volCard
                z:      1
                x:      win.volCardX
                y:      win.isFocused && win.showVolume ? 0 : -35
                width:  180
                height: 35
                Behavior on y {
                    NumberAnimation {
                        duration: 350; easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                    }
                }
                radius:         12
                topLeftRadius:  0
                topRightRadius: 0
                color:         win.colors.m3surfaceContainer
                clip:          true
                layer.enabled: true

                HoverHandler {
                    id: volHover
                    onHoveredChanged: hovered ? volumeTimer.stop() : volumeTimer.restart()
                }

                // Slider: icon is the thumb
                Item {
                    id: volSlider
                    anchors {
                        left: parent.left; right: parent.right
                        top: parent.top
                        leftMargin: 12; rightMargin: 12; topMargin: 2
                    }
                    height: 28

                    readonly property real thumbDia: 28
                    readonly property real travel:   width - thumbDia
                    // Always tracks actual volume — muted state only changes color, not position
                    readonly property real thumbX:   (Audio.volume / 100) * travel

                    // Track background
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color:  win.colors.m3surfaceContainerHighest
                        Behavior on color { CAnim {} }
                    }

                    // Fill
                    Rectangle {
                        width:  volSlider.thumbX + volSlider.thumbDia
                        height: parent.height
                        radius: height / 2
                        color:  Audio.muted ? Qt.alpha(win.colors.m3primary, 0.35) : win.colors.m3primary
                        Behavior on width { NumberAnimation { duration: 80 } }
                        Behavior on color { CAnim {} }
                    }

                    // Thumb with icon
                    Rectangle {
                        x:      volSlider.thumbX
                        anchors.verticalCenter: parent.verticalCenter
                        width:  volSlider.thumbDia
                        height: volSlider.thumbDia
                        radius: height / 2
                        color:  Audio.muted ? win.colors.m3onSurfaceVariant : win.colors.m3onPrimary
                        Behavior on x     { NumberAnimation { duration: 80 } }
                        Behavior on color { CAnim {} }

                        Text {
                            anchors.centerIn: parent
                            text:           Audio.muted       ? "󰖁" :
                                            Audio.volume > 66 ? "󰕾" :
                                            Audio.volume > 33 ? "󰖀" : "󰕿"
                            color:          Audio.muted ? win.colors.m3surfaceContainer : win.colors.m3primary
                            font.family:    Style.fontFamily
                            font.pixelSize: 13
                            Behavior on color { CAnim {} }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        property bool tapOnThumb: false
                        property real pressX:     0

                        function setVol(mx) {
                            const pct = Math.max(0, Math.min(100,
                                Math.round(mx / volSlider.travel * 100)
                            ))
                            Audio.setVolume(pct)
                        }
                        function isOnThumb(mx) {
                            return mx >= volSlider.thumbX &&
                                   mx <= volSlider.thumbX + volSlider.thumbDia
                        }

                        onPressed: {
                            volumeTimer.stop()
                            pressX     = mouseX
                            tapOnThumb = isOnThumb(mouseX)
                            if (!tapOnThumb) setVol(mouseX)
                        }
                        onPositionChanged: {
                            if (!pressed) return
                            if (tapOnThumb && Math.abs(mouseX - pressX) > 4)
                                tapOnThumb = false
                            if (!tapOnThumb) setVol(mouseX)
                        }
                        onClicked:  { if (tapOnThumb) Audio.toggleMute() }
                        onReleased: if (!volHover.hovered) volumeTimer.restart()
                        cursorShape: Qt.SizeHorCursor
                    }
                }
            }

            // — Brightness OSD ears —
            Shape {
                z: 1; x: brightCard.x - 12
                width: 12; height: 12
                y: win.isFocused && win.showBrightness ? 0 : -12
                Behavior on y {
                    NumberAnimation {
                        duration: 350; easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                    }
                }
                ShapePath {
                    fillColor: brightCard.color; strokeColor: "transparent"; strokeWidth: 0
                    startX: 0; startY: 0
                    PathArc { x: 12; y: 12; radiusX: 12; radiusY: 12; direction: PathArc.Clockwise }
                    PathLine { x: 12; y: 0 }
                }
            }
            Shape {
                z: 1; x: brightCard.x + brightCard.width
                y: win.isFocused && win.showBrightness ? 0 : -12
                width: 12; height: 12
                Behavior on y {
                    NumberAnimation {
                        duration: 350; easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                    }
                }
                ShapePath {
                    fillColor: brightCard.color; strokeColor: "transparent"; strokeWidth: 0
                    startX: 12; startY: 0
                    PathArc { x: 0; y: 12; radiusX: 12; radiusY: 12; direction: PathArc.Counterclockwise }
                    PathLine { x: 0; y: 0 }
                }
            }

            Rectangle {
                id:     brightCard
                z:      1
                anchors.horizontalCenter: parent.horizontalCenter
                y:      win.isFocused && win.showBrightness ? 0 : -35
                width:  160
                height: 35
                Behavior on y {
                    NumberAnimation {
                        duration: 350; easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                    }
                }
                radius:         12
                topLeftRadius:  0
                topRightRadius: 0
                color:         win.colors.m3surfaceContainer
                clip:          true
                layer.enabled: true

                HoverHandler {
                    onHoveredChanged: hovered ? brightnessTimer.stop() : brightnessTimer.restart()
                }

                // Slider: icon is the thumb
                Item {
                    id: brightSlider
                    anchors {
                        left: parent.left; right: parent.right
                        top: parent.top
                        leftMargin: 12; rightMargin: 12; topMargin: 2
                    }
                    height: 28

                    readonly property real thumbDia: 28
                    readonly property real travel:   width - thumbDia
                    readonly property real thumbX:   (Brightness.percent / 100) * travel

                    // Track background
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color:  win.colors.m3surfaceContainerHighest
                    }

                    // Fill
                    Rectangle {
                        width:  brightSlider.thumbX + brightSlider.thumbDia
                        height: parent.height
                        radius: height / 2
                        color:  win.colors.m3primary
                        Behavior on width { NumberAnimation { duration: 80 } }
                        Behavior on color { CAnim {} }
                    }

                    // Thumb with icon
                    Rectangle {
                        x:      brightSlider.thumbX
                        anchors.verticalCenter: parent.verticalCenter
                        width:  brightSlider.thumbDia
                        height: brightSlider.thumbDia
                        radius: height / 2
                        color:  win.colors.m3onPrimary
                        Behavior on x     { NumberAnimation { duration: 80 } }
                        Behavior on color { CAnim {} }

                        Text {
                            anchors.centerIn: parent
                            text:           Brightness.percent > 66 ? "󰃠" :
                                            Brightness.percent > 33 ? "󰃟" : "󰃞"
                            color:          win.colors.m3primary
                            font.family:    Style.fontFamily
                            font.pixelSize: 13
                            Behavior on color { CAnim {} }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        function setBright(mx) {
                            const pct = Math.max(1, Math.min(100,
                                Math.round(mx / brightSlider.travel * 100)
                            ))
                            Brightness.set(pct)
                        }
                        onPressed:         { brightnessTimer.stop(); setBright(mouseX) }
                        onPositionChanged: if (pressed) setBright(mouseX)
                        onReleased:        brightnessTimer.restart()
                        cursorShape:       Qt.SizeHorCursor
                    }
                }
            }
        }
    }
}
