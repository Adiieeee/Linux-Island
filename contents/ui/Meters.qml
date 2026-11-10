import QtQuick
import "."

// medidores en filas: icono, etiqueta, barra, valor y temperatura, todo en un renglón
Column {
    id: root
    spacing: 9

    // ancho fijo para las tres filas, si cada una se calcula sola la de ram "7.8/31" descuadra
    readonly property int anchoValor: Cfg.ramUsage ? 58 : 32

    component Meter: Item {
        id: m

        property string icon: ""
        property string label: ""
        property real value: 0     // 0..1
        property color accent: Theme.primary
        property int temp: -1      // <0 = sin temperatura
        property int valorAncho: 32
        // vacío = el porcentaje de siempre
        property string valorTexto: ""

        readonly property real v: Math.max(0, Math.min(1, value))
        readonly property bool hot: temp > 80

        width: parent.width
        height: 26

        // insignia del icono
        Rectangle {
            id: badge
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: 26
            radius: height / 2
            color: "transparent"
            border.width: 1
            border.color: Theme.outline

            Text {
                anchors.centerIn: parent
                text: m.icon
                color: m.accent
                font.family: Theme.fontIcons
                font.pixelSize: 15
            }
        }

        Text {
            id: nameText
            anchors.left: badge.right
            anchors.leftMargin: 9
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            text: m.label
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: Theme.labelSmall
            font.letterSpacing: Theme.labelSpacing
        }

        // barra de progreso
        Rectangle {
            id: track
            anchors.left: nameText.right
            anchors.leftMargin: 4
            anchors.right: pct.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            height: 6
            radius: 3
            color: Theme.containerHighest

            Rectangle {
                width: Math.max(parent.radius * 2, track.width * m.v)
                height: parent.height
                radius: parent.radius
                color: m.accent

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durLong
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durMedium
                    }
                }
            }
        }

        // margen siempre igual, tenga temperatura o no (tempRow invisible igual ocupa lugar)
        Text {
            id: pct
            anchors.right: tempRow.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: m.valorAncho
            horizontalAlignment: Text.AlignRight
            text: m.valorTexto !== "" ? m.valorTexto : Math.round(m.v * 100) + "%"
            color: Theme.fg
            font.family: Theme.fontDots
            font.pixelSize: 14
            font.weight: Font.Bold
        }

        // temperatura a la derecha, para que las tres queden en columna
        Row {
            id: tempRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            width: 34
            visible: m.temp >= 0

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "local_fire_department"
                color: Theme.alert
                font.family: Theme.fontIcons
                font.pixelSize: 12
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: m.temp + "°"
                color: m.hot ? Theme.alert : Theme.fgDim
                font.family: Theme.fontDots
                font.pixelSize: 13
                font.weight: Font.Bold
            }
        }
    }

    Meter {
        icon: "memory"
        label: "CPU"
        value: SysInfo.cpu / 100
        temp: SysInfo.cpuTemp
        valorAncho: root.anchoValor
        accent: SysInfo.cpu > 85 ? Theme.error : Theme.primary
    }

    Meter {
        icon: "database"
        label: "RAM"
        value: SysInfo.mem / 100
        valorAncho: root.anchoValor
        valorTexto: Cfg.ramUsage ? SysInfo.memShort : ""
        accent: SysInfo.mem > 85 ? Theme.error : Theme.tertiary
    }

    Meter {
        icon: "developer_board"
        label: "GPU"
        value: SysInfo.gpu / 100
        temp: SysInfo.gpuAvailable ? SysInfo.gpuTemp : -1
        valorAncho: root.anchoValor
        accent: SysInfo.gpu > 85 ? Theme.error : Theme.secondary
        visible: SysInfo.gpuAvailable
    }
}
