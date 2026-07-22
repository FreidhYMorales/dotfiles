pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "../../services"
import "../../components"
import "../../utils"

Item {
    id: root

    readonly property int formH: 220

    function focusName() {
        nameInput.forceActiveFocus()
    }

    function reset() {
        nameInput.text = ""
        urlInput.text  = ""
        statusText.text  = ""
        statusText.color = Colours.m3primary
    }

    function _setStatus(msg, isError) {
        statusText.text  = msg
        statusText.color = isError ? Colours.m3error : Colours.m3primary
    }

    function _submit() {
        const name = nameInput.text.trim()
        const url  = urlInput.text.trim()
        if (!name || !url) {
            _setStatus("Name and URL are required", true)
            return
        }
        _setStatus("Installing…", false)
        installProc.command = [Paths.home + "/.local/bin/webapp-install", name, url]
        installProc.running = true
    }

    Process {
        id: installProc
        onExited: exitCode => {
            if (exitCode === 0) {
                root._setStatus("Installed!", false)
                closeTimer.restart()
            } else {
                root._setStatus("Failed — check URL or name", true)
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 800
        onTriggered: Visibilities.toggle("launcher")
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

        Text {
            width:          parent.width
            text:           "Install Web App"
            color:          Colours.m3onSurface
            font.family:    Style.fontFamily
            font.pixelSize: 14
            font.weight:    Font.Medium
            Behavior on color { CAnim {} }
        }

        Item {
            width:  parent.width
            height: 52

            Text {
                anchors { left: parent.left; top: parent.top }
                text:           "Name"
                color:          Colours.m3onSurfaceVariant
                font.family:    Style.fontFamily
                font.pixelSize: 11
                Behavior on color { CAnim {} }
            }

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height:  34
                radius:  8
                color:   Colours.m3surfaceContainerHigh
                border.width: nameInput.activeFocus ? 1.5 : 1
                border.color: nameInput.activeFocus
                              ? Colours.m3primary
                              : Qt.alpha(Colours.m3outlineVariant, 0.6)
                Behavior on border.color { CAnim {} }
                Behavior on color        { CAnim {} }

                TextInput {
                    id: nameInput
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
                    Behavior on color { CAnim {} }

                    Keys.onTabPressed:    event => { urlInput.forceActiveFocus(); event.accepted = true }
                    Keys.onReturnPressed: root._submit()
                    Keys.onEscapePressed: Visibilities.toggle("launcher")
                }
            }
        }

        Item {
            width:  parent.width
            height: 52

            Text {
                anchors { left: parent.left; top: parent.top }
                text:           "URL"
                color:          Colours.m3onSurfaceVariant
                font.family:    Style.fontFamily
                font.pixelSize: 11
                Behavior on color { CAnim {} }
            }

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height:  34
                radius:  8
                color:   Colours.m3surfaceContainerHigh
                border.width: urlInput.activeFocus ? 1.5 : 1
                border.color: urlInput.activeFocus
                              ? Colours.m3primary
                              : Qt.alpha(Colours.m3outlineVariant, 0.6)
                Behavior on border.color { CAnim {} }
                Behavior on color        { CAnim {} }

                TextInput {
                    id: urlInput
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
                    Behavior on color { CAnim {} }

                    Keys.onTabPressed:    event => { nameInput.forceActiveFocus(); event.accepted = true }
                    Keys.onReturnPressed: root._submit()
                    Keys.onEscapePressed: Visibilities.toggle("launcher")
                }
            }
        }

        Item {
            width:  parent.width
            height: 36

            Item {
                id: installBtn
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width:  installLabel.implicitWidth + 28
                height: 32

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color:  installBtnHov.hovered
                            ? Qt.alpha(Colours.m3primary, 0.15)
                            : Qt.alpha(Colours.m3onSurface, 0.08)
                    Behavior on color { CAnim {} }
                }

                Text {
                    id: installLabel
                    anchors.centerIn: parent
                    text:           "󰄳  Install"
                    color:          Colours.m3primary
                    font.family:    Style.fontFamily
                    font.pixelSize: 12
                    Behavior on color { CAnim {} }
                }

                HoverHandler { id: installBtnHov }
                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    root._submit()
                }
            }

            Text {
                id: statusText
                anchors {
                    left:           installBtn.right
                    right:          parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin:     12
                }
                text:           ""
                color:          Colours.m3primary
                font.family:    Style.fontFamily
                font.pixelSize: 12
                elide:          Text.ElideRight
                Behavior on color { CAnim {} }
            }
        }
    }
}
