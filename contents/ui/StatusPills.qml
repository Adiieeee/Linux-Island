import QtQuick
import "."

// status cards row: network and bluetooth (sound lives in SliderCard)
Row {
    id: root
    spacing: 8

    property real pillWidth: (width - spacing) / 2

    // la isla escucha esto para abrir el panel correspondiente
    signal requestPanel(string mode)

    // ── red ──
    readonly property bool device: Net.connected
    readonly property bool isWifi: Net.isWifi
    readonly property bool isEthernet: Net.connected && !Net.isWifi

    // ethernet si hay cable, wifi si no
    Rectangle {
        id: netPill
        width: root.pillWidth
        height: 52
        radius: Theme.shapeLg
        color: root.device ? Theme.inverted : netMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

        Behavior on color {
            ColorAnimation {
                duration: Theme.durMedium
            }
        }

        MouseArea {
            id: netMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.requestPanel("wifi");
                else
                    Net.toggleWifi();
            }
        }

        Rectangle {
            id: netIconBg
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            radius: height / 2
            color: root.device ? Theme.invertedFg : Theme.surfaceHigh

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durMedium
                }
            }

            Text {
                anchors.centerIn: parent
                text: !root.device ? "wifi_off" : root.isEthernet ? "lan" : "wifi"
                color: root.device ? Theme.inverted : Theme.fgDim
                font.family: Theme.fontIcons
                font.pixelSize: 18
            }
        }

        Column {
            anchors.left: netIconBg.right
            anchors.leftMargin: 9
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                width: parent.width
                text: {
                    if (!root.device)
                        return Cfg.t("Sin red");
                    if (root.isEthernet)
                        return "Ethernet";
                    return Net.connectionName || "Wi-Fi";
                }
                color: root.device ? Theme.invertedFg : Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: {
                    if (!root.device)
                        return Cfg.t("SIN RED");
                    if (root.isEthernet)
                        return Cfg.t("CONECTADO");
                    return Net.signal_ + "%";
                }
                color: root.device ? Theme.invertedFg : Theme.fgDim
                font.letterSpacing: Theme.labelSpacing
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                elide: Text.ElideRight
            }
        }
    }

    // ── bluetooth (clic para encender/apagar) ──
    Rectangle {
        id: btPill
        readonly property bool on: Net.btEnabled
        readonly property var connectedDevice: {
            const devs = Net.btKnown;
            for (var i = 0; i < devs.length; i++)
                if (devs[i].connected)
                    return devs[i];
            return null;
        }

        width: root.pillWidth
        height: 52
        radius: Theme.shapeLg
        color: on ? Theme.inverted : btMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

        Behavior on color {
            ColorAnimation {
                duration: Theme.durMedium
            }
        }

        Rectangle {
            id: btIconBg
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            radius: height / 2
            color: btPill.on ? Theme.invertedFg : Theme.surfaceHigh

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durMedium
                }
            }

            Text {
                anchors.centerIn: parent
                text: btPill.on ? "bluetooth" : "bluetooth_disabled"
                color: btPill.on ? Theme.inverted : Theme.fgDim
                font.family: Theme.fontIcons
                font.pixelSize: 18
            }
        }

        Column {
            anchors.left: btIconBg.right
            anchors.leftMargin: 9
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                width: parent.width
                text: "Bluetooth"
                color: btPill.on ? Theme.invertedFg : Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: {
                    if (!btPill.on)
                        return Cfg.t("APAGADO");
                    return btPill.connectedDevice?.name ?? Cfg.t("ENCENDIDO");
                }
                color: btPill.on ? Theme.invertedFg : Theme.fgDim
                font.letterSpacing: Theme.labelSpacing
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: btMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    root.requestPanel("bt");
                    return;
                }
                Net.toggleBt();
            }
        }
    }
}
