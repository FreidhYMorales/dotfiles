import QtQuick
import "../../services"

// Discrete block/segment meter (terminal-alike), shared by the dashboard's
// Performance and Battery rows. The segment straddling the value boundary
// gets a partial-alpha fill instead of being strictly on/off, so precision
// isn't lost even with a small segment count (e.g. 48% with 10 segments =
// 4 full + a 5th at 80% alpha, not a hard cutoff at 40%).
Item {
    id: root

    property real  value:          0
    property color fillColor:      Colours.m3primary
    property int   segmentCount:   10
    property real  segmentSpacing: 3

    readonly property real segStep:      100 / segmentCount
    readonly property int  fullSegments: Math.min(segmentCount, Math.floor(value / segStep))
    readonly property real partialAlpha: Math.max(0, Math.min(1, (value - fullSegments * segStep) / segStep))

    readonly property real segW: (width - (segmentCount - 1) * segmentSpacing) / segmentCount

    Row {
        anchors.fill: parent
        spacing: root.segmentSpacing

        Repeater {
            model: root.segmentCount

            delegate: Rectangle {
                width:  root.segW
                height: root.height
                radius: Style.cornerRadius
                color:  index < root.fullSegments
                            ? root.fillColor
                            : index === root.fullSegments
                                ? Qt.alpha(root.fillColor, 0.18 + root.partialAlpha * 0.82)
                                : Qt.alpha(root.fillColor, 0.18)
                Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.InOutCubic } }
            }
        }
    }
}
