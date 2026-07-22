import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    implicitHeight: mainCol.implicitHeight + 16
    implicitWidth:  parent?.width ?? 300

    function batteryIcon(pct, charging) {
        if (charging) return "󰂄"
        if (pct >= 90) return "󰁹"
        if (pct >= 80) return "󰂂"
        if (pct >= 70) return "󰂁"
        if (pct >= 60) return "󰂀"
        if (pct >= 50) return "󰁿"
        if (pct >= 40) return "󰁾"
        if (pct >= 30) return "󰁽"
        if (pct >= 20) return "󰁼"
        if (pct >= 10) return "󰁻"
        return "󰁺"
    }

    Column {
        id: mainCol
        anchors {
            left:           parent.left
            right:          parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: 8

        // ── Top: rotated icon + info ──
        Item {
            width:  parent.width
            height: infoCol.implicitHeight

            // Battery icon rotated to horizontal
            Item {
                id:     iconWrapper
                width:  36
                height: parent.height
                anchors { left: parent.left; leftMargin: 12 }
                clip:   false

                Text {
                    anchors.centerIn: parent
                    rotation:       90
                    text:           root.batteryIcon(Battery.percentage, Battery.charging)
                    color:          Battery.charging
                                        ? Colours.m3primary
                                        : Battery.percentage < 20
                                            ? Colours.m3error
                                            : Colours.m3secondary
                    font.family:    Style.fontFamily
                    font.pixelSize: 28
                    Behavior on color { CAnim {} }
                }
            }

            // Info column
            Column {
                id: infoCol
                anchors {
                    left:        iconWrapper.right
                    leftMargin:  8
                    right:       parent.right
                    rightMargin: 12
                }
                spacing: 3

                // Battery % (left) | Health (right)
                Item {
                    width:  parent.width
                    height: Math.max(pctRow.implicitHeight, healthLabel.implicitHeight)

                    Row {
                        id:      pctRow
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           "Battery"
                            color:          Colours.m3onSurfaceVariant
                            font.family:    Style.fontFamily
                            font.pixelSize: 11
                            Behavior on color { CAnim {} }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           Battery.percentage + "%"
                            color:          Colours.m3onSurface
                            font.family:    Style.fontFamily
                            font.pixelSize: 18
                            font.weight:    Font.Medium
                            Behavior on color { CAnim {} }
                        }
                    }

                    Text {
                        id:      healthLabel
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text:           "Health " + Battery.health + "%"
                        color:          Colours.m3onSurfaceVariant
                        font.family:    Style.fontFamily
                        font.pixelSize: 11
                        Behavior on color { CAnim {} }
                    }
                }

                // Time to full — only while charging
                Text {
                    visible:        Battery.charging
                    text:           Battery.timeStr
                    color:          Colours.m3onSurfaceVariant
                    font.family:    Style.fontFamily
                    font.pixelSize: 11
                    Behavior on color { CAnim {} }
                }
            }
        }

        // ── Progress bar ──
        Item {
            width:  parent.width - 24
            height: 6
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.fill: parent
                radius:       3
                color:        Qt.alpha(Colours.m3surfaceContainerHighest, 0.6)
                Behavior on color { CAnim {} }
            }

            Rectangle {
                height: parent.height
                radius: 3
                color:  Battery.charging
                            ? Colours.m3primary
                            : Battery.percentage < 20
                                ? Colours.m3error
                                : Colours.m3secondary
                Behavior on color { CAnim {} }
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.InOutCubic } }

                width: Math.max(radius * 2, (Battery.percentage / 100) * parent.width)
            }
        }
    }
}
