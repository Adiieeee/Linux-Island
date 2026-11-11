pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.private.mpris as Mpris
import "."

// píldora colapsada, la parte que vive dentro del panel de plasma
// one black capsule: album art · clock · waveform while something plays or
// is paused, just the clock otherwise. as wide as its content, so main.qml
// can reserve exactly what is drawn, and as tall as the panel itself
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

    implicitWidth: root.media ? 2 * (root.inset + root.tile + root.gap) + clock.implicitWidth : 2 * root.padding + clock.implicitWidth
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

        Clock {
            id: clock
            anchors.centerIn: parent
        }

        // ── waveform: not real audio, bars that move while it plays ──
        MediaPart {
            id: wave
            anchors.right: parent.right
            anchors.rightMargin: root.inset
            anchors.verticalCenter: parent.verticalCenter
            width: root.tile
            height: Math.round(root.tile * 0.75)

            // each bar: [high, low, ms up, ms down]. different periods so
            // they never line up
            readonly property var bars: [[0.55, 0.25, 420, 380], [0.95, 0.35, 330, 460], [0.7, 0.2, 510, 300], [1.0, 0.4, 290, 410]]
            readonly property real rest: 0.25

            Row {
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: wave.bars

                    Rectangle {
                        id: bar
                        required property var modelData

                        readonly property bool live: root.media && root.isPlaying

                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: Math.round(wave.height * wave.rest)
                        radius: width / 2
                        color: root.isPlaying ? Theme.fg : Theme.fgFaint

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durMedium
                            }
                        }

                        SequentialAnimation on height {
                            running: bar.live
                            loops: Animation.Infinite

                            NumberAnimation {
                                to: wave.height * bar.modelData[0]
                                duration: bar.modelData[2]
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                to: wave.height * bar.modelData[1]
                                duration: bar.modelData[3]
                                easing.type: Easing.InOutSine
                            }
                        }

                        // paused: settle low instead of freezing mid-swing
                        NumberAnimation {
                            id: settle
                            target: bar
                            property: "height"
                            to: Math.round(wave.height * wave.rest)
                            duration: Theme.durMedium
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Theme.emphasized
                        }
                        onLiveChanged: if (!live) settle.restart()
                    }
                }
            }
        }
    }
}
