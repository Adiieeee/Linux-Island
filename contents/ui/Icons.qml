pragma Singleton

import QtQuick

// material symbols renderiza el nombre como icono (ligaduras), nombres y no codepoints
QtObject {
    readonly property string cpu: "speed"
    readonly property string mem: "memory"

    readonly property string volHigh: "volume_up"
    readonly property string volLow: "volume_down"
    readonly property string volMute: "volume_off"

    readonly property string wifi: "wifi"
    readonly property string wifiOff: "wifi_off"
    readonly property string ethernet: "lan"

    readonly property string batFull: "battery_full"
    readonly property string bat3q: "battery_6_bar"
    readonly property string batHalf: "battery_4_bar"
    readonly property string batQuarter: "battery_2_bar"
    readonly property string batEmpty: "battery_alert"
    readonly property string batCharging: "battery_charging_full"

    readonly property string play: "play_arrow"
    readonly property string pause: "pause"
    readonly property string next: "skip_next"
    readonly property string prev: "skip_previous"
    readonly property string music: "music_note"

    readonly property string close: "close"
    readonly property string bell: "notifications"
    readonly property string clearAll: "delete_sweep"

    // códigos de wttr.in a icono
    readonly property var weather: ({
            "113": "sunny",
            "116": "partly_cloudy_day",
            "119": "cloud",
            "122": "cloud",
            "143": "foggy",
            "176": "rainy",
            "179": "weather_snowy",
            "182": "rainy",
            "185": "rainy",
            "200": "thunderstorm",
            "227": "weather_snowy",
            "230": "weather_snowy",
            "248": "foggy",
            "260": "foggy",
            "263": "rainy",
            "266": "rainy",
            "281": "rainy",
            "284": "rainy",
            "293": "rainy",
            "296": "rainy",
            "299": "rainy",
            "302": "rainy",
            "305": "rainy",
            "308": "rainy",
            "311": "rainy",
            "353": "rainy",
            "356": "rainy",
            "359": "rainy",
            "386": "thunderstorm",
            "389": "thunderstorm",
            "392": "thunderstorm",
            "395": "weather_snowy"
        })
}
