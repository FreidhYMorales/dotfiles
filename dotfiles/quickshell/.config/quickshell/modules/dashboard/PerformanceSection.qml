import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    implicitHeight: metricsRow.implicitHeight + 16
    implicitWidth:  parent?.width ?? 300

    component CircleMetric: Item {
        id: circ

        property int    value:    0
        property string icon:     ""
        property string label:    ""
        property color  arcColor: Colours.m3primary

        implicitHeight: 78

        readonly property int circleSize: 50
        readonly property int strokeW:    5

        onValueChanged:    canvas.requestPaint()
        onArcColorChanged: canvas.requestPaint()

        // Individual container
        Rectangle {
            anchors.fill: parent
            radius:       10
            color:        Colours.m3surfaceContainerHighest
            Behavior on color { CAnim {} }
        }

        // Progress ring
        Canvas {
            id: canvas
            width:  circ.circleSize
            height: circ.circleSize
            anchors {
                top:              parent.top
                topMargin:        5
                horizontalCenter: parent.horizontalCenter
            }

            Component.onCompleted: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                const cx = width  / 2
                const cy = height / 2
                const r  = cx - circ.strokeW / 2 - 1
                const c  = circ.arcColor

                // Background track
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, Math.PI * 2)
                ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, 0.2)
                ctx.lineWidth   = circ.strokeW
                ctx.stroke()

                // Progress arc (clockwise from top)
                if (circ.value > 0) {
                    const start = -Math.PI / 2
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, start, start + (circ.value / 100) * Math.PI * 2)
                    ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, 1.0)
                    ctx.lineWidth   = circ.strokeW
                    ctx.lineCap     = "round"
                    ctx.stroke()
                }
            }
        }

        // Icon centered in the ring
        Text {
            anchors.centerIn: canvas
            text:           circ.icon
            font.family:    Style.fontFamily
            font.pixelSize: 16
            color:          circ.arcColor
            Behavior on color { CAnim {} }
        }

        // Label + value below the ring
        Text {
            anchors {
                top:              canvas.bottom
                topMargin:        5
                horizontalCenter: parent.horizontalCenter
            }
            text:           circ.label + " " + circ.value + "%"
            font.family:    Style.fontFamily
            font.pixelSize: 10
            color:          Colours.m3onSurfaceVariant
            Behavior on color { CAnim {} }
        }
    }

    Row {
        id: metricsRow
        anchors {
            left:           parent.left
            right:          parent.right
            leftMargin:     8
            rightMargin:    8
            verticalCenter: parent.verticalCenter
        }
        spacing: 8

        readonly property int count: SysInfo.hasGpu ? 4 : 3
        readonly property int itemW: Math.floor((width - (count - 1) * spacing) / count)

        CircleMetric {
            width:    metricsRow.itemW
            value:    SysInfo.cpu
            icon:     "󰻠"
            label:    "CPU"
            arcColor: Colours.m3primary
        }

        CircleMetric {
            width:    metricsRow.itemW
            value:    SysInfo.ram
            icon:     "󰑭"
            label:    "RAM"
            arcColor: Colours.m3secondary
        }

        CircleMetric {
            visible:  SysInfo.hasGpu
            width:    metricsRow.itemW
            value:    SysInfo.gpu
            icon:     "󰾲"
            label:    "GPU"
            arcColor: Colours.m3tertiary
        }

        CircleMetric {
            width:    metricsRow.itemW
            value:    SysInfo.disk
            icon:     "󰋊"
            label:    "Disk"
            arcColor: Colours.m3tertiary
        }
    }
}
