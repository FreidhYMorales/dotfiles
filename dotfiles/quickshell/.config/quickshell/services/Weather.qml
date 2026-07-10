pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// Weather service using open-meteo.com free API (no API key required).
// Compatible with Caelestia's Weather API used in the lock screen.
Singleton {
    id: root

    property string city:        ""
    property string loc:         ""
    property var    cc:          null
    property list<var> forecast:       []
    property list<var> hourlyForecast: []

    readonly property string icon:        cc ? _codeToIcon(cc.weatherCode) : "cloud_alert"
    readonly property string description: cc?.weatherDesc ?? qsTr("No weather")
    readonly property string temp:        formatTemp(cc?.tempC)
    readonly property string feelsLike:   formatTemp(cc?.feelsLikeC)
    readonly property int    humidity:    cc?.humidity ?? 0
    readonly property real   windSpeed:   cc?.windSpeed ?? 0

    function formatTemp(t) {
        if (t === undefined || t === null) return "--°C"
        return `${Math.round(t)}°C`
    }

    function reload() {
        if (!loc) {
            ipProc.running = false
            ipProc.running = true
        } else {
            _startWeather()
        }
    }

    function _startWeather() {
        if (!loc) return
        const coords = loc.split(",")
        if (coords.length < 2) return
        weatherProc.lat = coords[0].trim()
        weatherProc.lon = coords[1].trim()
        weatherProc.running = false
        weatherProc.running = true
    }

    function _codeToDesc(code) {
        const map = {
            0: "Clear", 1: "Clear", 2: "Partly cloudy", 3: "Overcast",
            45: "Fog", 48: "Fog",
            51: "Drizzle", 53: "Drizzle", 55: "Drizzle",
            61: "Light rain", 63: "Rain", 65: "Heavy rain",
            71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow",
            80: "Showers", 81: "Showers", 82: "Heavy showers",
            95: "Thunderstorm", 96: "Thunderstorm", 99: "Thunderstorm"
        }
        return map[code] || "Unknown"
    }

    function _codeToIcon(code) {
        const map = {
            0: "clear_day", 1: "clear_day", 2: "partly_cloudy_day", 3: "cloud",
            45: "foggy", 48: "foggy",
            51: "rainy", 53: "rainy", 55: "rainy",
            61: "rainy", 63: "rainy", 65: "rainy",
            71: "cloudy_snowing", 73: "cloudy_snowing", 75: "snowing_heavy", 77: "cloudy_snowing",
            80: "rainy", 81: "rainy", 82: "rainy",
            95: "thunderstorm", 96: "thunderstorm", 99: "thunderstorm"
        }
        return map[code] || "air"
    }

    // Step 1: geo-locate via IP
    Process {
        id: ipProc
        command: ["bash", "-c", "curl -sf --max-time 5 'https://ipinfo.io/json'"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                try {
                    const data = JSON.parse(line)
                    if (data.loc) {
                        root.loc  = data.loc
                        root.city = data.city || ""
                        root._startWeather()
                    }
                } catch(e) {
                    console.warn("Weather: IP parse error:", e)
                }
            }
        }
    }

    // Step 2: fetch weather from open-meteo using stored lat/lon
    Process {
        id: weatherProc
        property string lat: ""
        property string lon: ""
        command: ["bash", "-c",
            "curl -sf --max-time 10 \"https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min&hourly=temperature_2m,weather_code,precipitation_probability&timezone=auto&forecast_days=7\""
        ]
        running: false
        stdout: SplitParser {
            onRead: line => {
                try {
                    const data = JSON.parse(line)
                    if (!data.current) return
                    const cur = data.current
                    root.cc = {
                        weatherCode:  cur.weather_code,
                        weatherDesc:  root._codeToDesc(cur.weather_code),
                        tempC:        cur.temperature_2m,
                        feelsLikeC:   cur.apparent_temperature,
                        humidity:     cur.relative_humidity_2m,
                        windSpeed:    cur.wind_speed_10m
                    }

                    const fc = []
                    const daily = data.daily
                    if (daily) {
                        for (let i = 0; i < daily.time.length; i++) {
                            fc.push({
                                date:        daily.time[i],
                                maxTempC:    daily.temperature_2m_max[i],
                                minTempC:    daily.temperature_2m_min[i],
                                weatherCode: daily.weather_code[i],
                                icon:        root._codeToIcon(daily.weather_code[i])
                            })
                        }
                    }
                    root.forecast = fc

                    const hfc = []
                    const hourly = data.hourly
                    if (hourly) {
                        const now = new Date()
                        for (let i = 0; i < hourly.time.length; i++) {
                            const t = new Date(hourly.time[i] + ":00")
                            if (t < now) continue
                            hfc.push({
                                timestamp:    hourly.time[i],
                                tempC:        Math.round(hourly.temperature_2m[i]),
                                precipChance: hourly.precipitation_probability[i],
                                weatherCode:  hourly.weather_code[i],
                                icon:         root._codeToIcon(hourly.weather_code[i])
                            })
                            if (hfc.length >= 8) break
                        }
                    }
                    root.hourlyForecast = hfc
                } catch(e) {
                    console.warn("Weather: parse error:", e)
                }
            }
        }
    }

    Timer {
        interval: 3600000  // 1 hour
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.reload()
    }
}
