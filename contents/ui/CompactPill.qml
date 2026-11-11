pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.private.mpris as Mpris
import "."

// píldora colapsada, la parte que vive dentro del panel de plasma
// one black notch hanging from the screen edge (NotchShape): album art ·
// middle · waveform while something plays or is paused, just the clock
// otherwise. the middle is the clock, a new song's
// title and artist, or the lyric line being sung (both wider,
// Theme.lyricsWidth). as wide as its content, so
// main.qml can reserve exactly what is drawn, and as tall as the panel itself
Item {
    id: root

    // set by main.qml; only a horizontal panel gets the reach below
    property bool horizontal: true
    // set by main.qml: a panel on the screen's bottom edge hangs the notch
    // from the bottom instead
    property bool bottomEdge: false

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

    // ── the cover's colours, for the tint (as on the media card) ──
    // ImageColors needs the loaded Image, not the URL: given a remote URL it
    // returns grey
    Image {
        id: artImg
        source: root.artUrl
        asynchronous: true
        sourceSize.width: 92
        sourceSize.height: 92
        visible: false
    }

    Kirigami.ImageColors {
        id: paleta
        source: artImg.status === Image.Ready ? artImg : null
    }

    // the palette's real colours by area, like MediaCard.tonos (highlight and
    // average are computed and can invent a colour that isn't on the cover)
    readonly property var tones: {
        const p = paleta.palette;
        if (!p || p.length === 0)
            return [paleta.dominant, paleta.dominant, paleta.dominant];
        return [p[0].color, p[Math.min(1, p.length - 1)].color, p[Math.min(2, p.length - 1)].color];
    }

    // ── what the middle shows ──
    // "peek": a new song's title and artist, for a moment. "lyric": a line
    // is being sung (Lyrics.wide). both only while playing. "clock":
    // everything else (nothing playing, paused, a song without lyrics, an
    // instrumental break). the clock giving way to the lyrics is an
    // experiment: it isn't anywhere else in the island
    readonly property string mode: {
        if (!root.media || !root.isPlaying)
            return "clock";
        if (root.peeking)
            return "peek";
        if (Lyrics.wide)
            return "lyric";
        return "clock";
    }

    // ── track peek ──
    // each song gets one peek, the first time it plays: a track change, the
    // first song after plasmashell starts, another player taking over, or a
    // song found paused once it's resumed. the artist often arrives a moment
    // after the title; that is a new key and starts the peek over with it
    // a function called on each change, not a "wantPeek" binding with a
    // handler: the handler sets peekedKey, which the binding reads, and
    // QML reported a binding loop
    property bool peeking: false
    property string peekedKey: ""

    function maybePeek(): void {
        if (!root.media || !root.isPlaying || Lyrics.key === "" || Lyrics.key === root.peekedKey)
            return;
        root.peekedKey = Lyrics.key;
        root.peeking = true;
        peekTimer.restart();
    }

    onMediaChanged: root.maybePeek()
    onIsPlayingChanged: root.maybePeek()
    Component.onCompleted: root.maybePeek()

    Connections {
        target: Lyrics
        function onKeyChanged() {
            root.maybePeek();
        }
    }

    Timer {
        id: peekTimer
        interval: Theme.peekDuration
        onTriggered: root.peeking = false
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

    // art and waveform are squares inset from the notch's body by the same
    // amount on every side
    readonly property real inset: Math.round(capsuleHeight * 0.15)
    readonly property real tile: capsuleHeight - 2 * inset
    // the notch's top flares take this much on each side of its body
    readonly property real ear: Theme.notchEar
    // the waveform sits 6 px further in from the right side than the art
    // from the left (from the capsule this replaced, where the plain inset
    // crowded its round end; kept because it looked right)
    readonly property real edge: inset + 6
    readonly property int gap: 16
    // sides when only the clock shows
    readonly property int padding: 12

    // what the art and the waveform take on each side, or the padding beside
    // a lone clock
    readonly property real leftSide: root.ear + (root.media ? root.inset + root.tile + root.gap : root.padding)
    readonly property real rightSide: root.ear + (root.media ? root.edge + root.tile + root.gap : root.padding)

    implicitWidth: root.leftSide + root.middleWidth + root.rightSide
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

    Item {
        id: capsule
        anchors.fill: parent
        anchors.topMargin: -root.reach
        anchors.bottomMargin: -root.reach

        // tinted with the cover's colours while a song with art plays or is
        // paused; plain black with just the clock
        NotchShape {
            anchors.fill: parent
            flipped: root.bottomEdge
            tones: root.tones
            tint: root.media && artImg.status === Image.Ready ? 1 : 0
        }

        // ── album art, round ──
        MediaPart {
            x: root.ear + root.inset
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

        // ── middle: clock, track peek or lyric line ──
        // as wide as the capsule leaves between art and waveform while the
        // width animates, clipped, so a line widening the island is revealed
        // from the centre instead of running over the art
        Item {
            id: middle
            x: root.leftSide
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, capsule.width - root.leftSide - root.rightSide)
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
                id: peekLayer
                on: root.mode === "peek"

                Column {
                    anchors.centerIn: parent
                    width: Theme.lyricsWidth

                    MarqueeText {
                        width: parent.width
                        text: Lyrics.track
                        running: peekLayer.visible
                        scrollMs: Theme.peekDuration - 2 * Theme.marqueeHold
                        // a size above the artist and bold, so the two lines
                        // read as title and byline at a glance
                        font.pixelSize: Theme.bodySmall
                        font.weight: Font.Bold
                    }
                    MarqueeText {
                        width: parent.width
                        visible: text !== ""
                        text: Lyrics.artist
                        running: peekLayer.visible
                        scrollMs: Theme.peekDuration - 2 * Theme.marqueeHold
                        color: Theme.fgDim
                        font.pixelSize: Theme.labelSmall
                    }
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
            anchors.rightMargin: root.ear + root.edge
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
