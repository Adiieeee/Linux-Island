import QtQuick
import "."

Row {
    id: root
    spacing: 4

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: !Net.connected ? Icons.wifiOff : Net.isWifi ? Icons.wifi : Icons.ethernet
        color: Net.connected ? Theme.fg : Theme.error
        font.family: Theme.fontIcons
        font.pixelSize: 18
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: Net.isWifi
        text: Net.signal_
        color: Theme.fgVariant
        font.family: Theme.font
        font.pixelSize: Theme.labelMedium
    }
}
