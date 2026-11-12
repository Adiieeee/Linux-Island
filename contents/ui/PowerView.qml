import QtQuick
import org.kde.plasma.private.sessions as Sessions
import "."

// power panel: sleep, log out, hibernate, restart, shut down. everything goes
// through Plasma's SessionManagement, the same API as KDE's own menus, not
// systemctl: the session closes in order and apps get to save. log out,
// restart and shut down show KDE's own confirmation screen, with its
// countdown and Cancel (ConfirmationMode.Default follows System Settings'
// "Ask for confirmation"); sleep and hibernate run at once, as in KDE
Item {
    id: popup

    signal closed

    // pasado esto se arrastra en vez de seguir estirando la isla
    readonly property int listaMax: 344

    implicitHeight: col.implicitHeight + 30

    // typed, not var (hard rule 1). its canSuspend / canHibernate decide
    // which rows show, and follow the machine live
    readonly property Sessions.SessionManagement session: Sessions.SessionManagement {}

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
                    // fgDim like the Wi-Fi and Bluetooth panels' title;
                    // fgFaint was too dark
                    color: Theme.fgDim
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
                // ends the session or powers off: red icon
                property bool pesada: false

                // the row was clicked; each row's handler does its action
                signal triggered

                width: lista.width
                height: 44
                radius: Theme.shapeMd
                color: opMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
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
                            // 13 px, like the WI-FI / BLUETOOTH header
                            font.pixelSize: Theme.bodyMedium
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
                        onClicked: op.triggered()
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
                icono: "bedtime"
                titulo: Cfg.t("SUSPENDER")
                detalle: Cfg.t("Se apaga la pantalla, todo queda como está")
                visible: popup.session.canSuspend
                onTriggered: {
                    popup.session.suspend();
                    popup.closed();
                }
            }

            Opcion {
                icono: "logout"
                titulo: Cfg.t("CERRAR SESIÓN")
                detalle: Cfg.t("Cierra los programas abiertos")
                pesada: true
                onTriggered: {
                    popup.session.requestLogout(Sessions.SessionManagement.Default);
                    popup.closed();
                }
            }

            Opcion {
                icono: "downloading"
                titulo: Cfg.t("HIBERNAR")
                detalle: Cfg.t("Guarda todo en el disco y apaga")
                visible: popup.session.canHibernate
                pesada: true
                onTriggered: {
                    popup.session.hibernate();
                    popup.closed();
                }
            }

            Opcion {
                icono: "restart_alt"
                titulo: Cfg.t("REINICIAR")
                detalle: Cfg.t("Apaga y vuelve a arrancar")
                pesada: true
                onTriggered: {
                    popup.session.requestReboot(Sessions.SessionManagement.Default);
                    popup.closed();
                }
            }

            Opcion {
                icono: "power_settings_new"
                titulo: Cfg.t("APAGAR")
                detalle: Cfg.t("Apaga el equipo")
                pesada: true
                onTriggered: {
                    popup.session.requestShutdown(Sessions.SessionManagement.Default);
                    popup.closed();
                }
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
