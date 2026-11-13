pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import org.kde.bluezqt as BluezQt
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.brightnesscontrolplugin as BC
import org.kde.plasma.private.clipboard as Clip
import org.kde.plasma.private.volume as PA
import org.kde.plasma.workspace.dbus as DBus
import "."
import "alerts.js" as AlertsLib

// short alerts in the notch, in place of KDE's on-screen display: the
// volume, the output device, the microphone's mute, the brightness keys,
// the clipboard, Bluetooth devices, the charger, a low battery and a saved
// recording. one alert at a time: a new one takes over at once, and the
// same level changing again only updates it. every source is live
// (signals from Plasma's own models), nothing polls. CompactPill shows
// Alerts.showing in its middle (AlertView)
QtObject {
    id: root

    // ── the alert on show ──
    // kind: "" (none), "volume", "output", "mic", "brightness",
    // "clipboard", "bluetooth", "charger", "battery", "record".
    // icon: a Material Symbols name; image: a picture in its place (a
    // copied image). text: the line for an alert that isn't a level.
    // value: a level's bar, 0..1 of its whole range, or -1 for no bar;
    // boostFrom: where the bar turns red (the volume past 100%), 1 = never;
    // valueText: the number beside the bar or the line. dim: muted.
    // critical: in Theme.alert
    property string kind: ""
    property string icon: ""
    property string image: ""
    property string text: ""
    property real value: -1
    property real boostFrom: 1
    property string valueText: ""
    property bool dim: false
    property bool critical: false
    readonly property bool showing: root.kind !== ""

    // the control center is open (main.qml): its sliders already show
    // every level, so nothing alerts, and an alert on show goes
    property bool paused: false
    onPausedChanged: if (root.paused)
        root.hide()

    // the sources' first values after the widget starts aren't changes
    property bool armed: false
    readonly property Timer armTimer: Timer {
        interval: Theme.alertArmDelay
        running: true
        onTriggered: root.armed = true
    }

    readonly property Timer hideTimer: Timer {
        onTriggered: root.hide()
    }

    // props: any of icon, image, text, value, boostFrom, valueText, dim,
    // critical; the ones left out go back to their defaults
    function show(kind: string, props, ms: int): void {
        if (!root.armed || root.paused || !root.allowed(kind))
            return;
        root.icon = props.icon ?? "";
        root.image = props.image ?? "";
        root.text = props.text ?? "";
        root.value = props.value ?? -1;
        root.boostFrom = props.boostFrom ?? 1;
        root.valueText = props.valueText ?? "";
        root.dim = props.dim ?? false;
        root.critical = props.critical ?? false;
        root.kind = kind;
        root.hideTimer.interval = ms;
        root.hideTimer.restart();
    }

    // each kind has its own switch in the settings (Cfg.alert...)
    function allowed(kind: string): bool {
        switch (kind) {
        case "volume":
            return Cfg.alertVolume;
        case "mic":
            return Cfg.alertMic;
        case "output":
            return Cfg.alertOutput;
        case "brightness":
            return Cfg.alertBrightness;
        case "clipboard":
            return Cfg.alertClipboard;
        case "bluetooth":
            return Cfg.alertBluetooth;
        case "charger":
            return Cfg.alertCharger;
        case "battery":
            return Cfg.alertBattery;
        case "record":
            return Cfg.alertRecord;
        }
        return true;
    }

    function hide(): void {
        root.hideTimer.stop();
        root.kind = "";
    }

    // ── volume ──
    // the default output's level and mute, from plasma-pa: any change, from
    // the volume keys, a headset's own buttons or another mixer. the bar
    // spans 0..150%, the ceiling the island's volume slider has too
    readonly property real maxVolume: 1.5

    readonly property Connections sinkWatch: Connections {
        target: PA.PreferredDevice.sink
        function onVolumeChanged() {
            root.volumeAlert();
        }
        function onMutedChanged() {
            root.volumeAlert();
        }
    }

    function volumeAlert(): void {
        const sink = PA.PreferredDevice.sink;
        if (!sink || Date.now() - root.sinkSwitchedAt < Theme.alertQuietMs)
            return;
        const level = sink.volume / PA.PulseAudio.NormalVolume;
        root.show("volume", {
            icon: sink.muted ? "volume_off" : level < 0.5 ? "volume_down" : "volume_up",
            value: Math.min(1, level / root.maxVolume),
            boostFrom: 1 / root.maxVolume,
            valueText: Math.round(level * 100) + "%",
            dim: sink.muted
        }, Theme.alertLevelMs);
    }

    // ── output device ──
    // the default output changing (a headset plugged in, a pick in the
    // sound dropdown): the new device's name and icon, as the dropdown
    // shows them. its volume stays quiet for a moment (volumeAlert)
    property double sinkSwitchedAt: 0

    readonly property Connections preferredWatch: Connections {
        target: PA.PreferredDevice
        function onSinkChanged() {
            root.outputAlert();
        }
    }

    function outputAlert(): void {
        root.sinkSwitchedAt = Date.now();
        const sink = PA.PreferredDevice.sink;
        // a Bluetooth headset that just connected becomes the output a
        // moment later: its own alert already names it
        if (!sink || root.kind === "bluetooth")
            return;
        root.show("output", {
            icon: Audio.deviceIcon(sink, false),
            text: Audio.deviceName(sink)
        }, Theme.alertMs);
    }

    // ── brightness ──
    // only the brightness keys set up as in the README: they call
    // PowerDevil with its indicator off and the context "linuxisland".
    // PowerDevil announces every change with the context that asked for
    // it, so dimming when idle, the control center's slider or Plasma's
    // brightness applet don't alert
    readonly property BC.ScreenBrightnessControl screens: BC.ScreenBrightnessControl {}

    // each display's ceiling, by its DBus name (the model's displayName)
    component ScreenRow: QtObject {
        required property string displayName
        required property int maxBrightness
    }

    readonly property Instantiator screenRows: Instantiator {
        model: root.screens.isBrightnessAvailable ? root.screens.displays : null
        delegate: ScreenRow {}
    }

    function maxBrightness(display: string): int {
        for (let i = 0; i < root.screenRows.count; i++) {
            const row = root.screenRows.objectAt(i) as ScreenRow;
            if (row && row.displayName === display)
                return row.maxBrightness;
        }
        return 0;
    }

    // SignalWatcher calls dbus<SignalName> for each signal of the
    // interface; strings arrive wrapped ({value: ...}), see plain()
    readonly property DBus.SignalWatcher brightnessWatch: DBus.SignalWatcher {
        busType: DBus.BusType.Session
        service: "org.kde.ScreenBrightness"
        path: "/org/kde/ScreenBrightness"
        iface: "org.kde.ScreenBrightness"

        function dbusBrightnessChanged(display, brightness, client, context) {
            root.brightnessAlert(root.plain(display), root.plain(brightness), root.plain(context));
        }
    }

    function plain(arg) {
        return arg?.value ?? arg;
    }

    function brightnessAlert(display: string, brightness: int, context: string): void {
        if (context !== "linuxisland")
            return;
        const max = root.maxBrightness(display);
        if (max <= 0)
            return;
        const level = brightness / max;
        root.show("brightness", {
            icon: "light_mode",
            value: level,
            valueText: Math.round(level * 100) + "%"
        }, Theme.alertLevelMs);
    }

    // ── clipboard ──
    // what was just copied, from Klipper's history (the model Plasma's
    // clipboard applet uses, shared inside plasmashell): the first line of
    // a text, or a copied picture's thumbnail. a password manager's copies
    // never reach the history (Klipper skips them), so they don't show.
    // the newest entry is row 0; it's read once the model has settled.
    // only inside plasmashell, where the clipboard applet already made it:
    // anywhere else (a test in the qml tool) it starts a second Klipper,
    // which crashed offscreen (SystemClipboard asks X11 for the focus) and
    // would otherwise write to the same history database. with its alert
    // turned off the clipboard isn't read at all
    readonly property Instantiator clipboard: Instantiator {
        active: Qt.application.name === "plasmashell" && Cfg.alertClipboard
        delegate: Clip.HistoryModel {
            onCurrentTextChanged: Qt.callLater(root.clipboardAlert)
        }
    }

    function clipboardAlert(): void {
        const model = root.clipboard.object as Clip.HistoryModel;
        if (!model || model.count === 0)
            return;
        const top = model.index(0, 0);
        const picture = String(model.data(top, Qt.DecorationRole) ?? "");
        if (picture !== "") {
            root.show("clipboard", {
                icon: "image",
                image: picture,
                text: Cfg.t("Imagen copiada")
            }, Theme.alertClipMs);
            return;
        }
        const line = AlertsLib.preview(model.data(top, Qt.DisplayRole));
        if (line === "")
            return;
        root.show("clipboard", {
            icon: "content_copy",
            text: line
        }, Theme.alertClipMs);
    }

    // ── Bluetooth ──
    // a device that connects (BluezQt, what Plasma's Bluetooth applet
    // uses): its name, and its battery when it reports one. the battery
    // often arrives a moment after the connection; it fills in then, and
    // the alert's time starts over so it can be read
    property string bluetoothAddress: ""

    component DeviceWatch: Connections {
        // a BluezQt device, owned by BluezQt
        required property var modelData

        target: modelData
        function onConnectedChanged(connected) {
            if (connected)
                root.bluetoothAlert(modelData);
        }
        function onBatteryChanged() {
            if (root.kind === "bluetooth" && root.bluetoothAddress === modelData.address)
                root.bluetoothAlert(modelData);
        }
    }

    readonly property Instantiator bluetoothDevices: Instantiator {
        model: BluezQt.Manager.devices
        delegate: DeviceWatch {}
    }

    function bluetoothAlert(device): void {
        const battery = device.battery ? device.battery.percentage : -1;
        root.show("bluetooth", {
            icon: AlertsLib.bluetoothIcon(device.icon),
            text: device.name,
            valueText: battery >= 0 ? battery + "%" : ""
        }, Theme.alertMs);
        root.bluetoothAddress = device.address;
    }

    // ── charger and battery ──
    // Plasma's power management engine, as the control center's battery
    // (Battery.qml): it pushes each change, nothing polls. plugging in or
    // out shows the level; going down to 20% or 10% on battery shows it in
    // red. the first readings are only the starting point
    property int batteryPercent: -1
    property int pluggedIn: -1

    readonly property P5Support.DataSource power: P5Support.DataSource {
        engine: "powermanagement"
        connectedSources: ["Battery", "AC Adapter"]
        onNewData: (source, data) => {
            if (source === "Battery")
                root.batteryRead(data);
            else if (source === "AC Adapter")
                root.adapterRead(data);
        }
    }

    function batteryRead(data): void {
        // a desktop reports a phantom battery, "Unknown" (see Battery.qml)
        if (!(data["Has Battery"] ?? false) || data["State"] === "Unknown")
            return;
        const now = data["Percent"] ?? 0;
        const low = AlertsLib.lowCrossing(root.batteryPercent, now, root.pluggedIn === 0);
        root.batteryPercent = now;
        if (low > 0) {
            root.show("battery", {
                icon: "battery_alert",
                text: Cfg.t("Batería baja"),
                valueText: now + "%",
                critical: true
            }, Theme.alertMs);
        }
    }

    function adapterRead(data): void {
        const plugged = (data["Plugged in"] ?? false) ? 1 : 0;
        const before = root.pluggedIn;
        root.pluggedIn = plugged;
        if (before < 0 || before === plugged || root.batteryPercent < 0)
            return;
        root.show("charger", {
            icon: plugged ? "power" : "battery_full",
            text: plugged ? Cfg.t("Enchufado") : Cfg.t("Con batería"),
            valueText: root.batteryPercent + "%"
        }, Theme.alertMs);
    }

    // ── screen recording ──
    // a recording stopped from the island (Recorder.saved)
    readonly property Connections recorderWatch: Connections {
        target: Recorder
        function onSaved() {
            root.show("record", {
                icon: "videocam",
                text: Cfg.t("Grabación guardada")
            }, Theme.alertMs);
        }
    }

    // ── microphone ──
    // the default input muted or unmuted (the Microphone Mute key,
    // Meta+Volume Mute), with its level. not its level changing: in a call
    // the browser's automatic gain control moves it all the time.
    // inputs stop at 100%, so there's no red part
    readonly property Connections sourceWatch: Connections {
        target: PA.PreferredDevice.source
        function onMutedChanged() {
            root.micAlert();
        }
    }

    function micAlert(): void {
        const source = PA.PreferredDevice.source;
        if (!source)
            return;
        const level = source.volume / PA.PulseAudio.NormalVolume;
        root.show("mic", {
            icon: source.muted ? "mic_off" : "mic",
            value: Math.min(1, level),
            valueText: Math.round(level * 100) + "%",
            dim: source.muted
        }, Theme.alertLevelMs);
    }
}
