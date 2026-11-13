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

    // peak (linear 0..1) → dB → a height (0..1) made of two parts:
    // - how loud: the short average against the loudest recent moment, so
    //   a quietly mastered song isn't small and a soft passage is
    // - motion: how far this sample is above or below that average
    // a plain dB scale, even one relative to the recent peak, looked full
    // all the time: on a loud pop master the peaks only move ~3 dB (measured:
    // -9 to -5.7 dB for 80% of a song). with a base of 0.5 and a swing of
    // 0.4 a loud song sits around half height and moves, and only a loud
    // moment well above its average gets near the top.
    // the monitor isn't scaled by the volume slider (PipeWire leaves monitor
    // ports at full level), so turning the volume down doesn't shrink the bars
    readonly property real base: 0.5
    readonly property real swing: 0.4
    // a sample this many dB above (below) the average is a full swing up (down)
    readonly property real devDb: 3
    // share of each sample in the short average (~0.5 s)
    readonly property real avgRate: 0.1
    // loudness scale: the running peak is full, spanDb below it is nothing
    readonly property real spanDb: 30
    // the running peak jumps up at once and falls this many dB per sample
    // (2-3 dB/s: the monitor sends about 15-25 samples a second)
    readonly property real refFall: 0.12
    // and never counts as lower than this, so a quiet passage after a loud
    // one isn't blown up to full height
    readonly property real refFloorDb: -30
    // below this: silence
    readonly property real gateDb: -60
    // envelope: a rise shows at once, a fall keeps this much per sample
    readonly property real release: 0.5

    property real refDb: refFloorDb
    property real avgDb: gateDb
    property real env: 0
    // history[0] is the newest level (middle bar), history[k] is k samples older
    property var history: []

    function push(peak: real): void {
        let level = 0;
        const db = peak > 0.000001 ? 20 * Math.log(peak) / Math.LN10 : -120;
        if (db > wave.gateDb) {
            wave.avgDb += (db - wave.avgDb) * wave.avgRate;
            wave.refDb = Math.max(db, wave.refDb - wave.refFall);
            const top = Math.max(wave.refDb, wave.refFloorDb);
            const loud = Math.max(0, Math.min(1, (wave.avgDb - top + wave.spanDb) / wave.spanDb));
            const dev = Math.max(-1, Math.min(1, (db - wave.avgDb) / wave.devDb));
            level = Math.max(0, Math.min(1, loud * (wave.base + wave.swing * dev)));
        }
        wave.env = level > wave.env ? level : level + (wave.env - level) * wave.release;
        const next = [wave.env].concat(wave.history);
        next.length = Math.min(next.length, (wave.bars + 1) / 2);
        wave.history = next;
    }

    function quiet(): void {
        if (wave.live)
            return;
        wave.env = 0;
        wave.refDb = wave.refFloorDb;
        wave.avgDb = wave.gateDb;
        wave.history = [];
    }

    // a moment later, not in this handler: the bars' Behavior follows live
    // too and may not be enabled yet when this runs (tested: the bars then
    // dropped to rest at once instead of settling)
    onLiveChanged: if (!live)
        Qt.callLater(wave.quiet)

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

                // no animation while live: each sample sets the height (~24
                // frames a second). an animation between samples outlasted
                // the gap to the next one, so one always ran and the whole
                // panel was redrawn at the display's rate (144 fps, ~18 % of
                // a core with KWin). the usual settle when it stops, instead
                // of dropping at once
                Behavior on height {
                    enabled: !wave.live
                    NumberAnimation {
                        duration: Theme.durMedium
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
