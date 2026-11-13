import QtQuick
import org.kde.plasma.clock as PlasmaClock
import "."

// the panel island's clock, outside the notch on its right, on the panel.
// always 24-hour with a leading zero (HH:mm), whatever the Time setting
// (that one is for the control center's big clock), and as wide as "00:00"
// whatever the digits, so the island doesn't shift as they change (hard
// rule 8; the island's sides are as wide as the wider of dots and clock)
Item {
    id: root

    implicitWidth: molde.width
    implicitHeight: label.implicitHeight

    // Plasma's own clock source (the lock screen's uses it too): only HH:mm
    // shows, so it ticks on each minute instead of every second, and it
    // catches up after a suspend or a change of time, which a Timer set to
    // the next minute wouldn't (Qt's timers stand still while the machine
    // sleeps)
    PlasmaClock.Clock {
        id: clock
        trackSeconds: false
    }

    TextMetrics {
        id: molde
        font: label.font
        text: "00:00"
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.dateTime, "HH:mm")
        color: Theme.fg
        font.family: Theme.fontDots
        font.features: Theme.numFeatures
        font.pixelSize: Theme.islandClock
        font.weight: Font.Bold
    }
}
