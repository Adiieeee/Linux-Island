import QtQuick
import org.kde.plasma.plasma5support as P5Support
import "."

// panel de apagado: sesión, suspender, hibernar, reiniciar, apagar, bloquear
// todo por dbus a plasma, no systemctl a mano: cierra sesión ordenado, avisa a las apps
// reiniciar/apagar piden confirmar en la misma fila, un clic de más no tira la máquina
Item {
    id: popup

    signal closed

    // pasado esto se arrastra en vez de seguir estirando la isla
    readonly property int listaMax: 344

    implicitHeight: col.implicitHeight + 30

    // fila pidiendo confirmación, "" = ninguna
    property string confirmando: ""

    // solo se muestran si el equipo puede
    property bool puedeSuspender: false
    property bool puedeHibernar: false

    readonly property string cmdPuede: 'busctl --user --json=short call org.freedesktop.PowerManagement /org/freedesktop/PowerManagement org.freedesktop.PowerManagement CanSuspend; echo ---; busctl --user --json=short call org.freedesktop.PowerManagement /org/freedesktop/PowerManagement org.freedesktop.PowerManagement CanHibernate'

    Component.onCompleted: popup.consulta.connectSource(popup.cmdPuede)

    // datasource propio, tipado (no property var, se lo lleva puesto el gc de js)
    readonly property P5Support.DataSource consulta: P5Support.DataSource {
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            const partes = String(data["stdout"] ?? "").split("---");
            popup.puedeSuspender = partes.length > 0 && partes[0].indexOf("true") >= 0;
            popup.puedeHibernar = partes.length > 1 && partes[1].indexOf("true") >= 0;
        }
    }

    function correr(cmd) {
        Exec.run(cmd);
        popup.closed();
    }

    Item {
        id: card
        anchors.fill: parent

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 10

            // ── barra de título ──
            Item {
                width: parent.width
                height: 26

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Cfg.t("APAGADO_PANEL")
                    color: Theme.fgFaint
                    font.family: Theme.font
                    font.pixelSize: Theme.labelSmall
                    font.letterSpacing: Theme.labelSpacing
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 26
                    radius: height / 2
                    color: closeMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durShort
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        color: closeMa.containsMouse ? Theme.fg : Theme.fgDim
                        font.family: Theme.fontIcons
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.closed()
                    }
                }
            }

            // ── fila reutilizable ──
            component Opcion: Rectangle {
                id: op
                property string icono: ""
                property string titulo: ""
                property string detalle: ""
                property string comando: ""
                // pide confirmar antes de hacerse
                property bool pesada: false

                readonly property bool preguntando: popup.confirmando === op.titulo

                width: lista.width
                height: preguntando ? 78 : 44
                radius: Theme.shapeMd
                color: opMa.containsMouse || op.preguntando ? Theme.surfaceHigh : Theme.surfaceAlt

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }

                Item {
                    id: fila
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 44

                    Text {
                        id: opIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: op.icono
                        color: op.pesada ? Theme.alert : Theme.fg
                        font.family: Theme.fontIcons
                        font.pixelSize: 20
                    }

                    Column {
                        anchors.left: opIcon.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Text {
                            width: parent.width
                            text: op.titulo
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.bodySmall
                            font.weight: Font.Medium
                            font.letterSpacing: Theme.labelSpacing
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: op.detalle !== ""
                            text: op.detalle
                            color: Theme.fgVariant
                            font.family: Theme.font
                            font.pixelSize: Theme.labelSmall
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: opMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!op.pesada) {
                                popup.correr(op.comando);
                                return;
                            }
                            popup.confirmando = op.preguntando ? "" : op.titulo;
                        }
                    }
                }

                // ── confirmación ──
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 46
                    anchors.top: fila.bottom
                    anchors.topMargin: 2
                    spacing: 6
                    visible: op.preguntando

                    Rectangle {
                        width: siTxt.implicitWidth + 24
                        height: 28
                        radius: height / 2
                        color: siMa.containsMouse ? Qt.lighter(Theme.alert, 1.15) : Theme.alert

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durShort
                            }
                        }

                        Text {
                            id: siTxt
                            anchors.centerIn: parent
                            text: Cfg.t("SÍ")
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.labelSmall
                            font.weight: Font.Medium
                            font.letterSpacing: Theme.labelSpacing
                        }

                        MouseArea {
                            id: siMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.correr(op.comando)
                        }
                    }

                    Rectangle {
                        width: noTxt.implicitWidth + 24
                        height: 28
                        radius: height / 2
                        color: noMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)
                        border.width: 1
                        border.color: Theme.outline

                        Text {
                            id: noTxt
                            anchors.centerIn: parent
                            text: Cfg.t("MEJOR NO")
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.labelSmall
                            font.weight: Font.Medium
                            font.letterSpacing: Theme.labelSpacing
                        }

                        MouseArea {
                            id: noMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.confirmando = ""
                        }
                    }
                }
            }

            // ── lista ──
            // tope de alto + arrastre, si no con la isla corta la última opción quedaba a medias
            Item {
                width: parent.width
                height: Math.min(popup.listaMax, lista.contentHeight)

                Flickable {
                    id: lista
                    anchors.fill: parent
                    contentHeight: dentro.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 3500

                    Column {
                        id: dentro
                        width: lista.width
                        spacing: 6

            Opcion {
                icono: "lock"
                titulo: Cfg.t("BLOQUEAR")
                detalle: Cfg.t("Pide la contraseña al volver")
                comando: "busctl --user call org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver Lock"
            }

            Opcion {
                icono: "logout"
                titulo: Cfg.t("CERRAR SESIÓN")
                detalle: Cfg.t("Cierra los programas abiertos")
                comando: "busctl --user call org.kde.Shutdown /Shutdown org.kde.Shutdown logout"
                pesada: true
            }

            Opcion {
                icono: "bedtime"
                titulo: Cfg.t("SUSPENDER")
                detalle: Cfg.t("Se apaga la pantalla, todo queda como está")
                comando: "busctl --user call org.freedesktop.PowerManagement /org/freedesktop/PowerManagement org.freedesktop.PowerManagement Suspend"
                visible: popup.puedeSuspender
            }

            Opcion {
                icono: "downloading"
                titulo: Cfg.t("HIBERNAR")
                detalle: Cfg.t("Guarda todo en el disco y apaga")
                comando: "busctl --user call org.freedesktop.PowerManagement /org/freedesktop/PowerManagement org.freedesktop.PowerManagement Hibernate"
                visible: popup.puedeHibernar
                pesada: true
            }

            Opcion {
                icono: "restart_alt"
                titulo: Cfg.t("REINICIAR")
                detalle: Cfg.t("Apaga y vuelve a arrancar")
                comando: "busctl --user call org.kde.Shutdown /Shutdown org.kde.Shutdown logoutAndReboot"
                pesada: true
            }

            Opcion {
                icono: "power_settings_new"
                titulo: Cfg.t("APAGAR")
                detalle: Cfg.t("Apaga el equipo")
                comando: "busctl --user call org.kde.Shutdown /Shutdown org.kde.Shutdown logoutAndShutdown"
                pesada: true
            }
                    }
                }

                // barrita de scroll, igual que en los otros paneles
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    width: 3
                    radius: 1.5
                    color: Theme.fgFaint

                    visible: lista.contentHeight > lista.height
                    height: Math.max(24, lista.height * (lista.height / lista.contentHeight))
                    y: (lista.contentHeight <= lista.height) ? 0 : (lista.contentY / (lista.contentHeight - lista.height)) * (lista.height - height)

                    opacity: lista.moving ? 0.9 : 0.25

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durMedium
                        }
                    }
                }
            }
        }
    }
}
