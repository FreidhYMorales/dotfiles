import QtQuick
import "../../services"
import "../../components"
import "../../components/controls"

// Screen recorder settings — mode (screen/region/window) and audio are
// chosen here and persisted (services/Recorder.qml); actually starting or
// stopping a recording stays on RecorderWidget.qml's left click in the bar,
// this section never starts one itself. The mode pill is disabled while
// recording — changing it mid-recording wouldn't affect the process already
// running, so it'd be misleading to allow it (same guard as
// Recorder.setMode() itself).
Item {
    id: root

    implicitHeight: mainCol.implicitHeight + 16
    implicitWidth:  parent?.width ?? 300

    readonly property var modes:  ["screen", "region", "window"]
    readonly property var titles: ["Screen", "Region", "Window"]
    readonly property var labels: ["", "󱣵", "󱣴"]
    readonly property int selectedIndex: {
        const i = modes.indexOf(Recorder.mode)
        return i >= 0 ? i : 0
    }

    function _fmtElapsed() {
        const m = Math.floor(Recorder.elapsedSeconds / 60)
        const s = Recorder.elapsedSeconds % 60
        return String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0")
    }

    Column {
        id: mainCol
        anchors {
            left:           parent.left
            right:          parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: 10

        // ── Header: icon + title (left), status (right) ──
        Item {
            width:  parent.width - 24
            height: headerRow.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter

            Row {
                id:      headerRow
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           "󰻃"
                    color:          Recorder.recording ? Colours.m3error : Colours.m3onSurfaceVariant
                    font.family:    Style.fontFamily
                    font.pixelSize: 14
                    Behavior on color { CAnim {} }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           "Recorder"
                    color:          Colours.m3onSurfaceVariant
                    font.family:    Style.fontFamily
                    font.pixelSize: 11
                }
            }

            Text {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text:           Recorder.recording ? "Recording " + root._fmtElapsed() : "Idle"
                color:          Recorder.recording ? Colours.m3error : Colours.m3onSurfaceVariant
                font.family:    Style.fontFamily
                font.pixelSize: 11
                Behavior on color { CAnim {} }
            }
        }

        // ── Mode pill (screen/region/window) — sets the preference only ──
        Column {
            id:      modeCol
            width:   parent.width - 24
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            opacity: Recorder.recording ? 0.5 : 1.0
            Behavior on opacity { NumberAnimation { duration: 120 } }

            readonly property real segW: width / 3

            // Titles row — one label centered above each segment, so the
            // icons alone (which look similar at a glance) aren't the only
            // way to tell screen/region/window apart.
            Row {
                width: modeCol.width

                Repeater {
                    model: root.titles

                    delegate: Text {
                        required property string modelData
                        width:               modeCol.segW
                        horizontalAlignment: Text.AlignHCenter
                        text:           modelData
                        color:          Colours.m3onSurfaceVariant
                        font.family:    Style.fontFamily
                        font.pixelSize: 10
                    }
                }
            }

            Rectangle {
                id:     pill
                width:  modeCol.width
                height: 32
                radius: Style.cornerRadius
                color:  Colours.m3surfaceContainerHigh
                Behavior on color { CAnim {} }

                Rectangle {
                    width:  modeCol.segW - 4
                    height: pill.height - 4
                    radius: Style.cornerRadius
                    color:  Colours.m3primary
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.selectedIndex * modeCol.segW + 2
                    Behavior on x     { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                    Behavior on color { CAnim {} }
                }

                Row {
                    anchors.fill: parent

                    Repeater {
                        model: root.labels

                        delegate: Item {
                            required property string modelData
                            required property int    index
                            width:  modeCol.segW
                            height: pill.height

                            Text {
                                anchors.centerIn: parent
                                text:           parent.modelData
                                font.family:    Style.fontFamily
                                font.pixelSize: 14
                                color: root.selectedIndex === parent.index
                                           ? Colours.m3onPrimary
                                           : Colours.m3onSurface
                                Behavior on color { CAnim {} }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled:      !Recorder.recording
                                cursorShape:  Qt.PointingHandCursor
                                onClicked:    Recorder.setMode(root.modes[parent.index])
                            }
                        }
                    }
                }
            }
        }

        // ── Audio toggles — system output and mic combine into one mixed
        // track (gpu-screen-recorder's `default_output|default_input`) ──
        Item {
            width:  parent.width - 24
            height: systemAudioToggle.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text:           "System audio"
                color:          Colours.m3onSurface
                font.family:    Style.fontFamily
                font.pixelSize: 12
            }

            Toggle {
                id: systemAudioToggle
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                checked:  Recorder.systemAudioEnabled
                enabled:  !Recorder.recording
                onToggled: checked => Recorder.systemAudioEnabled = checked
            }
        }

        Item {
            width:  parent.width - 24
            height: micAudioToggle.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text:           "Microphone"
                color:          Colours.m3onSurface
                font.family:    Style.fontFamily
                font.pixelSize: 12
            }

            Toggle {
                id: micAudioToggle
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                checked:  Recorder.micAudioEnabled
                enabled:  !Recorder.recording
                onToggled: checked => Recorder.micAudioEnabled = checked
            }
        }
    }
}
