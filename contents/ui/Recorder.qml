pragma Singleton

import QtQuick
import "."
import Qt.labs.platform as Platform

// grabación con spectacle, wf-recorder no anda en kwin
// sin elegir monitor desde acá (spectacle pregunta), sin mezclar mic y audio del sistema
QtObject {
    id: root

    property bool recording: false
    property int elapsed: 0

    // ajustes
    // always a "Screen Record" folder inside the user's Videos folder
    readonly property string folder: Platform.StandardPaths.writableLocation(Platform.StandardPaths.MoviesLocation).toString().replace("file://", "") + "/Screen Record"
    property bool systemAudio: true
    property bool microphone: false

    property string lastFile: ""

    readonly property string elapsedText: {
        const m = Math.floor(elapsed / 60);
        const s = elapsed % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    readonly property Timer tick: Timer {
        running: root.recording
        interval: 1000
        repeat: true
        onTriggered: root.elapsed++
    }

    function start(): void {
        if (recording)
            return;
        elapsed = 0;
        const file = `${root.folder}/rec-${Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss")}.mp4`;
        root.lastFile = file;
        // spectacle has no CLI flag for audio: it reads "record system audio" and
        // "record microphone" from its own config, both off by default. write the
        // island's toggles there first (this overwrites spectacle's own setting)
        const audio = `kwriteconfig6 --file spectaclerc --group GuiConfig --key videoRecordSystemAudio --type bool ${root.systemAudio}; ` + `kwriteconfig6 --file spectaclerc --group GuiConfig --key videoRecordMicrophone --type bool ${root.microphone}; `;
        // "s" = pantalla, la palabra entera "screen" spectacle no la reconoce
        Exec.run(`${audio}mkdir -p '${root.folder}'; spectacle --background --record=s --output='${file}'`);
        recording = true;
    }

    // no se mata el proceso: sigint deja el mp4 sin moov atom (corrupto)
    // se para pidiéndole que grabe de nuevo, eso sí cierra bien el archivo
    // hay que repetir el mismo --output o tira la grabación a la basura
    // el pgrep es el seguro: si ya se cortó por otro lado, no arranca una nueva
    function stop(): void {
        if (!recording)
            return;
        Exec.run(`pgrep -x spectacle >/dev/null && spectacle --background --record=s --output='${root.lastFile}'`);
        recording = false;
    }

    function toggle(): void {
        if (recording)
            stop();
        else
            start();
    }

    // the default folder doesn't exist until the first recording
    function openFolder(): void {
        Exec.run(`mkdir -p '${root.folder}'; xdg-open '${root.folder}'`);
    }
}
