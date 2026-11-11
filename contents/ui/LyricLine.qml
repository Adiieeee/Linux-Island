pragma ComponentBehavior: Bound

import QtQuick
import "."

// the lyric line in the island's middle. each new line crossfades in: the
// old one fades out moving up, the new one fades in from below. two slots
// take turns, so the old line keeps its text while it leaves
Item {
    id: root

    // the line on show, and a number that changes with every new line
    // (Lyrics.shown), so the same words sung twice still count as new
    property string text
    property int serial: -1
    // how long a long line takes to slide to its end (MarqueeText.scrollMs)
    property int scrollMs: 3000
    // off while hidden: long lines don't slide
    property bool running: true

    // how far a line moves while it fades
    readonly property int shift: 6

    property bool onB: false
    // 0 → 1 over each change: the incoming slot's opacity, the outgoing's
    // complement
    property real progress: 1

    implicitHeight: a.implicitHeight

    // created while a line is already on (a second island): show it as is
    Component.onCompleted: {
        if (root.serial >= 0) {
            a.scrollMs = root.scrollMs;
            a.text = root.text;
        }
    }

    onSerialChanged: {
        root.onB = !root.onB;
        const slot = root.onB ? b : a;
        slot.scrollMs = root.scrollMs;
        slot.text = root.text;
        swap.restart();
    }

    NumberAnimation {
        id: swap
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: Theme.durShort
        easing.type: Easing.OutQuad
    }

    component Slot: MarqueeText {
        required property bool current

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: current ? root.shift * (1 - root.progress) : -root.shift * root.progress
        opacity: current ? root.progress : 1 - root.progress
        visible: opacity > 0
        running: root.running && current
        font.pixelSize: Theme.bodyMedium
        font.weight: Font.Medium
    }

    Slot {
        id: a
        current: !root.onB
    }
    Slot {
        id: b
        current: root.onB
    }
}
