import QtQuick
import "."

// píldora colapsada, la parte que vive dentro del panel de plasma
// as wide as its content, so main.qml can reserve exactly what is drawn,
// and as tall as whatever height main.qml gives it (the panel thickness)
Item {
    id: root

    readonly property int padding: 12

    implicitWidth: content.implicitWidth + root.padding * 2
    implicitHeight: Theme.collapsedHeight

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: height / 2
        color: Theme.surface
        clip: true

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 10

            Workspaces {
                anchors.verticalCenter: parent.verticalCenter
                visible: Cfg.showWorkspaces
            }

            Clock {
                anchors.verticalCenter: parent.verticalCenter
                visible: Cfg.showClock
            }
        }
    }
}
