pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.private.mpris as Mpris
import "."

// píldora colapsada, la parte que vive dentro del panel de plasma
// one black capsule: album art · middle · waveform while something plays or
// is paused, just the clock otherwise. the middle is the clock, or the lyric
// line being sung (wider, Theme.lyricsWidth). as wide as its content, so
// main.qml can reserve exactly what is drawn, and as tall as the panel itself
Item {
    id: root

    // set by main.qml; only a horizontal panel gets the reach below
    property bool horizontal: true

    // ── media ──
    // no buttons here: previous/play/next live in the control center.
    // always the active player (the one playing), whatever the media card
    // in the control center is set to (see Media.qml)
    readonly property var player: Media.active
    readonly property int playback: player?.playbackStatus ?? Mpris.PlaybackStatus.Stopped
    readonly property bool isPlaying: playback === Mpris.PlaybackStatus.Playing
    // playing or paused, not stopped
    readonly property bool media: Cfg.showMini && player !== null && playback !== Mpris.PlaybackStatus.Stopped
    readonly property string artUrl: player?.artUrl ?? ""

    // ── what the middle shows ──
    // "lyric": a line is being sung (Lyrics.wide, playing only). "clock":
    // everything else (nothing playing, paused, a song without lyrics, an
    // instrumental break). the clock giving way to the lyrics is an
    // experiment: it isn't anywhere else in the island
    readonly property string mode: {
        if (!root.media)
            return "clock";
        if (root.isPlaying && Lyrics.wide)
            return "lyric";
        return "clock";
    }
    readonly property real middleWidth: root.mode === "clock" ? clock.implicitWidth : Theme.lyricsWidth

    // ── as tall as the panel ──
    // the panel insets every applet by its theme's margins (Ant-Dark: 4 px
    // above and below), which left a gap around the island. the slot is
    // centred, so the gap on each side is half the difference to the panel
    // window; capped at the theme margin so a floating panel, whose window is
    // taller than the bar, isn't overshot
    KSvg.FrameSvgItem {
        id: panelSvg
        imagePath: "widgets/panel-background"
        visible: false
    }

    readonly property real reach: {
        const w = root.Window.window;
        if (!root.horizontal || !w)
            return 0;
        const gap = (w.height - root.height) / 2;
        const cap = Math.max(panelSvg.fixedMargins.top, panelSvg.fixedMargins.bottom);
        return Math.max(0, Math.min(gap, cap));
    }
    readonly property real capsuleHeight: root.height + 2 * root.reach

    // art and waveform are squares inset from the capsule's edge, small
    // enough to stay inside its round ends
    readonly property real inset: Math.round(capsuleHeight * 0.15)
    readonly property real tile: capsuleHeight - 2 * inset
    readonly property int gap: 16
    // sides when only the clock shows
    readonly property int padding: 12

    // what the art and the waveform take, or the padding beside a lone clock
    readonly property real sides: root.media ? 2 * (root.inset + root.tile + root.gap) : 2 * root.padding

    implicitWidth: root.sides + root.middleWidth
    implicitHeight: Theme.collapsedHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.durLong
            easing.type: Easing.Bezier
            easing.bezierCurve: Theme.emphasizedDecel
        }
    }

    // art and waveform come in and out together with the width
    component MediaPart: Item {
        opacity: root.media ? 1 : 0
        scale: root.media ? 1 : 0.6
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durLong
                easing.type: Easing.Bezier
                easing.bezierCurve: Theme.emphasizedDecel
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.durLong
                easing.type: Easing.Bezier
                easing.bezierCurve: Theme.emphasizedDecel
            }
        }
    }

    // one of the middle's contents, fading in and out as the mode changes
    component Layer: Item {
        property bool on: false

        anchors.fill: parent
        opacity: on ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durMedium
                easing.type: Easing.Bezier
                easing.bezierCurve: Theme.emphasizedDecel
            }
        }
    }

    Rectangle {
        id: capsule
        anchors.fill: parent
        anchors.topMargin: -root.reach
        anchors.bottomMargin: -root.reach
        radius: height / 2
        color: Theme.surface

        // ── album art, round ──
        MediaPart {
            x: root.inset
            anchors.verticalCenter: parent.verticalCenter
            width: root.tile
            height: root.tile

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Theme.surfaceHigh
            }

            // clip leaves it square; ShadowedImage really rounds it
            Kirigami.ShadowedImage {
                anchors.fill: parent
                radius: width / 2
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 64
                sourceSize.height: 64
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: root.artUrl === ""
                text: Icons.music
                color: Theme.fgDim
                font.family: Theme.fontIcons
                font.pixelSize: 14
            }
        }

        // ── middle: clock or lyric line ──
        // as wide as the capsule leaves between art and waveform while the
        // width animates, clipped, so a line widening the island is revealed
        // from the centre instead of running over the art
        Item {
            id: middle
            anchors.centerIn: parent
            width: Math.max(0, capsule.width - root.sides)
            height: parent.height
            clip: true

            Layer {
                on: root.mode === "clock"

                Clock {
                    id: clock
                    anchors.centerIn: parent
                }
            }

            Layer {
                id: lyricLayer
                on: root.mode === "lyric"

                LyricLine {
                    anchors.centerIn: parent
                    width: Theme.lyricsWidth
                    text: Lyrics.text
                    serial: Lyrics.shown
                    running: lyricLayer.visible
                    // the line is on screen from its start to the next one;
                    // the slide fits in between, with a hold at each end
                    scrollMs: Math.max(500, (Lyrics.lineEnd - Lyrics.lineStart) * 1000 / Lyrics.rate - 2 * Theme.marqueeHold)
                }
            }
        }

        // ── waveform: the real level of what the speakers play ──
        MediaPart {
            anchors.right: parent.right
            anchors.rightMargin: root.inset
            anchors.verticalCenter: parent.verticalCenter
            width: root.tile
            height: Math.round(root.tile * 0.75)

            LiveWave {
                anchors.fill: parent
                live: root.media && root.isPlaying
            }
        }
    }
}
