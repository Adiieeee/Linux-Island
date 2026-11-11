pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.private.volume as PA
import "."

// the island's waveform, driven by real audio: the peak level of everything
// the default output plays, read by plasma-pa's VolumeMonitor (the same live
// level meter Plasma's own audio applet draws in its sliders). it records a
// peak-detect stream from the sink's monitor, natively, with no process and
// no polling, and only while `live` is on: off, the target is null and the
// stream is closed
//
// the newest level sits in the middle bar and older ones spread outwards to
// both sides, so a beat looks like a pulse moving out from the centre
Item {
    id: wave

    // follow the audio (something is playing). off: the bars rest low and dim
    property bool live: false

    // odd, so one bar sits in the middle
    readonly property int bars: 5
    readonly property int barWidth: 3
    readonly property int barSpacing: 2
    // resting height, as a fraction of the item's height
    readonly property real rest: 0.25
    // the outermost bars are this much of the others, for a rounder outline
    readonly property real edgeScale: 0.8

    // peak (linear 0..1) → dB → 0..1, relative to a running peak: the loudest
    // recent moment is full height and spanDb below it is silence. songs are
    // mastered at very different levels (two measured Spotify tracks peaked at
    // -21 and -10 dB), and a fixed scale left the quiet one small and pinned
    // the loud one at the top. a peak meter barely moves on dense music (a few
    // dB between samples), hence the narrow window.
    // the monitor isn't scaled by the volume slider (PipeWire leaves monitor
    // ports at full level), so turning the volume down doesn't shrink the bars
    readonly property real spanDb: 24
    // the running peak jumps up at once and falls this many dB per sample
    // (~3 dB/s at the monitor's ~25 samples a second)
    readonly property real refFall: 0.12
    // and never counts as lower than this, so a quiet passage after a loud
    // one isn't blown up to full height
    readonly property real refFloorDb: -30
    // keeps quiet passages small
    readonly property real curve: 1.3
    // envelope: a rise shows at once, a fall keeps this much per sample
    readonly property real release: 0.5

    property real refDb: refFloorDb
    property real env: 0
    // history[0] is the newest level (middle bar), history[k] is k samples older
    property var history: []

    function push(peak: real): void {
        let level = 0;
        if (peak > 0.00001) {
            const db = 20 * Math.log(peak) / Math.LN10;
            wave.refDb = Math.max(db, wave.refDb - wave.refFall);
            const top = Math.max(wave.refDb, wave.refFloorDb);
            level = Math.pow(Math.max(0, Math.min(1, (db - top + wave.spanDb) / wave.spanDb)), wave.curve);
        }
        wave.env = level > wave.env ? level : level + (wave.env - level) * wave.release;
        const next = [wave.env].concat(wave.history);
        next.length = Math.min(next.length, (wave.bars + 1) / 2);
        wave.history = next;
    }

    onLiveChanged: if (!live) {
        wave.env = 0;
        wave.refDb = wave.refFloorDb;
        wave.history = [];
    }

    PA.VolumeMonitor {
        target: wave.live ? PA.PreferredDevice.sink : null
        onVolumeChanged: wave.push(volume)
    }

    Row {
        anchors.centerIn: parent
        spacing: wave.barSpacing

        Repeater {
            model: wave.bars

            Rectangle {
                id: bar
                required property int index

                readonly property int distance: Math.abs(bar.index - (wave.bars - 1) / 2)
                readonly property real level: (wave.history[bar.distance] ?? 0) * (bar.distance === (wave.bars - 1) / 2 ? wave.edgeScale : 1)

                anchors.verticalCenter: parent.verticalCenter
                width: wave.barWidth
                height: Math.round(wave.height * (wave.rest + (1 - wave.rest) * bar.level))
                radius: width / 2
                color: wave.live ? Theme.fg : Theme.fgFaint

                // short while live, to smooth the steps between samples; the
                // usual settle when it stops, instead of dropping at once
                Behavior on height {
                    NumberAnimation {
                        duration: wave.live ? Theme.durTick : Theme.durMedium
                        easing.type: Easing.OutQuad
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durMedium
                    }
                }
            }
        }
    }
}
