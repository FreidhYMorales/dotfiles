pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../services"
import "../../components"

// ">polkit" mode (LauncherContent.qml) — takes over the app-list area
// whenever services/Polkit.qml has an active authentication request. Owns
// its own password field (bordered TextInput, same look as WebAppForm's
// name/URL fields) right above Cancel/Submit — the launcher's own search
// bar underneath just shows a static contextual placeholder while this mode
// is active, it's not the thing being typed into.
Item {
    id: root

    readonly property var flow: Polkit.flow
    readonly property int formH: content.implicitHeight + 32

    function focusInput() {
        passwordInput.forceActiveFocus()
    }

    function _submit() {
        Polkit.submit(passwordInput.text)
        passwordInput.text = ""
    }

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

        Item {
            width:  parent.width
            height: Math.max(icon.visible ? icon.height : 0, msgText.implicitHeight)

            Image {
                id: icon
                readonly property string resolved: root.flow && root.flow.iconName
                    ? Quickshell.iconPath(root.flow.iconName, "dialog-password")
                    : ""
                visible:  resolved !== ""
                source:   resolved
                width:    32
                height:   32
                anchors { left: parent.left; top: parent.top }
                fillMode: Image.PreserveAspectFit
            }

            Text {
                id: msgText
                anchors {
                    left:        icon.visible ? icon.right : parent.left
                    leftMargin:  icon.visible ? 12 : 0
                    right:       parent.right
                    top:         parent.top
                }
                wrapMode:       Text.WordWrap
                text:           root.flow ? root.flow.message : ""
                color:          Colours.m3onSurface
                font.family:    Style.fontFamily
                font.pixelSize: 14
                Behavior on color { CAnim {} }
            }
        }

        Text {
            width:          parent.width
            visible:        root.flow && root.flow.supplementaryMessage !== ""
            wrapMode:       Text.WordWrap
            text:           root.flow ? root.flow.supplementaryMessage : ""
            color:          root.flow && root.flow.supplementaryIsError ? Colours.m3error : Colours.m3onSurfaceVariant
            font.family:    Style.fontFamily
            font.pixelSize: 12
            Behavior on color { CAnim {} }
        }

        // ── Password field ─────────────────────────────────────────────────

        Item {
            width:   parent.width
            height:  52
            visible: root.flow && root.flow.isResponseRequired

            Text {
                anchors { left: parent.left; top: parent.top }
                text:           root.flow ? root.flow.inputPrompt : ""
                color:          Colours.m3onSurfaceVariant
                font.family:    Style.fontFamily
                font.pixelSize: 11
                Behavior on color { CAnim {} }
            }

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height:  34
                radius:  Style.cornerRadius
                color:   Colours.m3surfaceContainerHigh
                border.width: passwordInput.activeFocus ? 1.5 : 1
                border.color: passwordInput.activeFocus
                              ? Colours.m3primary
                              : Qt.alpha(Colours.m3outlineVariant, 0.6)
                Behavior on border.color { CAnim {} }
                Behavior on color        { CAnim {} }

                TextInput {
                    id: passwordInput
                    anchors {
                        left:           parent.left
                        right:          parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin:     10
                        rightMargin:    10
                    }
                    font.family:    Style.fontFamily
                    font.pixelSize: 13
                    color:          Colours.m3onSurface
                    selectByMouse:  true
                    clip:           true
                    echoMode:          root.flow && !root.flow.responseVisible ? TextInput.Password : TextInput.Normal
                    passwordCharacter: "*"
                    Behavior on color { CAnim {} }

                    // Guarded the same way submitBtn's own `visible` already
                    // is: the field can still hold focus and receive key
                    // events for a moment after isResponseRequired flips
                    // false (right after submitting, before the next stage
                    // arrives) — an extra Enter in that window would
                    // otherwise resubmit an empty string.
                    Keys.onReturnPressed: if (root.flow && root.flow.isResponseRequired) root._submit()
                    Keys.onEscapePressed: Polkit.cancel()
                }
            }
        }

        Row {
            anchors.right: parent.right
            spacing: 8

            Item {
                id: cancelBtn
                width:  cancelLabel.implicitWidth + 24
                height: 28

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
                    onClicked:    Polkit.cancel()
                }
            }

            Item {
                id: submitBtn
                visible: root.flow && root.flow.isResponseRequired
                width:  submitLabel.implicitWidth + 24
                height: 28

                Rectangle {
                    anchors.fill: parent
                    radius: Style.cornerRadius
                    color: Qt.alpha(Colours.m3primary, submitBtnHov.hovered ? 0.28 : 0.18)
                    Behavior on color { CAnim {} }
                }
                Text {
                    id: submitLabel
                    anchors.centerIn: parent
                    text:           "Submit"
                    color:          Colours.m3primary
                    font.family:    Style.fontFamily
                    font.pixelSize: 12
                    Behavior on color { CAnim {} }
                }
                HoverHandler { id: submitBtnHov }
                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    root._submit()
                }
            }
        }
    }
}
