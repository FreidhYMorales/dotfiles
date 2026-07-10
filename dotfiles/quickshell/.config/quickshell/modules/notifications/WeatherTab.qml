import Quickshell
import Quickshell.Io
import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    property string _buf:      ""
    property bool   _loading:  true
    property bool   _error:    false

    // Parsed weather data
    property string _temp:        "--"
    property string _desc:        ""
    property string _location:    ""
    property string _humidity:    "--"
    property string _wind:        "--"
    property string _weatherIcon: "󰖙"

    function _weatherIcon_from_code(code) {
        const c = parseInt(code)
        if (c === 113)                                                      return "󰖙"
        if (c === 116 || c === 119)                                         return "󰖕"
        if (c === 122 || c === 143)                                         return "󰖑"
        if ((c >= 176 && c <= 182) || c === 185 ||
            (c >= 263 && c <= 266) || (c >= 281 && c <= 284) ||
            (c >= 293 && c <= 296))                                         return "󰖗"
        if ((c >= 200 && c <= 202) || (c >= 386 && c <= 392))              return "󰖓"
        if (c === 227 || c === 230 ||
            (c >= 323 && c <= 338) || (c >= 368 && c <= 371))              return "󰖘"
        return "󰖙"
    }

    function _parse(raw) {
        root._loading = false
        try {
            const data = JSON.parse(raw)
            const cur  = data.current_condition[0]
            const area = data.nearest_area[0]

            root._temp        = cur.temp_C + "°C"
            root._desc        = cur.weatherDesc[0].value
            root._location    = area.areaName[0].value
            root._humidity    = cur.humidity + "%"
            root._wind        = cur.windspeedKmph + " km/h"
            root._weatherIcon = root._weatherIcon_from_code(cur.weatherCode)
            root._error       = false
        } catch (e) {
            root._error = true
            console.warn("WeatherTab: parse error:", e)
        }
    }

    Process {
        id: curlProc
        command: ["curl", "-s", "--max-time", "5", "wttr.in/?format=j1"]

        stdout: SplitParser {
            onRead: data => root._buf += data
        }

        onRunningChanged: {
            if (!running) root._parse(root._buf)
        }
    }

    Timer {
        id:       refreshTimer
        interval: 1800000
        running:  true
        repeat:   true
        onTriggered: {
            root._buf     = ""
            root._loading = true
            curlProc.running = false
            curlProc.running = true
        }
    }

    Component.onCompleted: {
        curlProc.running = true
    }

    // Loading state
    Text {
        anchors.centerIn: parent
        visible:          root._loading
        text:             "Loading..."
        font.family:      "Iosevka Term Nerd Font"
        font.pixelSize:   13
        color:            Colours.m3onSurfaceVariant
        Behavior on color { CAnim {} }
    }

    // Error state
    Text {
        anchors.centerIn: parent
        visible:          !root._loading && root._error
        text:             "Weather unavailable"
        font.family:      "Iosevka Term Nerd Font"
        font.pixelSize:   13
        color:            Colours.m3onSurfaceVariant
        Behavior on color { CAnim {} }
    }

    // Data state — two column layout
    Item {
        anchors { fill: parent; topMargin: 8; bottomMargin: 8; leftMargin: 16; rightMargin: 16 }
        visible: !root._loading && !root._error

        // Left column: icon + temperature, vertically centered
        Column {
            id:      weatherLeft
            width:   parent.width * 0.42
            anchors {
                left:           parent.left
                verticalCenter: parent.verticalCenter
            }
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           root._weatherIcon
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 44
                color:          Colours.m3primary
                Behavior on color { CAnim {} }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           root._temp
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 28
                font.weight:    Font.Medium
                color:          Colours.m3onSurface
                Behavior on color { CAnim {} }
            }
        }

        // Right column: weather details, vertically centered
        Column {
            anchors {
                left:           weatherLeft.right
                leftMargin:     12
                right:          parent.right
                verticalCenter: parent.verticalCenter
            }
            spacing: 7

            Text {
                text:           root._desc
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 13
                color:          Colours.m3onSurface
                elide:          Text.ElideRight
                width:          parent.width
                Behavior on color { CAnim {} }
            }
            Text {
                text:           root._location
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 11
                color:          Colours.m3onSurfaceVariant
                elide:          Text.ElideRight
                width:          parent.width
                Behavior on color { CAnim {} }
            }
            Row {
                spacing: 4
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           "󰖋"
                    font.family:    "Iosevka Term Nerd Font"
                    font.pixelSize: 14
                    color:          Colours.m3onSurfaceVariant
                    Behavior on color { CAnim {} }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           root._humidity
                    font.family:    "Iosevka Term Nerd Font"
                    font.pixelSize: 12
                    color:          Colours.m3onSurfaceVariant
                    Behavior on color { CAnim {} }
                }
            }
            Row {
                spacing: 4
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           "󰖝"
                    font.family:    "Iosevka Term Nerd Font"
                    font.pixelSize: 14
                    color:          Colours.m3onSurfaceVariant
                    Behavior on color { CAnim {} }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           root._wind
                    font.family:    "Iosevka Term Nerd Font"
                    font.pixelSize: 12
                    color:          Colours.m3onSurfaceVariant
                    Behavior on color { CAnim {} }
                }
            }
        }
    }
}
