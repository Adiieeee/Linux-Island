import QtQuick
import Qt.labs.platform as Platform
import "."

// vista de config de grabación, reemplaza el contenido de la isla mientras está abierta
Item {
    id: root

    signal closed

    readonly property string home: Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation).toString().replace("file://", "")

    // el contenedor de la isla usa esto para dimensionar el popup
    implicitHeight: col.implicitHeight

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 14

        // ── encabezado ──
        Item {
            width: parent.width
            height: 40

            Rectangle {
                id: statusDot
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: 6
                width: 10
                height: 10
                radius: 5
                color: Recorder.recording ? Theme.alert : "transparent"
                border.width: Recorder.recording ? 0 : 1.5
                border.color: Theme.fgFaint

                // latido mientras graba
                SequentialAnimation on opacity {
                    running: Recorder.recording
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) statusDot.opacity = 1
                    NumberAnimation {
                        to: 0.35
                        duration: 700
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        to: 1
                        duration: 700
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Column {
                anchors.left: statusDot.right
                anchors.leftMargin: 12
                anchors.top: parent.top
                spacing: 1

                Text {
                    text: Cfg.t("GRABACIÓN DE PANTALLA")
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.titleSmall
                    font.weight: Font.Bold
                    font.letterSpacing: Theme.labelSpacing
                }

                Text {
                    text: Recorder.recording ? Cfg.t("Grabando") + " · " + Recorder.elapsedText : Cfg.t("Listo para grabar")
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.bodySmall
                }
            }

            // cerrar
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                width: 30
                height: 30
                radius: height / 2
                color: closeMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)

                Text {
                    anchors.centerIn: parent
                    text: "close"
                    color: Theme.fgDim
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                }

                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closed()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.outline
        }

        // píldora seleccionable reutilizable
        component ChoicePill: Rectangle {
            id: cp
            property string label: ""
            property bool active: false
            signal picked

            width: cpText.implicitWidth + 26
            height: 30
            radius: height / 2
            color: active ? Theme.inverted : cpMa.containsMouse ? Theme.surfaceHigh : "transparent"
            border.width: active ? 0 : 1
            border.color: Theme.outline

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durShort
                }
            }

            Text {
                id: cpText
                anchors.centerIn: parent
                text: cp.label
                color: cp.active ? Theme.invertedFg : Theme.fgDim
                font.family: Theme.fontDots
                font.pixelSize: 13
                font.weight: Font.Bold
            }

            MouseArea {
                id: cpMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !Recorder.recording
                onClicked: cp.picked()
            }
        }

        // ── fps ──
        // oculto: spectacle no deja elegir fps, esto escribía en una propiedad que ya no existe
        Item {
            visible: false
            width: parent.width
            height: 0

            Text {
                id: fpsLabel
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 66
                text: "FPS"
                color: Theme.fgFaint
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                font.letterSpacing: Theme.labelSpacing
            }

            Row {
                anchors.left: fpsLabel.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Repeater {
                    model: [30, 60, 120]

                    ChoicePill {
                        required property var modelData
                        label: String(modelData)
                        active: false
                        onPicked: {}
                    }
                }
            }
        }

        // ── carpeta ──
        Item {
            width: parent.width
            height: 30

            Text {
                id: dirLabel
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 66
                text: Cfg.t("CARPETA")
                color: Theme.fgFaint
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                font.letterSpacing: Theme.labelSpacing
            }

            Row {
                anchors.left: dirLabel.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Repeater {
                    model: ["Videos", "Pictures", "Desktop", ""]

                    ChoicePill {
                        required property var modelData
                        readonly property string path: root.home + (modelData !== "" ? "/" + modelData : "")
                        label: modelData !== "" ? "~/" + modelData : "~/"
                        active: Recorder.folder === path
                        onPicked: Recorder.folder = path
                    }
                }
            }
        }

        // interruptor con etiqueta
        component ToggleRow: Rectangle {
            id: tr
            property string icon: ""
            property string label: ""
            property bool checked: false
            signal toggled

            width: parent.width
            height: 44
            radius: Theme.shapeMd
            color: trMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durShort
                }
            }

            Text {
                id: trIcon
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: tr.icon
                color: tr.checked ? Theme.fg : Theme.fgFaint
                font.family: Theme.fontIcons
                font.pixelSize: 18
            }

            Text {
                anchors.left: trIcon.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: tr.label
                color: tr.checked ? Theme.fg : Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.bodyMedium
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 24
                radius: height / 2
                color: tr.checked ? Theme.inverted : Theme.surfaceHigh
                border.width: tr.checked ? 0 : 1
                border.color: Theme.outline

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durMedium
                    }
                }

                Rectangle {
                    width: tr.checked ? 18 : 14
                    height: width
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    x: tr.checked ? parent.width - width - 3 : 4
                    color: tr.checked ? Theme.invertedFg : Theme.fgFaint

                    Behavior on x {
                        NumberAnimation {
                            duration: Theme.durMedium
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Theme.emphasized
                        }
                    }
                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.durShort
                        }
                    }
                }
            }

            MouseArea {
                id: trMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !Recorder.recording
                onClicked: tr.toggled()
            }
        }

        ToggleRow {
            icon: "volume_up"
            label: Cfg.t("Audio del sistema")
            checked: Recorder.systemAudio
            onToggled: Recorder.systemAudio = !Recorder.systemAudio
        }

        ToggleRow {
            icon: "mic"
            label: Cfg.t("Micrófono")
            checked: Recorder.microphone
            onToggled: Recorder.microphone = !Recorder.microphone
        }

        // ── acción principal ──
        Rectangle {
            width: parent.width
            height: 46
            radius: Theme.shapeMd
            color: Recorder.recording ? Theme.alert : startMa.containsMouse ? Qt.rgba(Theme.alert.r, Theme.alert.g, Theme.alert.b, 0.32) : Qt.rgba(Theme.alert.r, Theme.alert.g, Theme.alert.b, 0.20)
            border.width: 1
            border.color: Qt.rgba(Theme.alert.r, Theme.alert.g, Theme.alert.b, 0.55)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durShort
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 10

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 12
                    radius: Recorder.recording ? 2 : 6
                    color: Recorder.recording ? Theme.fg : Theme.alert

                    Behavior on radius {
                        NumberAnimation {
                            duration: Theme.durShort
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Recorder.recording ? Cfg.t("Detener grabación") : Cfg.t("Empezar a grabar")
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.bodyMedium
                    font.weight: Font.Medium
                }
            }

            MouseArea {
                id: startMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Recorder.toggle()
            }
        }

        // ── abrir carpeta ──
        Rectangle {
            width: parent.width
            height: 42
            radius: Theme.shapeMd
            color: openMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durShort
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "folder_open"
                    color: Theme.fgDim
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Cfg.t("Abrir carpeta de grabaciones")
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.bodyMedium
                }
            }

            MouseArea {
                id: openMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Recorder.openFolder()
            }
        }

        Text {
            text: Cfg.t("Se guarda en") + " " + Recorder.folder.replace(root.home, "~")
            color: Theme.fgFaint
            font.family: Theme.font
            font.pixelSize: Theme.labelSmall
        }
    }
}
