pragma Singleton

import QtQuick
import org.kde.plasma.private.volume as PA
import "."

// short alerts in the notch, in place of KDE's on-screen display: the
// volume and the microphone, with their mute, for now. one alert at a time: a new one takes over
// at once, and the same level changing again only updates it.
// every source is live (signals from Plasma's own models), nothing polls.
// CompactPill shows Alerts.showing in its middle (AlertView)
QtObject {
    id: root

    // ── the alert on show ──
    // kind: "" (none), "volume", "mic". icon: a Material Symbols name. text: the
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
        if (!sink)
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
