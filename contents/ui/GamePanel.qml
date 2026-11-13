import QtQuick
import "."

// the panel that opens under the floating notch over a fullscreen game
// (main.qml's gameNotch window): only the media card and the recording +
// meters row. everything in it is mouse-driven, because the overlay never
// takes the keyboard (the game keeps it). Plasma's popup can't be used over
// a game: it must take the keyboard, and KWin then drops the game behind
// the panels, so the whole panel showed. laid out like the control center:
// a frame ring as wide as Plasma's visible one (translucent, but not blurred:
// blur crashes plasmashell), then the island, then 14 px padding
Item {
    id: root

    implicitWidth: Theme.expandedWidth + 2 * Theme.popupRing
    implicitHeight: content.implicitHeight + 14 + 12 + 2 * Theme.popupRing

    // the ring Plasma's popup frame leaves around the control center
    Rectangle {
        anchors.fill: parent
        radius: Theme.islandCorner + Theme.popupRing
        color: Qt.alpha(Theme.bg, 0.5)
    }

    Rectangle {
        id: island
        anchors.fill: parent
        anchors.margins: Theme.popupRing
        radius: Theme.islandCorner
        color: Theme.surface
    }

    Column {
        id: content
        anchors.left: island.left
        anchors.right: island.right
        anchors.top: island.top
        anchors.margins: 14
        spacing: 10

        // still: no per-frame redraws over the game; not raisable: a click
        // on the art would bring the player forward, out from behind the game
        MediaCard {
            width: parent.width
            still: true
            raisable: false
        }

        // a click anywhere on the recording card starts/stops (there's no
        // recording view here)
        RecordMetersRow {
            width: parent.width
            cardToggles: true
        }
    }
}
