pragma Singleton

import QtQuick
import "."

// wttr.in con xhr en vez de curl, sin salir a un proceso para bajar el json
QtObject {
    id: root

    property string temp: "--"
    property string desc: ""
    property string code: ""
    property string city: ""
    property bool ready: false
    // between sunrise and sunset at the last reading, from wttr.in's
    // astronomy. compared with this machine's clock, so it's right for the
    // place the computer is in (the default, found by IP), not for a
    // Weather city in another time zone
    property bool day: true

    readonly property string icon: root.iconFor(root.code, root.desc, root.day)

    function iconFor(code, desc, day) {
        if (code === "")
            return "";
        if (!day && Icons.weatherNight[code])
            return Icons.weatherNight[code];
        if (Icons.weather[code])
            return Icons.weather[code];
        // a code outside the standard 48 (wttr.in sent 149, "Smoky haze"):
        // guess from the description, first match wins
        const guesses = [[/thunder/i, "thunderstorm"], [/snow|blizzard/i, "weather_snowy"], [/sleet|ice|freezing/i, "weather_mix"], [/rain|drizzle|shower|precip/i, "rainy"], [/fog/i, "foggy"], [/mist|haze|smok|dust|sand/i, "mist"], [/overcast|cloud/i, "cloud"], [/sun|clear/i, day ? "sunny" : "clear_night"]];
        for (const g of guesses) {
            if (g[0].test(desc))
                return g[1];
        }
        return "cloud";
    }

    // "05:25 AM" → minutes after midnight; NaN for anything else ("No sunrise")
    function minutesOf(text) {
        const m = /^(\d{1,2}):(\d{2})\s*(AM|PM)$/i.exec(String(text).trim());
        if (!m)
            return NaN;
        const h = Number(m[1]) % 12 + (m[3].toUpperCase() === "PM" ? 12 : 0);
        return h * 60 + Number(m[2]);
    }

    function isDay(sunrise, sunset) {
        const rise = root.minutesOf(sunrise);
        const set = root.minutesOf(sunset);
        if (isNaN(rise) || isNaN(set))
            return true;
        const now = new Date();
        const t = now.getHours() * 60 + now.getMinutes();
        return t >= rise && t < set;
    }

    function fetch() {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE || xhr.status !== 200)
                return;
            try {
                const d = JSON.parse(xhr.responseText);
                const cur = d.current_condition[0];
                root.temp = cur.temp_C + "°";
                root.desc = cur.weatherDesc[0].value;
                root.code = cur.weatherCode;
                const area = d.nearest_area && d.nearest_area[0];
                root.city = area ? area.areaName[0].value : "";
                const astro = d.weather && d.weather[0] && d.weather[0].astronomy && d.weather[0].astronomy[0];
                root.day = astro ? root.isDay(astro.sunrise, astro.sunset) : true;
                root.ready = true;
            } catch (e) {}
        };
        const lugar = Cfg.weatherCity ? encodeURIComponent(Cfg.weatherCity) : "";
        xhr.open("GET", `https://wttr.in/${lugar}?format=j1`);
        xhr.send();
    }

    // ciudad cambiada a mano: refresca ya, no esperar los 15 min del tick
    readonly property Connections watchCity: Connections {
        target: Cfg
        function onWeatherCityChanged() {
            root.fetch();
        }
    }

    readonly property Timer tick: Timer {
        interval: 900000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetch()
    }
}
