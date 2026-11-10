import QtQuick
import org.kde.kirigami as Kirigami
import "."

// interior de la isla abierta, mismo contenido y overlays que hyprland
Item {
    id: root

    implicitWidth: Theme.expandedWidth

    // plasma dibuja el popup del tamaño que le pidamos, sale del alto real del contenido
    implicitHeight: mainColumn.implicitHeight + 14 + 12 + (root.notifying ? Theme.notifStrip : 0)

    // vista activa: "", "wifi", "bt", "rec", "audio", "notif", "cal", "power"
    property string overlay: ""

    readonly property bool notifying: Notifs.current !== null

    function openOverlay(name) {
        overlay = name;
    }
    function closeOverlay() {
        overlay = "";
    }

    Rectangle {
        id: island
        anchors.fill: parent
        radius: Theme.expandedRadius
        color: Theme.surface
        clip: true

        // ── notificación entrante ──
        // franja fija abajo, se suma al alto del panel sin tapar lo de arriba
        Item {
            id: notifView
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Theme.notifStrip

            opacity: root.notifying ? 1 : 0
            visible: opacity > 0
            z: 3

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durShort
                }
            }

            transform: Translate {
                y: root.notifying ? 0 : 10
                Behavior on y {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasizedDecel
                    }
                }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                height: 1
                color: Theme.outline
            }

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                spacing: 12

                Kirigami.Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    source: Notifs.current?.icon ?? ""
                    implicitWidth: 28
                    implicitHeight: 28
                    visible: (Notifs.current?.icon ?? "") !== ""
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 40
                    spacing: 1

                    Text {
                        width: parent.width
                        text: Notifs.current?.summary ?? ""
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.bodySmall
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: Notifs.current?.body ?? ""
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.labelSmall
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // ── panel ──
        Item {
            id: panel
            anchors.fill: parent
            anchors.margins: 14
            anchors.bottomMargin: 12 + (root.notifying ? Theme.notifStrip : 0)

            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: Theme.durMedium
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Theme.emphasized
                }
            }

            // se apaga y achica un poco cuando hay overlay encima
            // nada de layer.enabled + multieffect, revienta plasmashell (ver readme)
            Item {
                id: panelContent
                anchors.fill: parent

                opacity: root.overlay !== "" ? 0.45 : 1
                scale: root.overlay !== "" ? 0.97 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }

                Column {
                    id: mainColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: 10

                    // ── encabezado: hora grande + fecha ──
                    Item {
                        width: parent.width
                        height: 44

                        Timer {
                            id: panelClock
                            property date now: new Date()
                            interval: 1000
                            running: true
                            repeat: true
                            triggeredOnStart: true
                            onTriggered: now = new Date()
                        }

                        // hora y segundos separados, un solo Text no deja mezclar tamaños
                        // ancho fijo con dígitos en cero: en Doto no miden igual y el reloj bailaba
                        Row {
                            id: bigClock
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            TextMetrics {
                                id: moldeHora
                                font: horaTxt.font
                                text: horaTxt.text.replace(/[0-9]/g, "0")
                            }

                            Text {
                                id: horaTxt
                                anchors.bottom: parent.bottom
                                width: moldeHora.width
                                text: Qt.formatDateTime(panelClock.now, Cfg.fmtHora)
                                color: Theme.fg
                                font.family: Theme.fontDots
                                font.pixelSize: Theme.displayLarge
                                font.weight: Font.Bold
                            }

                            TextMetrics {
                                id: moldeSeg
                                font: segTxt.font
                                text: "00"
                            }

                            Text {
                                id: segTxt
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 4
                                width: moldeSeg.width
                                text: Qt.formatDateTime(panelClock.now, "ss")
                                color: Theme.fgDim
                                font.family: Theme.fontDots
                                font.pixelSize: Theme.displaySmall
                                font.weight: Font.Bold
                            }
                        }

                        // la fecha abre el calendario, mismo sistema de overlay que wifi/bt
                        Rectangle {
                            anchors.left: bigClock.right
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: fechaCol.implicitWidth + 20
                            height: 42
                            radius: Theme.shapeMd
                            color: fechaMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.durShort
                                }
                            }

                            Column {
                                id: fechaCol
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: Cfg.locale.toString(panelClock.now, "dddd, d MMMM").toUpperCase()
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.labelMedium
                                    font.letterSpacing: Theme.labelSpacing
                                }

                                Text {
                                    text: Cfg.t("CALENDARIO")
                                    color: fechaMa.containsMouse ? Theme.fgDim : Theme.fgFaint
                                    font.family: Theme.font
                                    font.pixelSize: Theme.labelSmall
                                    font.letterSpacing: Theme.labelSpacing
                                }
                            }

                            MouseArea {
                                id: fechaMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openOverlay("cal")
                            }
                        }
                    }

                    // ── red · bluetooth · sonido ──
                    StatusPills {
                        width: parent.width
                        onRequestPanel: mode => root.openOverlay(mode)
                    }

                    // ── reproductor ──
                    MediaCard {
                        width: parent.width
                    }

                    // ── grabación + medidores ──
                    Item {
                        width: parent.width
                        height: 106

                        Rectangle {
                            id: recCard
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * 0.42
                            radius: Theme.shapeLg
                            color: recMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.durShort
                                }
                            }

                            MouseArea {
                                id: recMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                // grabando: solo detiene. libre: abre la vista de config
                                onClicked: {
                                    if (Recorder.recording)
                                        Recorder.stop();
                                    else
                                        root.openOverlay("rec");
                                }
                            }

                            Rectangle {
                                id: recDot
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                height: 30
                                radius: height / 2
                                color: Recorder.recording ? "transparent" : Theme.surfaceHigh
                                border.width: 1.5
                                border.color: Recorder.recording ? Theme.alert : Theme.outline

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: Theme.durShort
                                    }
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    visible: Recorder.recording
                                    width: 11
                                    height: 11
                                    radius: 2
                                    color: Theme.alert
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !Recorder.recording
                                    text: "play_arrow"
                                    color: Theme.fg
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 18
                                }
                            }

                            Column {
                                anchors.left: recDot.right
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 0

                                Text {
                                    width: parent.width
                                    text: Cfg.t("GRABACIÓN")
                                    color: Theme.fgDim
                                    font.family: Theme.font
                                    font.pixelSize: Theme.labelSmall
                                    font.letterSpacing: Theme.labelSpacing
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: Recorder.elapsedText
                                    color: Recorder.recording ? Theme.fg : Theme.fgFaint
                                    font.family: Theme.fontDots
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Rectangle {
                            anchors.left: recCard.right
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            radius: Theme.shapeLg
                            color: Theme.containerHigh

                            Meters {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                            }
                        }
                    }

                    // ── modo café + acciones ──
                    QuickActions {
                        width: parent.width
                        onRequestNotifs: root.openOverlay("notif")
                        onRequestPower: root.openOverlay("power")
                        onRequestLauncher: root.openOverlay("apps")
                    }
                }
            }

        }

        // ── vistas superpuestas ──
        // cuelgan de la isla entera, no del recuadro interior, si no queda un borde sin oscurecer
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.overlay !== "" ? 0.55 : 0
            visible: opacity > 0
            z: 4

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durMedium
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Theme.emphasized
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.closeOverlay()
            }
        }

        Item {
            anchors.fill: parent
            anchors.margins: 14
            anchors.bottomMargin: 12 + (root.notifying ? Theme.notifStrip : 0)
            z: 5
            visible: overlayBox.opacity > 0

                Rectangle {
                    id: overlayBox
                    anchors.centerIn: parent
                    width: parent.width
                    height: Math.min(parent.height, overlayLoader.item ? overlayLoader.item.implicitHeight + 28 : parent.height)
                    radius: Theme.shapeLg
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.outline
                    clip: true

                    opacity: root.overlay !== "" ? 1 : 0
                    scale: root.overlay !== "" ? 1 : 0.94

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durShort
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Theme.emphasized
                        }
                    }
                    Behavior on scale {
                        SpringAnimation {
                            spring: 9.0
                            damping: 0.5
                            mass: 0.35
                            epsilon: 0.005
                        }
                    }
                    Behavior on height {
                        NumberAnimation {
                            duration: Theme.durMedium
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Theme.emphasized
                        }
                    }

                    Loader {
                        id: overlayLoader
                        anchors.fill: parent
                        anchors.margins: 14
                        active: root.overlay !== ""

                        sourceComponent: {
                            if (root.overlay === "rec")
                                return recComp;
                            if (root.overlay === "wifi" || root.overlay === "bt")
                                return connComp;
                            if (root.overlay === "audio")
                                return audioComp;
                            if (root.overlay === "notif")
                                return notifComp;
                            if (root.overlay === "cal")
                                return calComp;
                            if (root.overlay === "power")
                                return powerComp;
                            if (root.overlay === "apps")
                                return appsComp;
                            return null;
                        }
                    }

                    Component {
                        id: recComp
                        RecordView {
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: connComp
                        ConnPanel {
                            mode: root.overlay
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: audioComp
                        AudioPanel {
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: notifComp
                        NotifPanel {
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: calComp
                        CalendarPanel {
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: powerComp
                        PowerView {
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: appsComp
                        AppLauncher {
                            onClosed: root.closeOverlay()
                        }
                    }
                }
        }
    }
}
