pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

// Icon mapping utilities — Caelestia-compatible API.
QtObject {
    id: root

    readonly property var weatherIcons: ({
        "0": "clear_day",  "1": "clear_day",  "2": "partly_cloudy_day", "3": "cloud",
        "45": "foggy",     "48": "foggy",
        "51": "rainy",     "53": "rainy",     "55": "rainy",
        "56": "rainy",     "57": "rainy",
        "61": "rainy",     "63": "rainy",     "65": "rainy",
        "66": "rainy",     "67": "rainy",
        "71": "cloudy_snowing", "73": "cloudy_snowing", "75": "snowing_heavy", "77": "cloudy_snowing",
        "80": "rainy",     "81": "rainy",     "82": "rainy",
        "85": "cloudy_snowing", "86": "snowing_heavy",
        "95": "thunderstorm", "96": "thunderstorm", "99": "thunderstorm"
    })

    function getWeatherIcon(code) {
        return weatherIcons[String(code)] || "air"
    }

    function getNotifIcon(summary, urgency) {
        const s = (summary || "").toLowerCase()
        if (s.includes("reboot"))      return "restart_alt"
        if (s.includes("recording"))   return "screen_record"
        if (s.includes("battery"))     return "power"
        if (s.includes("screenshot"))  return "screenshot_monitor"
        if (s.includes("welcome"))     return "waving_hand"
        if (s.includes("time"))        return "schedule"
        if (s.includes("installed"))   return "download"
        if (s.includes("update"))      return "update"
        if (urgency === NotificationUrgency.Critical) return "release_alert"
        return "chat"
    }

    function getVolumeIcon(volume, isMuted) {
        if (isMuted)       return "no_sound"
        if (volume >= 0.5) return "volume_up"
        if (volume > 0)    return "volume_down"
        return "volume_mute"
    }

    function getBatteryIcon(percentage, charging) {
        if (percentage === 1)
            return charging ? "battery_charging_full" : "battery_full"
        const level = Math.floor(percentage * 7)
        return charging ? `battery_charging_${(level + 3) * 10}` : `battery_${level}_bar`
    }
}
