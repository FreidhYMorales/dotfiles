import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    // Per-monitor palette (bar/panels only — see Colours.paletteFor).
    // Defaults to the shared global palette so this widget still works
    // wherever else it might be instantiated without a screen context.
    property var colors: Colours.palette

    implicitHeight: calCol.implicitHeight

    property var _now:   new Date()
    property int _year:  _now.getFullYear()
    property int _month: _now.getMonth()

    Connections {
        target: Time
        function onNowChanged() {
            const t = Time.now
            const n = root._now
            if (t.getFullYear() !== n.getFullYear() ||
                t.getMonth()    !== n.getMonth()    ||
                t.getDate()     !== n.getDate()) {
                root._now = t
            }
        }
    }

    function buildDays(year, month) {
        const days        = []
        const first       = new Date(year, month, 1).getDay()
        const offset      = (first + 6) % 7
        const daysInMonth = new Date(year, month + 1, 0).getDate()
        const daysInPrev  = new Date(year, month, 0).getDate()

        for (let i = offset - 1; i >= 0; i--)
            days.push({ day: daysInPrev - i, thisMonth: false })
        for (let d = 1; d <= daysInMonth; d++)
            days.push({ day: d, thisMonth: true })
        while (days.length % 7 !== 0)
            days.push({ day: days.length - daysInMonth - offset + 1, thisMonth: false })
        return days
    }

    function monthName(m) {
        return ["January","February","March","April","May","June",
                "July","August","September","October","November","December"][m]
    }

    Column {
        id:      calCol
        width:   parent.width
        spacing: 6

        // Header
        Item {
            width:  parent.width
            height: 36

            Item {
                id:     prevBtn
                width:  28; height: 28
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: 7
                    color:  prevHov.hovered
                                ? Qt.alpha(root.colors.m3onSurface, 0.08)
                                : "transparent"
                    Behavior on color { CAnim {} }
                }
                Text {
                    anchors.centerIn: parent
                    text:           "󰅁"
                    font.family:    "Iosevka Term Nerd Font"
                    font.pixelSize: 16
                    color:          root.colors.m3onSurface
                    Behavior on color { CAnim {} }
                }
                HoverHandler { id: prevHov }
                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        root._month--
                        if (root._month < 0) { root._month = 11; root._year-- }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text:           root.monthName(root._month) + " " + root._year
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 13
                font.weight:    Font.Medium
                color:          root.colors.m3onSurface
                Behavior on color { CAnim {} }
            }

            Item {
                id:     nextBtn
                width:  28; height: 28
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }

                Rectangle {
                    anchors.fill: parent
                    radius: 7
                    color:  nextHov.hovered
                                ? Qt.alpha(root.colors.m3onSurface, 0.08)
                                : "transparent"
                    Behavior on color { CAnim {} }
                }
                Text {
                    anchors.centerIn: parent
                    text:           "󰅂"
                    font.family:    "Iosevka Term Nerd Font"
                    font.pixelSize: 16
                    color:          root.colors.m3onSurface
                    Behavior on color { CAnim {} }
                }
                HoverHandler { id: nextHov }
                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        root._month++
                        if (root._month > 11) { root._month = 0; root._year++ }
                    }
                }
            }
        }

        // Weekday labels
        Row {
            width: parent.width
            Repeater {
                model: ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
                delegate: Text {
                    required property string modelData
                    width:               calCol.width / 7
                    text:                modelData
                    horizontalAlignment: Text.AlignHCenter
                    font.family:         "Iosevka Term Nerd Font"
                    font.pixelSize:      10
                    color:               root.colors.m3onSurfaceVariant
                    Behavior on color { CAnim {} }
                }
            }
        }

        // Day grid
        Grid {
            id:      dayGrid
            width:   parent.width
            columns: 7

            Repeater {
                model: root.buildDays(root._year, root._month)
                delegate: Item {
                    required property var modelData
                    width:  dayGrid.width / 7
                    height: 32

                    readonly property bool isToday:
                        modelData.thisMonth &&
                        modelData.day  === root._now.getDate() &&
                        root._month    === root._now.getMonth() &&
                        root._year     === root._now.getFullYear()

                    Rectangle {
                        anchors.centerIn: parent
                        width: 24; height: 24; radius: 12
                        visible: isToday
                        color:   root.colors.m3primary
                        Behavior on color { CAnim {} }
                    }
                    Text {
                        anchors.centerIn:    parent
                        text:                modelData.day
                        font.family:         "Iosevka Term Nerd Font"
                        font.pixelSize:      12
                        horizontalAlignment: Text.AlignHCenter
                        color: isToday
                                   ? root.colors.m3onPrimary
                                   : modelData.thisMonth
                                       ? root.colors.m3onSurface
                                       : Qt.alpha(root.colors.m3onSurface, 0.35)
                        Behavior on color { CAnim {} }
                    }
                }
            }
        }
    }
}
