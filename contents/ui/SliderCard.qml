import QtQuick
import org.kde.plasma.private.brightnesscontrolplugin as BC
import "."

// full-width sliders for sound and brightness. a long track is easier to
// drag precisely than the small bar the sound card used to have
Rectangle {
    id: root

    // the island listens to this to open the matching overlay
    signal requestPanel(string mode)

    // same backend as Plasma's brightness applet: talks to PowerDevil over
    // DBus in-process and updates live, so nothing gets polled.
    // isSilent: no brightness OSD while dragging, the slider already shows it
    BC.ScreenBrightnessControl {
        id: screens
        isSilent: true
    }

    implicitHeight: rows.implicitHeight + 20
    radius: Theme.shapeLg
    color: Theme.containerHigh

    // all label columns are as wide as the widest label, so the tracks line up
    readonly property real labelWidth: {
        let w = 0;
        for (let i = 0; i < rows.children.length; i++) {
            const r = rows.children[i];
            if (r.labelImplicitWidth !== undefined)
                w = Math.max(w, r.labelImplicitWidth);
        }
        return Math.min(w, 96);
    }

    TextMetrics {
        id: valueMetrics
        font.family: Theme.fontDots
        font.features: Theme.numFeatures
        font.pixelSize: Theme.bodySmall
        font.weight: Font.Medium
        text: "150%"
    }

    // icon · label · track with knob · value
    component SliderRow: Item {
        id: row

        property string icon
        property color iconColor: Theme.fgVariant
        property string label
        property string valueText
        property color valueColor: Theme.fg

        // position on the track, 0..1
        property real value: 0
        // past this point the fill turns red (volume boost). 1 = never
        property real boostFrom: 1
        property color fillColor: Theme.fg
        // thin tick on the track at boostFrom, so 100% is easy to find
        property bool showMark: false
        property bool iconClickable: true

        // left button only: a right-click opens a panel, it doesn't drag
        readonly property bool pressed: dragArea.pressed && (dragArea.pressedButtons & Qt.LeftButton) !== 0
        readonly property real labelImplicitWidth: labelText.implicitWidth

        signal moved(real fraction)
        signal stepped(int direction)
        signal iconClicked
        signal rightClicked

        width: parent ? parent.width : 0
        height: 30

        Text {
            id: iconText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            horizontalAlignment: Text.AlignHCenter
            text: row.icon
            color: row.iconColor
            font.family: Theme.fontIcons
            font.pixelSize: 18

            MouseArea {
                anchors.fill: parent
                anchors.margins: -5
                cursorShape: row.iconClickable ? Qt.PointingHandCursor : Qt.ArrowCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        row.rightClicked();
                    else
                        row.iconClicked();
                }
            }
        }

        Text {
            id: labelText
            anchors.left: iconText.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: root.labelWidth
            text: row.label
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: Theme.labelSmall
            font.letterSpacing: Theme.labelSpacing
            elide: Text.ElideRight
        }

        Text {
            id: valueText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: valueMetrics.advanceWidth
            horizontalAlignment: Text.AlignRight
            text: row.valueText
            color: row.valueColor
            font.family: Theme.fontDots
            font.features: Theme.numFeatures
            font.pixelSize: Theme.bodySmall
            font.weight: Font.Medium
        }

        Item {
            id: trackArea
            anchors.left: labelText.right
            anchors.leftMargin: 12
            anchors.right: valueText.left
            anchors.rightMargin: 14
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            readonly property real fillTo: Math.max(0, Math.min(1, row.value))

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                radius: 3
                color: Theme.containerHighest

                Rectangle {
                    width: track.width * Math.min(trackArea.fillTo, row.boostFrom)
                    height: parent.height
                    radius: parent.radius
                    color: row.fillColor

                    Behavior on width {
                        enabled: !dragArea.pressed
                        NumberAnimation {
                            duration: Theme.durShort
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Theme.emphasized
                        }
                    }
                }

                // boost: from boostFrom up to the value, in red
                Rectangle {
                    x: track.width * row.boostFrom
                    width: track.width * Math.max(0, trackArea.fillTo - row.boostFrom)
                    height: parent.height
                    radius: parent.radius
                    color: Theme.alert
                    visible: width > 0
                }

                Rectangle {
                    visible: row.showMark
                    x: track.width * row.boostFrom - 1
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: 10
                    radius: 1
                    color: Theme.outline
                }
            }

            Rectangle {
                id: knob
                anchors.verticalCenter: parent.verticalCenter
                x: track.width * trackArea.fillTo - width / 2
                width: dragArea.pressed || dragArea.containsMouse ? 16 : 12
                height: width
                radius: width / 2
                color: trackArea.fillTo > row.boostFrom ? Theme.alert : row.fillColor

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durShort
                    }
                }
                Behavior on x {
                    enabled: !dragArea.pressed
                    NumberAnimation {
                        duration: Theme.durShort
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }
            }

            // the whole row height is grabbable, not just the 6 px track
            MouseArea {
                id: dragArea
                anchors.fill: parent
                anchors.leftMargin: -6
                anchors.rightMargin: -6
                hoverEnabled: true
                preventStealing: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                function apply(mx) {
                    row.moved(Math.max(0, Math.min(1, (mx - 6) / track.width)));
                }

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        row.rightClicked();
                }
                onPressed: mouse => {
                    if (mouse.button === Qt.LeftButton)
                        apply(mouse.x);
                }
                onPositionChanged: mouse => {
                    if (pressed && (mouse.buttons & Qt.LeftButton))
                        apply(mouse.x);
                }
                onWheel: wheel => row.stepped(wheel.angleDelta.y > 0 ? 1 : -1)
            }
        }
    }

    Column {
        id: rows
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 4

        // ── sound: real ceiling 150%, past 100% the fill turns red ──
        SliderRow {
            icon: Audio.muted ? "volume_off" : "volume_up"
            iconColor: Audio.muted ? Theme.outline : Audio.boosted ? Theme.alert : Theme.fgVariant
            label: Cfg.t("SONIDO")
            value: Audio.volume / Audio.maxVolume
            boostFrom: 1 / Audio.maxVolume
            showMark: true
            // muted keeps the level visible, just dimmed
            fillColor: Audio.muted ? Theme.outline : Theme.fg
            valueText: Audio.percent + "%"
            valueColor: Audio.muted ? Theme.outline : Audio.boosted ? Theme.alert : Theme.fg

            // the 1 s poll would overwrite the value mid-drag and make it jump
            onPressedChanged: Audio.holding = pressed
            onMoved: f => Audio.setVolume(f * Audio.maxVolume)
            onStepped: d => Audio.step(d * 0.05)
            onIconClicked: Audio.toggleMute()
            onRightClicked: root.requestPanel("audio")
        }

        // ── brightness: one row per display, like Plasma's own applet ──
        Repeater {
            id: screenRows
            model: screens.isBrightnessAvailable ? screens.displays : null

            delegate: SliderRow {
                id: screenRow

                readonly property real level: model.maxBrightness > 0 ? model.brightness / model.maxBrightness : 0

                // the model only updates after PowerDevil confirms (slower over
                // DDC for external monitors), so show the requested level while
                // dragging and for a moment after, or the knob would bounce back
                property real wanted: 0

                function request(f) {
                    // never fully black: 0 switches some backlights off
                    screenRow.wanted = Math.max(0.01, Math.min(1, f));
                    settle.restart();
                    screens.setBrightness(model.displayName, Math.round(screenRow.wanted * model.maxBrightness));
                }

                Timer {
                    id: settle
                    interval: 1000
                }

                icon: "light_mode"
                iconClickable: false
                // one display: just "screen". several: which one
                label: screenRows.count === 1 ? Cfg.t("PANTALLA") : model.isInternal ? Cfg.t("PORTÁTIL") : model.label.replace(/[-\s]+$/, "").toUpperCase()
                value: screenRow.pressed || settle.running ? screenRow.wanted : screenRow.level
                valueText: Math.round(screenRow.value * 100) + "%"

                onMoved: f => screenRow.request(f)
                onStepped: d => screenRow.request(screenRow.value + d * 0.05)
            }
        }
    }
}
