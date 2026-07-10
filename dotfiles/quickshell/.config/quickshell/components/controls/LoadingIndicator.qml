pragma ComponentBehavior: Bound
import QtQuick

// Circular indeterminate loading indicator
Item {
    id: root
    property color color:       "#cdd6f4"
    property real  implicitSize: 24

    implicitWidth:  implicitSize
    implicitHeight: implicitSize

    Canvas {
        id: canvas
        anchors.fill: parent
        property real angle: 0

        NumberAnimation on angle {
            from: 0; to: 360
            duration: 1000
            loops: Animation.Infinite
            running: true
        }

        onAngleChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            const cx   = width  / 2
            const cy   = height / 2
            const r    = Math.min(width, height) / 2 - 3
            const start = (canvas.angle - 90) * Math.PI / 180
            ctx.beginPath()
            ctx.arc(cx, cy, r, start, start + Math.PI * 1.2)
            ctx.strokeStyle = root.color
            ctx.lineWidth   = 2.5
            ctx.lineCap     = "round"
            ctx.stroke()
        }
    }
}
