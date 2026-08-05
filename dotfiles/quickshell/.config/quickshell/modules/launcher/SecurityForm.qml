pragma ComponentBehavior: Bound

import QtQuick
import "../../services"
import "../../components"
import "../../components/controls"

// ">security" — manage lockscreen unlock methods. Today: fingerprint on/off
// + per-finger enroll/delete (any of the 10 fprintd finger names, not just
// one), backed by services/Security.qml (fprintd-list/-enroll/-delete).
// Height is measured off `content.implicitHeight` (not a hand-picked
// constant like ScreensaverForm's) — the registered/available finger lists
// are variable-length, so there's no fixed number of rows to hardcode.
Item {
    id: root

    readonly property bool showProgress: Security.enrolling
    readonly property int formH: content.implicitHeight + 32

    Column {
        id: content
        anchors {
            left:        parent.left
            right:       parent.right
            top:         parent.top
            topMargin:   16
            leftMargin:  16
            rightMargin: 16
        }
        spacing: 12

        // ── Fingerprint unlock toggle ────────────────────────────────────

        Item {
            width:  parent.width
            height: 28

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text:           "Fingerprint unlock (lockscreen)"
                color:          Colours.m3onSurface
                font.family:    Style.fontFamily
                font.pixelSize: 13
                Behavior on color { CAnim {} }
            }

            Toggle {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                checked:   Security.fingerprintEnabled
                onToggled: c => Security.fingerprintEnabled = c
            }
        }

        // ── Registered fingers + available-finger picker ──────────────────

        Column {
            width:   parent.width
            spacing: 10
            visible: !root.showProgress

            Text {
                text:           "Registered fingers"
                color:          Colours.m3onSurfaceVariant
                font.family:    Style.fontFamily
                font.pixelSize: 11
            }

            Text {
                visible:        !Security.hasEnrolledFingerprint
                text:           "No fingerprints registered"
                color:          Colours.m3onSurface
                font.family:    Style.fontFamily
                font.pixelSize: 13
                Behavior on color { CAnim {} }
            }

            Column {
                width:   parent.width
                spacing: 4

                Repeater {
                    model: Security.enrolledFingerNames

                    delegate: Item {
                        id: fingerRow
                        required property string modelData
                        width:  content.width
                        height: 28

                        Row {
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            Text {
                                text:           "󰄬"
                                color:          Colours.m3primary
                                font.family:    Style.fontFamily
                                font.pixelSize: 13
                            }
                            Text {
                                text:           Security.fingerLabel(fingerRow.modelData)
                                color:          Colours.m3onSurface
                                font.family:    Style.fontFamily
                                font.pixelSize: 13
                                Behavior on color { CAnim {} }
                            }
                        }

                        Item {
                            id: delBtn
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            width:  24
                            height: 24

                            Rectangle {
                                anchors.fill: parent
                                radius: Style.cornerRadius
                                color: Qt.alpha(Colours.m3error, delBtnHov.hovered ? 0.22 : 0.12)
                                Behavior on color { CAnim {} }
                            }
                            Text {
                                anchors.centerIn: parent
                                text:           "×"
                                color:          Colours.m3error
                                font.family:    Style.fontFamily
                                font.pixelSize: 15
                            }
                            HoverHandler { id: delBtnHov }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape:  Qt.PointingHandCursor
                                onClicked:    Security.deleteFinger(fingerRow.modelData)
                            }
                        }
                    }
                }
            }

            Text {
                visible:        Security.availableFingers.length > 0
                text:           "Add a finger"
                color:          Colours.m3onSurfaceVariant
                font.family:    Style.fontFamily
                font.pixelSize: 11
            }

            Text {
                visible:        Security.availableFingers.length === 0
                text:           "All fingers registered"
                color:          Colours.m3onSurfaceVariant
                font.family:    Style.fontFamily
                font.pixelSize: 13
            }

            Flow {
                width:   parent.width
                height:  implicitHeight
                spacing: 6
                visible: Security.availableFingers.length > 0

                Repeater {
                    model: Security.availableFingers

                    delegate: Item {
                        id: chip
                        required property var modelData
                        width:  chipLabel.implicitWidth + 20
                        height: 26

                        Rectangle {
                            anchors.fill: parent
                            radius: Style.cornerRadius
                            color: Qt.alpha(Colours.m3primary, chipHov.hovered ? 0.22 : 0.12)
                            Behavior on color { CAnim {} }
                        }
                        Text {
                            id: chipLabel
                            anchors.centerIn: parent
                            text:           chip.modelData.label
                            color:          Colours.m3primary
                            font.family:    Style.fontFamily
                            font.pixelSize: 12
                        }
                        HoverHandler { id: chipHov }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    Security.startEnroll(chip.modelData.id)
                        }
                    }
                }
            }
        }

        // ── Live enrollment progress ──────────────────────────────────────

        Column {
            width:   parent.width
            spacing: 6
            visible: root.showProgress

            Text {
                width:               parent.width
                horizontalAlignment: Text.AlignHCenter
                text:                "Enrolling: " + Security.fingerLabel(Security.enrollingFinger)
                color:               Colours.m3onSurface
                font.family:         Style.fontFamily
                font.pixelSize:      13
                Behavior on color { CAnim {} }
            }
            Text {
                width:               parent.width
                horizontalAlignment: Text.AlignHCenter
                text:                Security.enrollMessage
                color:               Colours.m3onSurfaceVariant
                font.family:         Style.fontFamily
                font.pixelSize:      12
                Behavior on color { CAnim {} }
            }
            Text {
                width:               parent.width
                horizontalAlignment: Text.AlignHCenter
                text:                "Successful touches: " + Security.enrollStageCount
                color:               Colours.m3onSurfaceVariant
                font.family:         Style.fontFamily
                font.pixelSize:      11
                Behavior on color { CAnim {} }
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width:  cancelLabel.implicitWidth + 24
                height: 26

                Rectangle {
                    anchors.fill: parent
                    radius: Style.cornerRadius
                    color: Qt.alpha(Colours.m3onSurface, cancelBtnHov.hovered ? 0.14 : 0.08)
                    Behavior on color { CAnim {} }
                }
                Text {
                    id: cancelLabel
                    anchors.centerIn: parent
                    text:           "Cancel"
                    color:          Colours.m3onSurfaceVariant
                    font.family:    Style.fontFamily
                    font.pixelSize: 12
                    Behavior on color { CAnim {} }
                }
                HoverHandler { id: cancelBtnHov }
                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    Security.cancelEnroll()
                }
            }
        }
    }
}
