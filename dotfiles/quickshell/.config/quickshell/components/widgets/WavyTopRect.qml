pragma ComponentBehavior: Bound
import QtQuick

// Rectangle with a wavy top edge drawn with Canvas.
Item {
    id: root
    property color color:      "#ffffff"
    property real  waveHeight: 8
    property real  waveFreq:   2

    Canvas {
        anchors.fill: parent

        onWidthChanged:  requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = root.color
            ctx.beginPath()
            ctx.moveTo(0, root.waveHeight)
            const waves = root.waveFreq
            const step  = width / (waves * 2)
            for (let i = 0; i < waves * 2; i++) {
                const cp  = (i + 0.5) * step
                const ep  = (i + 1)   * step
                const top = (i % 2 === 0) ? 0 : root.waveHeight * 2
                ctx.quadraticCurveTo(cp, top, ep, root.waveHeight)
            }
            ctx.lineTo(width, height)
            ctx.lineTo(0, height)
            ctx.closePath()
            ctx.fill()
        }
    }
}
