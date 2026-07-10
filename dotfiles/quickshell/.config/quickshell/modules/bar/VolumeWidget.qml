import QtQuick
import "../../services"
import "../../components"

Item {
    id: root
    implicitWidth:  Math.max(26, row.implicitWidth) + (standalone ? 16 : 0)
    implicitHeight: 26

    property bool standalone:   true
    property bool showPercent:  false

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: root.showPercent = false
    }

    Connections {
        target: Audio
        function onVolumeChanged() { root.showPercent = true; hideTimer.restart() }
        function onMutedChanged()  { root.showPercent = true; hideTimer.restart() }
    }

    function updateCenterX() {
        if (!standalone) return
        Visibilities.volumeBarCenterX = 8 + mapToItem(null, implicitWidth / 2, 0).x
    }
    Component.onCompleted:  Qt.callLater(updateCenterX)
    onXChanged:             Qt.callLater(updateCenterX)
    onImplicitWidthChanged: Qt.callLater(updateCenterX)

    Rectangle {
        anchors.fill: parent
        visible:      root.standalone
        radius:       height / 2
        color:        Colours.m3surfaceContainerHigh
        Behavior on color { CAnim {} }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:           Audio.muted       ? "󰖁" :
                            Audio.volume > 66 ? "󰕾" :
                            Audio.volume > 33 ? "󰖀" : "󰕿"
            color:          Audio.muted ? Colours.m3onSurfaceVariant : Colours.m3onSurface
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 13
            Behavior on color { CAnim {} }
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width:  root.showPercent ? percentText.implicitWidth + 10 : 0
            height: percentText.implicitHeight
            clip:   true
            Behavior on width {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            Text {
                id: percentText
                anchors { left: parent.left; leftMargin: 5; verticalCenter: parent.verticalCenter }
                text:           Audio.volume + "%"
                color:          Audio.muted ? Colours.m3onSurfaceVariant : Colours.m3onSurface
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 12
                Behavior on color { CAnim {} }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked:    Visibilities.toggle("volume")
    }
}
