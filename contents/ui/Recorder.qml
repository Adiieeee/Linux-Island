pragma Singleton

import QtQuick
import "."
import Qt.labs.platform as Platform
import org.kde.plasma.plasma5support as P5Support

// grabación con spectacle, wf-recorder no anda en kwin
// sin elegir monitor desde acá (spectacle pregunta), sin mezclar mic y audio del sistema
QtObject {
    id: root

    property bool recording: false
    property int elapsed: 0

    // ajustes
    // default: a "Screen Record" folder inside the user's Videos folder. the
    // folder picked in the recording view lives in the applet config
    // (Cfg.recFolder, empty = default); main.qml writes it on folderChosen
    readonly property string defaultFolder: Platform.StandardPaths.writableLocation(Platform.StandardPaths.MoviesLocation).toString().replace("file://", "") + "/Screen Record"
    readonly property string folder: Cfg.recFolder !== "" ? Cfg.recFolder : defaultFolder
    property bool systemAudio: true
    property bool microphone: false

    property string lastFile: ""

    // the singleton can't reach Plasmoid.configuration, so main.qml saves it
    signal folderChosen(string path)

    // single quotes for the shell, escaping only the single quote (as in Net)
    function quote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    // kdialog runs as its own process: a Qt dialog opened from the popup
    // would lose its parent when the popup hides on focus loss
    property string pickCmd: ""

    readonly property P5Support.DataSource picker: P5Support.DataSource {
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            if (cmd !== root.pickCmd)
                return;
            const path = (data["stdout"] ?? "").trim();
            // exit 1 = cancelled
            if ((data["exit code"] ?? 1) === 0 && path !== "")
                root.folderChosen(path === root.defaultFolder ? "" : path);
        }
    }

    function chooseFolder(): void {
        root.pickCmd = `kdialog --getexistingdirectory ${root.quote(root.folder)} --title ${root.quote(Cfg.t("Carpeta de grabaciones"))}`;
        root.picker.connectSource(root.pickCmd);
    }

    function resetFolder(): void {
        root.folderChosen("");
    }

    // the command that launched the current recording. spectacle stays alive
    // while it records, so this DataSource answers when the recording ends
    property string startCmd: ""

    readonly property P5Support.DataSource proc: P5Support.DataSource {
        engine: "executable"
        connectedSources: []

        // the command ends with "pgrep -x spectacle": exit 0 means another
        // spectacle (an open window that took the request) is still recording,
        // so keep the state. otherwise the recording ended on its own:
        // cancelled window pick, spectacle failing to start, or a stop from
        // spectacle's own tray icon
        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            if (cmd !== root.startCmd || !root.recording)
                return;
            if ((data["exit code"] ?? 1) !== 0)
                root.recording = false;
        }
    }

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
        root.startCmd = `${audio}mkdir -p ${root.quote(root.folder)}; spectacle --background --record=s --output=${root.quote(file)}; pgrep -x spectacle >/dev/null`;
        recording = true;
        root.proc.connectSource(root.startCmd);
    }

    // no se mata el proceso: sigint deja el mp4 sin moov atom (corrupto)
    // se para pidiéndole que grabe de nuevo, eso sí cierra bien el archivo
    // hay que repetir el mismo --output o tira la grabación a la basura
    // el pgrep es el seguro: si ya se cortó por otro lado, no arranca una nueva
    function stop(): void {
        if (!recording)
            return;
        Exec.run(`pgrep -x spectacle >/dev/null && spectacle --background --record=s --output=${root.quote(root.lastFile)}`);
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
        Exec.run(`mkdir -p ${root.quote(root.folder)}; xdg-open ${root.quote(root.folder)}`);
    }
}
