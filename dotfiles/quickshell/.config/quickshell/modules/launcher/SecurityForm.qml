pragma ComponentBehavior: Bound

import QtQuick
import "../../services"
import "../../components"
import "../../components/controls"

// ">security" — manage lockscreen unlock methods. Today: fingerprint on/off
// + enroll/delete, backed by services/Security.qml (fprintd-list/-enroll/
// -delete). Deliberately not a card grid like ScreensaverForm's timeout
// trio — this is a short list of rows, same shape as its own toggle row.
Item {
    id: root

    readonly property bool showProgress: Security.enrolling

    readonly property int baseFormH: 108
    readonly property int progressFormH: baseFormH + 64
    readonly property int formH: root.showProgress ? root.progressFormH : root.baseFormH

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

        // ── Enrollment status + enroll/delete action ─────────────────────

        Item {
            width:  parent.width
            height: 40
            visible: !root.showProgress

            Column {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                spacing: 2

                Row {
                    spacing: 6
                    Text {
                        visible:        Security.hasEnrolledFingerprint
                        text:           "󰄬"
                        color:          Colours.m3primary
                        font.family:    Style.fontFamily
                        font.pixelSize: 13
                        Behavior on color { CAnim {} }
                    }
                    Text {
                        text:           Security.hasEnrolledFingerprint ? "Fingerprint registered" : "No fingerprint registered"
                        color:          Colours.m3onSurface
                        font.family:    Style.fontFamily
                        font.pixelSize: 13
                        Behavior on color { CAnim {} }
                    }
                }
                Text {
                    visible:        Security.hasEnrolledFingerprint
                    text:           Security.enrolledFingerNames.join(", ")
                    color:          Colours.m3onSurfaceVariant
                    font.family:    Style.fontFamily
                    font.pixelSize: 11
                    Behavior on color { CAnim {} }
                }
            }

            Item {
                id: actionBtn
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width:  actionLabel.implicitWidth + 24
                height: 28

                Rectangle {
                    anchors.fill: parent
                    radius: Style.cornerRadius
                    color: Qt.alpha(
                        Security.hasEnrolledFingerprint ? Colours.m3error : Colours.m3primary,
                        actionBtnHov.hovered ? 0.22 : 0.15
                    )
                    Behavior on color { CAnim {} }
                }

                Text {
                    id: actionLabel
                    anchors.centerIn: parent
                    text:           Security.hasEnrolledFingerprint ? "Delete" : "Enroll"
                    color:          Security.hasEnrolledFingerprint ? Colours.m3error : Colours.m3primary
                    font.family:    Style.fontFamily
                    font.pixelSize: 12
                    Behavior on color { CAnim {} }
                }

                HoverHandler { id: actionBtnHov }
                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    Security.hasEnrolledFingerprint ? Security.deleteFingerprint() : Security.startEnroll()
                }
            }
        }

        // ── Live enrollment progress ──────────────────────────────────────

        Item {
            width:   parent.width
            height:  64
            visible: root.showProgress

            Column {
                anchors.centerIn: parent
                width:   parent.width
                spacing: 6

                Text {
                    width:               parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text:                Security.enrollMessage
                    color:               Colours.m3onSurface
                    font.family:         Style.fontFamily
                    font.pixelSize:      13
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
}
