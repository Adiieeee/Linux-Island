pragma Singleton

import QtQuick
import org.kde.plasma.plasma5support as P5Support

// mismos datos que quickshell, de /proc y nvidia-smi, sin guardar callbacks
QtObject {
    id: root

    property int cpu: 0
    property int cpuTemp: 0
    property int mem: 0
    property string memText: "0G / 0G"
    // versión corta para la fila del medidor
    property string memShort: "0/0"
    property int gpu: 0
    property int gpuTemp: 0
    property bool gpuAvailable: false

    property var _prev: null

    // cpu + ram. temp por nombre de sensor (k10temp/coretemp), no ruta fija
    // sin comillas en $n: plasma5support separa el comando en palabras y se perdían
    readonly property string cpuCmd: 'head -1 /proc/stat; head -3 /proc/meminfo; for h in /sys/class/hwmon/hwmon*; do n=$(cat $h/name 2>/dev/null); case $n in k10temp|coretemp|zenpower) cat $h/temp1_input 2>/dev/null; break;; esac; done'

    readonly property string gpuCmd: "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits"

    readonly property P5Support.DataSource source: P5Support.DataSource {
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            const out = data["stdout"] ?? "";
            if (cmd === root.cpuCmd)
                root.readCpu(out);
            else if (cmd === root.gpuCmd)
                root.readGpu(out, data["exit code"] ?? 0);
        }
    }

    function readCpu(text) {
        const lines = text.trim().split("\n");
        if (lines.length < 4)
            return;

        const c = lines[0].split(/\s+/).slice(1).map(Number);
        const idle = c[3] + c[4];
        const total = c.reduce((a, b) => a + b, 0);

        if (root._prev) {
            const dTotal = total - root._prev.total;
            const dIdle = idle - root._prev.idle;
            if (dTotal > 0)
                root.cpu = Math.round(100 * (dTotal - dIdle) / dTotal);
        }
        root._prev = {
            total: total,
            idle: idle
        };

        const kb = l => Number(l.split(/\s+/)[1]);
        const totalKb = kb(lines[1]);
        const availKb = kb(lines[3]);
        root.mem = Math.round(100 * (totalKb - availKb) / totalKb);
        const gb = v => (v / 1048576).toFixed(1);
        root.memText = gb(totalKb - availKb) + "G / " + gb(totalKb) + "G";
        // total redondeado a entero, "7.8/31" ocupa menos que "7.8/31.3"
        root.memShort = gb(totalKb - availKb) + "/" + Math.round(totalKb / 1048576);

        // hwmon reporta milésimas de grado
        if (lines.length >= 5) {
            const t = Number(lines[4]);
            if (!isNaN(t))
                root.cpuTemp = Math.round(t / 1000);
        }
    }

    // si nvidia-smi falla o no existe, gpuAvailable queda false y no se muestra
    function readGpu(text, code) {
        const parts = text.trim().split(",");
        if (code !== 0 || parts.length < 2) {
            root.gpuAvailable = false;
            return;
        }
        const u = Number(parts[0].trim());
        const t = Number(parts[1].trim());
        if (isNaN(u) || isNaN(t)) {
            root.gpuAvailable = false;
            return;
        }
        root.gpu = u;
        root.gpuTemp = t;
        root.gpuAvailable = true;
    }

    readonly property Timer tick: Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.source.connectSource(root.cpuCmd);
            root.source.connectSource(root.gpuCmd);
        }
    }
}
