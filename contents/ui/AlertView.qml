import QtQuick
import "."

// the notch's middle during an alert (Alerts.qml): an icon, then a level's
// bar and number, or a line of text. the bar is drawn like the control
// center's sliders (SliderCard): red past boostFrom, a tick at it, dimmed
// while muted
Item {
    id: root

    readonly property bool level: Alerts.value >= 0
    readonly property color tone: Alerts.critical ? Theme.alert : Alerts.dim ? Theme.fgFaint : Theme.fg

    implicitHeight: 20

    Text {
        id: glyph
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 20
        horizontalAlignment: Text.AlignHCenter
        text: Alerts.icon
        color: root.tone
        font.family: Theme.fontIcons
        font.pixelSize: 16
    }

    // ── a level: bar and number ──
    Text {
        id: valueText
        visible: root.level
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: valueMetrics.advanceWidth
        horizontalAlignment: Text.AlignRight
        text: Alerts.valueText
        color: Alerts.dim ? Theme.fgFaint : Alerts.value > Alerts.boostFrom ? Theme.alert : Theme.fg
        font.family: Theme.fontDots
        font.features: Theme.numFeatures
        font.pixelSize: Theme.bodySmall
        font.weight: Font.Bold
    }

    // the widest the number gets, so the bar doesn't move as it changes
    TextMetrics {
        id: valueMetrics
        font: valueText.font
        text: "000%"
    }

    Rectangle {
        id: track
        visible: root.level
        anchors.left: glyph.right
        anchors.leftMargin: 10
        anchors.right: valueText.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        height: 4
        radius: 2
        color: Theme.containerHighest

        readonly property real fillTo: Math.max(0, Math.min(1, Alerts.value))

        Rectangle {
            width: track.width * Math.min(track.fillTo, Alerts.boostFrom)
            height: parent.height
            radius: parent.radius
            color: Alerts.dim ? Theme.outline : Theme.fg

            Behavior on width {
                NumberAnimation {
                    duration: Theme.durShort
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Theme.emphasized
                }
            }
        }

        // past boostFrom (the volume over 100%), in red
        Rectangle {
            x: track.width * Alerts.boostFrom
            width: track.width * Math.max(0, track.fillTo - Alerts.boostFrom)
            height: parent.height
            radius: parent.radius
            color: Alerts.dim ? Theme.outline : Theme.alert
            visible: width > 0
        }

        // 100%, easy to find
        Rectangle {
            visible: Alerts.boostFrom < 1
            x: track.width * Alerts.boostFrom - 1
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: 8
            radius: 1
            color: Theme.outline
        }
    }

    // ── anything else: one line ──
    Text {
        visible: !root.level
        anchors.left: glyph.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: Alerts.text
        color: root.tone
        elide: Text.ElideRight
        font.family: Theme.font
        font.pixelSize: Theme.bodySmall
        font.weight: Font.Bold
    }
}
