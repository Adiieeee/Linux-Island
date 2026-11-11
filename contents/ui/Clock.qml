import QtQuick
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

    // quickshell tenía SystemClock, acá un Timer común alcanza igual
    Timer {
        id: clock
        property date now: new Date()
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: now = new Date()
    }

    TextMetrics {
        id: molde
        font: label.font
        text: "00:00"
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.now, "HH:mm")
        color: Theme.fg
        font.family: Theme.fontDots
        font.features: Theme.numFeatures
        font.pixelSize: Theme.islandClock
        font.weight: Font.Bold
    }
}
