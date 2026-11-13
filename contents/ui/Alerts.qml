pragma Singleton

import QtQuick
import org.kde.plasma.private.brightnesscontrolplugin as BC
import org.kde.plasma.private.volume as PA
import org.kde.plasma.workspace.dbus as DBus
import "."

// short alerts in the notch, in place of KDE's on-screen display: the
// volume, the output device, the microphone and the brightness keys, for
// now. one alert at a time: a new one takes over at once, and the same
// level changing again only updates it.
// every source is live (signals from Plasma's own models), nothing polls.
// CompactPill shows Alerts.showing in its middle (AlertView)
QtObject {
    id: root

    // ── the alert on show ──
    // kind: "" (none), "volume", "output", "mic", "brightness". icon: a Material Symbols name. text: the
    // line for an alert that isn't a level. value: a level's bar, 0..1 of
    // its whole range, or -1 for no bar; boostFrom: where the bar turns red
    // (the volume past 100%), 1 = never; valueText: the number beside it.
    // dim: muted. critical: in Theme.alert
    property string kind: ""
    property string icon: ""
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

    // props: any of icon, text, value, boostFrom, valueText, dim, critical;
    // the ones left out go back to their defaults
    function show(kind: string, props, ms: int): void {
        if (!root.armed || root.paused)
            return;
        root.icon = props.icon ?? "";
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
        if (!sink)
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

    // ── microphone ──
    // the default input's level and mute (the Microphone Mute key,
    // Meta+Volume Mute). inputs stop at 100%, so there's no red part
    readonly property Connections sourceWatch: Connections {
        target: PA.PreferredDevice.source
        function onVolumeChanged() {
            root.micAlert();
        }
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
