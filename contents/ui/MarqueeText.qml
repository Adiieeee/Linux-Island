import QtQuick
import "."

// one line of text in a fixed width. centred when it fits; when it doesn't,
// it waits Theme.marqueeHold, slides once until its end shows (over scrollMs)
// and stays there. the slide starts over when the text, the width or
// scrollMs change
Item {
    id: root

    property alias text: label.text
    property alias color: label.color
    property alias font: label.font
    // how long the slide itself takes
    property int scrollMs: 3000
    // off: back to the start, no slide
    property bool running: true

    readonly property real overflow: Math.max(0, label.implicitWidth - root.width)
    property real offset: 0

    implicitHeight: label.implicitHeight
    clip: true

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        x: root.overflow > 0 ? -root.offset : (root.width - implicitWidth) / 2
        color: Theme.fg
        font.family: Theme.font
        textFormat: Text.PlainText
    }

    SequentialAnimation {
        id: slide

        PauseAnimation {
            duration: Theme.marqueeHold
        }
        NumberAnimation {
            target: root
            property: "offset"
            from: 0
            to: root.overflow
            duration: Math.max(1, root.scrollMs)
            easing.type: Easing.InOutSine
        }
    }

    function restart(): void {
        slide.stop();
        root.offset = 0;
        if (root.running && root.overflow > 0)
            slide.start();
    }

    onTextChanged: Qt.callLater(root.restart)
    onOverflowChanged: Qt.callLater(root.restart)
    onScrollMsChanged: Qt.callLater(root.restart)
    onRunningChanged: Qt.callLater(root.restart)
}
