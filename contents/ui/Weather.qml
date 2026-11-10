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

    readonly property string icon: Icons.weather[code] ?? ""

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
