pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic

ListView {
    id: root
    clip:    true
    spacing: 4
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
}
