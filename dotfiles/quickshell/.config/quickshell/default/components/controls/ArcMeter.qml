pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import "../../services"

// Compact circular progress ring with a centered icon glyph — built for
// N-C's always-on CPU/RAM glance meters (replaces the two stacked
// SegmentedMeter bars used there before). `value` follows the same 0-100
// percent convention as SysInfo.cpu/SysInfo.ram (see
// modules/dashboard/PerformanceSection.qml's BlockMetric, the project's
// existing percent-meter convention) — not 0-1.
//
// QtQuick.Shapes' PathAngleArc (start angle + sweep angle) instead of manual
// point/tangent math — this project already uses QtQuick.Shapes successfully
// elsewhere (components/NotchEarShape.qml's ear cutouts), so the module and
// Shape.CurveRenderer combination is known-good here. A stroked arc needs no
// masking, so QtQuick.Effects.MultiEffect is intentionally not used (project
// has prior bad experience with mask-based approaches — see
// NotchEarShape.qml's own comment).
//
// Deliberately minimal: percent value + icon + two colors, nothing else. Not
// built as a general-purpose gauge API — a future Performance-panel use case
// (Phase 5+) can extend this if/when it actually needs more.
Item {
    id: root

    property real   value:         0     // 0-100
    property string icon:          ""
    property var    colors:        Colours.palette
    property color  ringColor:     root.colors.m3primary
    property real   ringWidth:     2.5
    property real   iconPixelSize: 10

    implicitWidth:  24
    implicitHeight: 24

    readonly property real _radius: Math.min(width, height) / 2 - ringWidth / 2
    readonly property real _sweep:  360 * Math.max(0, Math.min(100, root.value)) / 100

    Shape {
        id: shape
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Background track — full circle (359.99, not 360: a true 360deg
        // sweep starts/ends on the same point and can render as an empty
        // path). Dim, non-animated.
        ShapePath {
            strokeColor: Qt.alpha(root.colors.m3outlineVariant, 0.4)
            fillColor:   "transparent"
            strokeWidth: root.ringWidth
            capStyle:    ShapePath.RoundCap

            PathAngleArc {
                centerX:    root.width / 2
                centerY:    root.height / 2
                radiusX:    root._radius
                radiusY:    root._radius
                startAngle: -90
                sweepAngle: 359.99
            }
        }

        // Foreground arc — value-proportional sweep, accent-colored.
        ShapePath {
            id: fillPath
            strokeColor: root.ringColor
            fillColor:   "transparent"
            strokeWidth: root.ringWidth
            capStyle:    ShapePath.RoundCap

            Behavior on strokeColor { ColorAnimation { duration: 200; easing.type: Easing.InOutCubic } }

            PathAngleArc {
                centerX:    root.width / 2
                centerY:    root.height / 2
                radiusX:    root._radius
                radiusY:    root._radius
                startAngle: -90
                sweepAngle: root._sweep

                Behavior on sweepAngle { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text:           root.icon
        font.family:    Style.fontFamily
        font.pixelSize: root.iconPixelSize
        color:          root.ringColor
        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.InOutCubic } }
    }
}
