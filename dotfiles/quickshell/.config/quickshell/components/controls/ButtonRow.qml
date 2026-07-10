pragma ComponentBehavior: Bound
import QtQuick

// Horizontal row for icon buttons.
Row {
    id: root
    property color selectedColor: "transparent"
    property int   selectedIndex: 0
    spacing: 8
}
