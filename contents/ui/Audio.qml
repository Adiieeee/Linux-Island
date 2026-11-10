pragma Singleton

import QtQuick
import org.kde.plasma.plasma5support as P5Support

// sonido con wpctl/pactl. SinkModel nativo de plasma no expone cuál está activo ni el volumen
// volumen cada segundo, lista de dispositivos solo con el panel abierto
QtObject {
    id: root

    readonly property real maxVolume: 1.5

    property real volume: 0
    property bool muted: false
    property string description: ""
    property string defaultSink: ""
    property string defaultSource: ""

    property var sinks: []
    property var sources: []

    readonly property int percent: Math.round(volume * 100)
    readonly property bool boosted: !muted && volume > 1

    // arrastrando la barra no pisar con el sondeo, llega tarde y salta
    property bool holding: false

    // con cero, no se consultan los dispositivos
    property int watchers: 0

    readonly property string volCmd: "wpctl get-volume @DEFAULT_AUDIO_SINK@"
    readonly property string devCmd: 'pactl get-default-sink; echo ---; pactl get-default-source; echo ---; LC_ALL=C pactl list sinks | grep -E "^[[:space:]]*(Name|Description):"; echo ---; LC_ALL=C pactl list sources | grep -E "^[[:space:]]*(Name|Description):"'

    readonly property P5Support.DataSource source: P5Support.DataSource {
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            const out = data["stdout"] ?? "";
            if (cmd === root.volCmd)
                root.readVolume(out);
            else if (cmd === root.devCmd)
                root.readDevices(out);
        }
    }

    function readVolume(text) {
        if (root.holding)
            return;
        const m = text.match(/Volume:\s*([0-9.]+)/);
        if (m)
            root.volume = Number(m[1]);
        root.muted = text.indexOf("[MUTED]") !== -1;
    }

    function readDevices(text) {
        const parts = text.split("---");
        if (parts.length < 4)
            return;
        root.defaultSink = parts[0].trim();
        root.defaultSource = parts[1].trim();
        root.sinks = root.parsePairs(parts[2]);
        // los ".monitor" son la escucha de lo que suena, no micrófonos
        root.sources = root.parsePairs(parts[3]).filter(d => !d.name.endsWith(".monitor"));

        const cur = root.sinks.filter(d => d.name === root.defaultSink);
        root.description = cur.length ? cur[0].description : "";
    }

    // pactl imprime name y description en renglones alternados
    function parsePairs(text) {
        const list = [];
        let name = "";
        for (const line of text.split("\n")) {
            const n = line.match(/^\s*Name:\s*(.*)$/);
            if (n) {
                name = n[1].trim();
                continue;
            }
            const d = line.match(/^\s*Description:\s*(.*)$/);
            if (d && name) {
                list.push({
                    name: name,
                    description: d[1].trim()
                });
                name = "";
            }
        }
        return list;
    }

    function refreshDevices() {
        root.source.connectSource(root.devCmd);
    }

    function setVolume(v) {
        const clamped = Math.max(0, Math.min(root.maxVolume, v));
        root.volume = clamped;
        root.muted = false;
        Exec.run(`wpctl set-volume -l ${root.maxVolume} @DEFAULT_AUDIO_SINK@ ${clamped.toFixed(2)}`);
    }

    function step(delta) {
        root.setVolume(root.volume + delta);
    }

    function toggleMute() {
        root.muted = !root.muted;
        Exec.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle");
    }

    function setDefaultSink(name) {
        root.defaultSink = name;
        Exec.run(`pactl set-default-sink "${name}"`);
        refreshTimer.restart();
    }

    function setDefaultSource(name) {
        root.defaultSource = name;
        Exec.run(`pactl set-default-source "${name}"`);
        refreshTimer.restart();
    }

    readonly property Timer refreshTimer: Timer {
        interval: 400
        onTriggered: root.refreshDevices()
    }

    readonly property Timer tick: Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.source.connectSource(root.volCmd);
            // el nombre se ve en la tarjeta sonido, se refresca aunque no haya panel abierto
            if (root.watchers > 0 || root.description === "")
                root.refreshDevices();
        }
    }
}
