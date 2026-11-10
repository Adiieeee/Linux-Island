import QtQuick
import "."

Item {
    id: root

    implicitWidth: active ? mini.implicitWidth : 0
    implicitHeight: Theme.collapsedHeight
    visible: Cfg.showMini && active

    readonly property bool active: mini.active

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.durLong
            easing.type: Easing.Bezier
            easing.bezierCurve: Theme.emphasizedDecel
        }
    }

    Item {
        id: container
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        width: parent.width
        height: parent.height

        opacity: root.active ? 1 : 0
        scale: root.active ? 1 : 0.72
        transformOrigin: Item.Left

        Behavior on opacity {
            NumberAnimation { duration: Theme.durMedium }
        }
        Behavior on scale {
            SpringAnimation {
                spring: 9.0
                damping: 0.5
                mass: 0.35
                epsilon: 0.005
            }
        }

        MiniPlayer {
            id: mini
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
        }
    }
}
