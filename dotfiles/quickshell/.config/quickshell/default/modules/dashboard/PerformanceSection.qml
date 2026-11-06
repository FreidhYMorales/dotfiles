import QtQuick
import "../../services"
import "../../components"
import "../../components/controls"

Item {
    id: root

    implicitHeight: metricsCol.implicitHeight + 16
    implicitWidth:  parent?.width ?? 300

    component BlockMetric: Item {
        id: metric

        property int    value:    0
        property string icon:     ""
        property string label:    ""
        property color  arcColor: Colours.m3primary
        property bool   isLast:   false

        implicitHeight: 40

        Item {
            id: leftGroup
            width:  60
            height: parent.height

            Text {
                id: iconText
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text:           metric.icon
                font.family:    Style.fontFamily
                font.pixelSize: 14
                color:          metric.arcColor
                Behavior on color { CAnim {} }
            }

            Text {
                anchors {
                    left:           iconText.right
                    leftMargin:     6
                    verticalCenter: parent.verticalCenter
                }
                text:           metric.label
                font.family:    Style.fontFamily
                font.pixelSize: 11
                color:          Colours.m3onSurfaceVariant
                Behavior on color { CAnim {} }
            }
        }

        Text {
            id: percentText
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width:               32
            horizontalAlignment: Text.AlignRight
            text:           metric.value + "%"
            font.family:    Style.fontFamily
            font.pixelSize: 11
            color:          Colours.m3onSurfaceVariant
            Behavior on color { CAnim {} }
        }

        SegmentedMeter {
            anchors {
                left:           leftGroup.right
                leftMargin:     10
                right:          percentText.left
                rightMargin:    10
                verticalCenter: parent.verticalCenter
            }
            height:    14
            value:     metric.value
            fillColor: metric.arcColor
        }

        // Row divider (hidden on last row)
        Rectangle {
            visible: !metric.isLast
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1
            color:  Qt.alpha(Colours.m3outlineVariant, 0.25)
            Behavior on color { CAnim {} }
        }
    }

    Column {
        id: metricsCol
        anchors {
            left:        parent.left
            right:       parent.right
            top:         parent.top
            leftMargin:  14
            rightMargin: 14
            topMargin:   8
        }
        spacing: 0

        BlockMetric {
            width:    parent.width
            value:    SysInfo.cpu
            icon:     "󰻠"
            label:    "CPU"
            arcColor: Colours.m3primary
        }

        BlockMetric {
            width:    parent.width
            value:    SysInfo.ram
            icon:     "󰑭"
            label:    "RAM"
            arcColor: Colours.m3secondary
        }

        BlockMetric {
            visible:  SysInfo.hasGpu
            width:    parent.width
            value:    SysInfo.gpu
            icon:     "󰾲"
            label:    "GPU"
            arcColor: Colours.m3tertiary
        }

        BlockMetric {
            visible:  SysInfo.hasIgpu
            width:    parent.width
            value:    SysInfo.igpu
            icon:     "󰾲"
            label:    "iGPU"
            arcColor: Colours.m3tertiary
        }

        BlockMetric {
            visible:  SysInfo.hasNpu
            width:    parent.width
            value:    SysInfo.npu
            icon:     ""
            label:    "NPU"
            arcColor: Colours.m3tertiary
        }

        BlockMetric {
            width:    parent.width
            value:    SysInfo.disk
            icon:     "󰋊"
            label:    "Disk"
            arcColor: Colours.m3tertiary
            isLast:   true
        }
    }
}
