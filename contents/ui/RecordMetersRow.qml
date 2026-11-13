import QtQuick
import "."

// the recording card and the hardware meters side by side: the control
// center's row above the bottom buttons, and the game panel's second row
// (moved here from ExpandedPanel so both use the same code)
Item {
    id: root

    // a click on the card itself starts/stops recording (the game panel)
    // instead of asking for the recording view
    property bool cardToggles: false

    // the card was clicked and the recording view should open (ExpandedPanel)
    signal settingsRequested

    implicitHeight: 106

    Rectangle {
        id: recCard
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * 0.42
        radius: Theme.shapeLg
        color: recMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

        Behavior on color {
            ColorAnimation {
                duration: Theme.durShort
            }
        }

        MouseArea {
            id: recMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            // the card opens the recording view (status and stop
            // while recording), or, with cardToggles (the game panel, which
            // has no recording view), starts/stops like the round button;
            // the round button starts/stops directly
            onClicked: {
                if (root.cardToggles)
                    Recorder.toggle();
                else
                    root.settingsRequested();
            }
        }

        Rectangle {
            id: recDot
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 30
            radius: height / 2
            // a step above surfaceHigh on hover, or it vanishes when
            // the whole card hovers to surfaceHigh
            color: Recorder.recording ? "transparent" : recBtnMa.containsMouse ? Theme.surfaceTop : Theme.surfaceHigh
            border.width: 1.5
            border.color: Recorder.recording ? Theme.alert : Theme.outline

            Behavior on border.color {
                ColorAnimation {
                    duration: Theme.durShort
                }
            }

            Rectangle {
                anchors.centerIn: parent
                visible: Recorder.recording
                width: 11
                height: 11
                radius: 2
                color: Theme.alert
            }

            Text {
                anchors.centerIn: parent
                visible: !Recorder.recording
                text: "play_arrow"
                color: Theme.fg
                font.family: Theme.fontIcons
                font.pixelSize: 18
            }

            // above the card's MouseArea, so the button doesn't open the view
            MouseArea {
                id: recBtnMa
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Recorder.toggle()
            }
        }

        Column {
            anchors.left: recDot.right
            anchors.leftMargin: 10
            anchors.right: recInfo.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                width: parent.width
                text: Cfg.t("GRABACIÓN")
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                font.letterSpacing: Theme.labelSpacing
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: Recorder.elapsedText
                color: Recorder.recording ? Theme.fg : Theme.fgFaint
                font.family: Theme.fontDots
                font.features: Theme.numFeatures
                font.pixelSize: 18
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
        }

        // current settings at a glance, top to bottom on the card's
        // right: screen or window, system audio, microphone.
        // on = dim, off = faint + the crossed-out glyph
        Column {
            id: recInfo
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                text: Recorder.mode === "w" ? "select_window" : "desktop_windows"
                color: Theme.fgDim
                font.family: Theme.fontIcons
                font.pixelSize: 15
            }

            Text {
                text: Recorder.systemAudio ? "volume_up" : "volume_off"
                color: Recorder.systemAudio ? Theme.fgDim : Theme.fgFaint
                font.family: Theme.fontIcons
                font.pixelSize: 15
            }

            Text {
                text: Recorder.microphone ? "mic" : "mic_off"
                color: Recorder.microphone ? Theme.fgDim : Theme.fgFaint
                font.family: Theme.fontIcons
                font.pixelSize: 15
            }
        }
    }

    Rectangle {
        anchors.left: recCard.right
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        radius: Theme.shapeLg
        color: Theme.containerHigh

        Meters {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 12
            anchors.rightMargin: 12
        }
    }
}
