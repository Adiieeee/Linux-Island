import QtQuick
import "."

// píldora colapsada, la parte que vive dentro del panel de plasma
Item {
    id: root

    implicitWidth: 150  // Change this number to your preferred compact width
    implicitHeight: Theme.collapsedHeight

    // en un panel grueso no se estira, se queda centrada con su alto de diseño
    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 150      // Matches root implicitWidth
        height: 27
        radius: height / 2
        color: Theme.surface
        clip: true      // Crops any overflowing widgets so it stays a neat pill

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Workspaces {
                anchors.verticalCenter: parent.verticalCenter
                visible: Cfg.showWorkspaces
            }
        }

        Clock {
            anchors.centerIn: parent
            visible: Cfg.showClock
        }
    }
}
