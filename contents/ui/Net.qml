pragma Singleton

import QtQuick
import org.kde.plasma.plasma5support as P5Support

// red y bluetooth con nmcli y bluetoothctl
// básico cada 8s, listas largas solo mientras hay un panel abierto
QtObject {
    id: root

    // ── red ──
    property bool wifiEnabled: false
    property bool connected: false
    property bool isWifi: false
    property string connectionName: ""
    property int signal_: 0

    property var savedNets: []
    property var nearbyNets: []

    // ── bluetooth ──
    property bool btEnabled: false
    property var btKnown: []
    property var btNearby: []

    // cuántos paneles abiertos, para pedir las listas solo entonces
    property int netWatchers: 0
    property int btWatchers: 0

    // ── intento de conexión en curso ──
    // connecting = nombre de red o mac que se está conectando, para la animación
    property string connecting: ""
    property string failed: ""
    // cmd en curso en runner, para ignorar respuestas de intentos ya cortados
    property string activeCmd: ""

    readonly property string baseCmd: 'nmcli -t -f TYPE,STATE,CONNECTION device; echo ---; nmcli radio wifi; echo ---; bluetoothctl show | grep Powered'

    readonly property string netListCmd: 'nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list; echo ---; nmcli -t -f NAME,TYPE connection show'

    readonly property string btListCmd: 'bluetoothctl devices Paired; echo ---; bluetoothctl devices Connected; echo ---; bluetoothctl devices'

    readonly property P5Support.DataSource source: P5Support.DataSource {
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            const out = data["stdout"] ?? "";
            if (cmd === root.baseCmd)
                root.readBase(out);
            else if (cmd === root.netListCmd)
                root.readNetList(out);
            else if (cmd === root.btListCmd)
                root.readBtList(out);
        }
    }

    function readBase(text) {
        const parts = text.split("---");
        if (parts.length < 3)
            return;

        let conn = false, wifi = false, name = "";
        for (const line of parts[0].split("\n")) {
            const p = line.split(":");
            if (p.length < 3 || p[1] !== "connected" || p[0] === "loopback")
                continue;
            conn = true;
            wifi = p[0] === "wifi";
            name = p[2];
            if (wifi)
                break;
        }
        root.connected = conn;
        root.isWifi = wifi;
        root.connectionName = name;

        root.wifiEnabled = parts[1].trim() === "enabled";
        root.btEnabled = /Powered:\s*yes/.test(parts[2]);
    }

    function readNetList(text) {
        const parts = text.split("---");
        if (parts.length < 2)
            return;

        const seen = {};
        const near = [];
        for (const line of parts[0].split("\n")) {
            const p = line.split(":");
            if (p.length < 4 || !p[1] || seen[p[1]])
                continue;
            seen[p[1]] = true;
            const inUse = p[0].trim() === "*";
            if (inUse)
                root.signal_ = Number(p[2]) || 0;
            near.push({
                name: p[1],
                signal: Number(p[2]) || 0,
                secure: p[3].trim() !== "",
                connected: inUse
            });
        }
        root.nearbyNets = near;

        const saved = [];
        for (const line of parts[1].split("\n")) {
            const p = line.split(":");
            if (p.length < 2 || !p[1].includes("wireless"))
                continue;
            saved.push({
                name: p[0],
                connected: p[0] === root.connectionName
            });
        }
        root.savedNets = saved;
    }

    function readBtList(text) {
        const parts = text.split("---");
        if (parts.length < 3)
            return;

        const on = {};
        for (const d of root.parseDevices(parts[1]))
            on[d.mac] = true;

        const paired = {};
        const known = [];
        for (const d of root.parseDevices(parts[0])) {
            paired[d.mac] = true;
            known.push({
                mac: d.mac,
                name: d.name,
                connected: !!on[d.mac]
            });
        }
        root.btKnown = known;
        root.btNearby = root.parseDevices(parts[2]).filter(d => !paired[d.mac]);
    }

    function parseDevices(text) {
        const list = [];
        for (const line of text.split("\n")) {
            const m = line.match(/^Device ([0-9A-F:]+) (.*)$/i);
            if (m)
                list.push({
                    mac: m[1],
                    name: m[2],
                    connected: false
                });
        }
        return list;
    }

    function refreshLists() {
        if (root.netWatchers > 0)
            root.source.connectSource(root.netListCmd);
        if (root.btWatchers > 0)
            root.source.connectSource(root.btListCmd);
    }

    function toggleWifi() {
        Exec.run(`nmcli radio wifi ${root.wifiEnabled ? "off" : "on"}`);
        root.wifiEnabled = !root.wifiEnabled;
    }

    function toggleBt() {
        Exec.run(`bluetoothctl power ${root.btEnabled ? "off" : "on"}`);
        root.btEnabled = !root.btEnabled;
    }

    // ── conectar ──
    // estos sí necesitan saber cómo terminaron, por eso van por su propio DataSource y no Exec
    readonly property P5Support.DataSource runner: P5Support.DataSource {
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            if (cmd !== root.activeCmd)
                return;
            root.settle((data["exit code"] ?? 0) === 0);
        }
    }

    // comillas simples para el shell, escapando solo la comilla simple
    function quote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function attempt(id, cmd) {
        root.failed = "";
        root.connecting = id;
        root.activeCmd = cmd;
        root.giveUp.restart();
        root.hurry.restart();
        root.runner.connectSource(cmd);
    }

    function settle(ok) {
        root.giveUp.stop();
        if (!ok)
            root.failed = root.connecting;
        root.connecting = "";
        root.activeCmd = "";
        root.refreshLists();
    }

    // red que no responde, no dejar la animación girando para siempre
    readonly property Timer giveUp: Timer {
        interval: 30000
        onTriggered: {
            root.runner.disconnectSource(root.activeCmd);
            root.settle(false);
        }
    }

    // mientras conecta, mirar más seguido que el tick de 8s
    readonly property Timer hurry: Timer {
        interval: 1500
        repeat: true
        running: root.connecting !== ""
        onTriggered: root.refreshLists()
    }

    function connectNet(name) {
        root.attempt(name, `nmcli connection up ${root.quote(name)}`);
    }

    // device wifi connect crea y guarda la red sola, sin contraseña para las abiertas
    function joinNet(ssid, password) {
        const extra = password ? ` password ${root.quote(password)}` : "";
        root.attempt(ssid, `nmcli device wifi connect ${root.quote(ssid)}${extra}`);
    }

    function disconnectNet(name) {
        Exec.run(`nmcli connection down ${root.quote(name)}`);
    }

    function forgetNet(name) {
        Exec.run(`nmcli connection delete ${root.quote(name)}`);
    }

    function connectBt(mac) {
        root.attempt(mac, `bluetoothctl connect ${mac}`);
    }

    function disconnectBt(mac) {
        Exec.run(`bluetoothctl disconnect ${mac}`);
    }

    // emparejar y conectar de una, recién emparejado no queda conectado solo
    function pairBt(mac) {
        root.attempt(mac, `bluetoothctl --timeout 25 pair ${mac} && bluetoothctl trust ${mac} && bluetoothctl connect ${mac}`);
    }

    function forgetBt(mac) {
        Exec.run(`bluetoothctl remove ${mac}`);
    }

    // buscar dispositivos solo con el panel de bluetooth abierto
    function scanBt(on) {
        if (on)
            Exec.run('bluetoothctl --timeout 20 scan on >/dev/null 2>&1 &');
    }

    readonly property Timer tick: Timer {
        interval: 8000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.source.connectSource(root.baseCmd);
            root.refreshLists();
        }
    }
}
