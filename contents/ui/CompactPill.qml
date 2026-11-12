pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.private.mpris as Mpris
import "."

// píldora colapsada, la parte que vive dentro del panel de plasma
// desktop dots · notch · clock. the notch hangs from the screen edge
// (NotchShape): album art · middle · waveform while something plays or is
// paused, just today's date otherwise. the middle is the date, a new song's
// title and artist, or the lyric line being sung (both wider,
// Theme.lyricsWidth). the dots and the clock sit outside it, on the panel.
// as wide as its content, so main.qml can reserve exactly what is drawn,
// and as tall as the panel itself
Item {
    id: root

    // set by main.qml; only a horizontal panel gets the reach below
    property bool horizontal: true
    // set by main.qml: a panel on the screen's bottom edge hangs the notch
    // from the bottom instead
    property bool bottomEdge: false

    // the pointer entered the notch (not the sides): main.qml opens the
    // popup (only opens, never closes)
    signal openRequested
    // the pointer is on the notch: main.qml keeps the control center open
    readonly property bool notchHovered: notchMa.containsMouse

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
    // a video in the browser (YouTube): the date where a music player shows ♪
    // or ♫, since a video without lyrics isn't "a song without lyrics"
    readonly property bool browser: Media.isBrowser(root.player)

    // ── the cover's colours, for the tint (as on the media card) ──
    // only with the tint turned on (Cfg.tintIsland, off by default: the
    // notch is black like the control center); off, the cover isn't loaded
    // a second time and no colours are worked out.
    // ImageColors needs the loaded Image, not the URL: given a remote URL it
    // returns grey
    Image {
        id: artImg
        source: Cfg.tintIsland ? root.artUrl : ""
        asynchronous: true
        sourceSize.width: 92
        sourceSize.height: 92
        visible: false
        // a cached cover loads at once and status stays Ready, so paleta's
        // source never changes and it kept the previous cover's colours.
        // recompute after every new picture (as in MediaCard)
        onSourceChanged: Qt.callLater(root.refreshTones)
    }

    Kirigami.ImageColors {
        id: paleta
        source: artImg.status === Image.Ready ? artImg : null
    }

    function refreshTones() {
        if (artImg.status === Image.Ready)
            paleta.update();
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
    // "date": no song (long form, alone in the notch), or the lyrics turned
    // off (short form, between art and waveform; no track peek either).
    // "peek": a new song's title and artist, for a moment. "lyric": a line
    // is being sung (Lyrics.wide). "gap": a song with lyrics between lines
    // (intro, outro, a break of 4 s or more): one eighth note (♪). "nolyrics":
    // a song without lyrics, or with no title to look up: two beamed eighth
    // notes (♫). "blank": still looking the lyrics up (usually hidden by the
    // peek). the notes follow the Windhawk island this is modelled on. a
    // browser (YouTube) shows the date instead of ♪, ♫ or the blank.
    // pausing changes nothing here: the playhead stops, so Lyrics.wide and
    // the line on show stay as they are, and the waveform resting dim says
    // it's paused
    readonly property string mode: {
        if (!root.media || !Lyrics.enabled)
            return "date";
        if (root.peeking)
            return "peek";
        if (Lyrics.status === "found" && Lyrics.wide)
            return "lyric";
        if (root.browser)
            return "date";
        if (Lyrics.status === "found")
            return "gap";
        if (Lyrics.status === "loading")
            return "blank";
        return "nolyrics";
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
    readonly property real middleWidth: {
        if (root.mode === "date")
            return dateText.implicitWidth;
        if (root.mode === "peek" || root.mode === "lyric")
            return Theme.lyricsWidth;
        return Theme.noteWidth;
    }

    // today, for the date in the middle
    Timer {
        id: day
        property date now: new Date()
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: now = new Date()
    }

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
    // sides when only the date shows
    readonly property int padding: 12

    // what the art and the waveform take on each side, or the padding beside
    // a lone date
    readonly property real leftSide: root.ear + (root.media ? root.inset + root.tile + root.gap : root.padding)
    readonly property real rightSide: root.ear + (root.media ? root.edge + root.tile + root.gap : root.padding)

    // the notch itself, animated as its content changes; notchTarget is
    // where it's heading (the floating notch's window takes the larger of
    // the two, so a growing notch isn't clipped)
    readonly property real notchTarget: root.leftSide + root.middleWidth + root.rightSide
    property real notchWidth: root.notchTarget

    Behavior on notchWidth {
        NumberAnimation {
            duration: Theme.durLong
            easing.type: Easing.Bezier
            easing.bezierCurve: Theme.emphasizedDecel
        }
    }

    // ── outside the notch ──
    // the desktop dots on its left and the clock on its right, on the panel
    // itself. both sides are as wide as the wider of the two (the narrower
    // one gets empty space at its outer end), so the notch, and the popup
    // that opens under the whole widget, stay in the middle of the screen
    readonly property int sideGap: 12
    readonly property real sideWidth: root.notchOnly ? 0 : Math.max(dots.implicitWidth, clock.implicitWidth) + root.sideGap

    // just the notch, without the dots and the clock: the copy that floats
    // over a fullscreen game (main.qml). the two aren't even created then,
    // so there's no second TasksModel or ticking clock
    property bool notchOnly: false

    // the floating notch over a game is showing (main.qml): this notch is
    // hidden and its waveform stops listening. it's under the game anyway,
    // and while the control center is open over the game the panel shows
    // through, where it would sit under the floating one as a second notch.
    // the dots and the clock stay
    property bool asleep: false

    implicitWidth: 2 * root.sideWidth + root.notchWidth
    implicitHeight: Theme.collapsedHeight

    Loader {
        id: dots
        active: !root.notchOnly
        anchors.right: capsule.left
        anchors.rightMargin: root.sideGap
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -Theme.dotsLift
        sourceComponent: Workspaces {}
    }

    Loader {
        id: clock
        active: !root.notchOnly
        anchors.left: capsule.right
        anchors.leftMargin: root.sideGap
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -Theme.clockLift
        sourceComponent: Clock {}
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
        visible: !root.asleep
        x: root.sideWidth
        width: root.notchWidth
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: -root.reach
        anchors.bottomMargin: -root.reach

        // black like the control center (the same Theme.surface). with the
        // tint setting on, in the cover's colours while a song with art
        // plays or is paused; black again with just the date
        NotchShape {
            anchors.fill: parent
            flipped: root.bottomEdge
            tones: root.tones
            tint: Cfg.tintIsland && root.media && artImg.status === Image.Ready ? 1 : 0
        }

        // ── album art, round ──
        MediaPart {
            x: root.ear + root.inset + Theme.artNudge
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -Theme.artLift
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

        // ── middle: date, track peek, lyric line or a note ──
        // as wide as the capsule leaves between art and waveform while the
        // width animates, clipped, so a line widening the island is revealed
        // from the centre instead of running over the art
        Item {
            id: middle
            x: root.leftSide
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -Theme.middleLift
            width: Math.max(0, capsule.width - root.leftSide - root.rightSide)
            height: parent.height
            clip: true

            // "11 November 2026" alone in the notch, "11 Nov 2026" between art
            // and waveform. both in the clock's style (its font, bold,
            // tabular digits): in the interface font at medium weight, with
            // the short one letter-spaced, it looked like another font
            Layer {
                on: root.mode === "date"

                Text {
                    id: dateText
                    anchors.centerIn: parent
                    text: Cfg.locale.toString(day.now, root.media ? "d MMM yyyy" : "d MMMM yyyy")
                    color: Theme.fg
                    font.family: Theme.fontDots
                    font.features: Theme.numFeatures
                    font.pixelSize: Theme.bodySmall
                    font.weight: Font.Bold
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
                        paused: !root.isPlaying
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
                        paused: !root.isPlaying
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
                    paused: !root.isPlaying
                    // the line is on screen from its start to the next one;
                    // the slide fits in between, with a hold at each end
                    scrollMs: Math.max(500, (Lyrics.lineEnd - Lyrics.lineStart) * 1000 / Lyrics.rate - 2 * Theme.marqueeHold)
                }
            }

            Layer {
                on: root.mode === "gap"

                NoteGlyph {
                    anchors.centerIn: parent
                    kind: "eighth"
                }
            }

            Layer {
                on: root.mode === "nolyrics"

                NoteGlyph {
                    anchors.centerIn: parent
                    kind: "beamed"
                }
            }
        }

        // ── waveform: the real level of what the speakers play ──
        MediaPart {
            anchors.right: parent.right
            anchors.rightMargin: root.ear + root.edge
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -Theme.waveLift
            width: root.tile
            height: Math.round(root.tile * 0.75)

            LiveWave {
                anchors.fill: parent
                live: root.media && root.isPlaying && !root.asleep
            }
        }

        // only the notch opens the popup; the dots and the empty sides don't.
        // entering it opens it at once. clicks do nothing: no buttons are
        // accepted (they fall through to the panel), and the pointer stays
        // the plain arrow, since there's nothing to click
        MouseArea {
            id: notchMa
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: root.openRequested()
        }
    }
}
