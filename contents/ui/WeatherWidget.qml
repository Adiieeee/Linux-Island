import QtQuick
import "."

Row {
    spacing: 5
    visible: Weather.ready

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Weather.icon
        color: Theme.tertiary
        font.family: Theme.fontIcons
        font.pixelSize: 18
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Weather.temp
        color: Theme.fgVariant
        font.family: Theme.font
        font.pixelSize: Theme.labelMedium
    }
}
