import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami
import "."

// interior de la isla abierta, mismo contenido y overlays que hyprland
Item {
    id: root

    // Plasma's popup always draws the theme's dialog frame around this item
    // (translucent and blurred, as wide as the theme's margins). the island
    // reaches into that frame and leaves only Theme.popupRing of it showing,
    // and this item shrinks by the same amount so the island keeps its size.
    // the padding is read by name from the popup window: outside a Plasma
    // popup it's undefined and the reach is 0
    function reach(side) {
        const w = root.Window.window;
        const pad = w ? (w[side + "Padding"] ?? 0) : 0;
        return Math.max(0, pad - Theme.popupRing);
    }
    readonly property real reachTop: root.reach("top")
    readonly property real reachBottom: root.reach("bottom")
    readonly property real reachLeft: root.reach("left")
    readonly property real reachRight: root.reach("right")

    implicitWidth: Theme.expandedWidth - reachLeft - reachRight

    // plasma dibuja el popup del tamaño que le pidamos, sale del alto real del contenido
    // this item's height that fits the content; the island adds the reach back
    readonly property real drawnHeight: mainColumn.implicitHeight + 14 + 12 - reachTop - reachBottom

    // the island's height only changes with its content (the brightness
    // row); the SOUND/BRIGHTNESS dropdowns float over
    // the cards and don't change it. every resize of Plasma's popup window
    // costs a frame in the compositor, measured in plasmashell (see README).
    // Plasma reacts to each change of implicitHeight at once, so main.qml sets
    // the Layout heights in an order that never inverts min and max
    implicitHeight: Math.round(drawnHeight) + nudge

    // Plasma restores the size saved at the last hide (popupHeight) when it
    // creates the popup, and only enforces our min/max height when those
    // change while it's shown. if the content changed meanwhile (PowerDevil
    // late, a new version of the widget) the island came out cut off or with
    // a blank strip. a 1 px nudge right after showing makes Plasma apply the
    // real height again
    property int nudge: 0
    Timer {
        id: nudgeBack
        interval: 50
        onTriggered: root.nudge = 0
    }
    Connections {
        target: root.Window.window
        ignoreUnknownSignals: true
        function onVisibleChanged() {
            if (root.Window.window && root.Window.window.visible) {
                root.nudge = 1;
                nudgeBack.restart();
            }
        }
    }

    // vista activa: "", "wifi", "bt", "rec", "audio", "notif", "cal", "power"
    property string overlay: ""

    // something opened another window (the media card raised its player):
    // main.qml closes the popup
    signal closeRequested

    // the lyrics button in the bottom row: main.qml flips the showLyrics
    // config key (a view can't write Plasmoid.configuration through Cfg)
    signal lyricsToggled

    function openOverlay(name) {
        overlay = name;
    }
    function closeOverlay() {
        overlay = "";
    }

    // the island's outline with Theme.islandCorner corners (not a Rectangle
    // radius: a circle can't run parallel to the theme's squircle frame).
    // CurveRenderer antialiases without layer.enabled (hard rule 3)
    component IslandShape: Shape {
        id: shp
        property color fill: Theme.surface
        readonly property real t: Theme.islandCorner
        readonly property real c: Theme.islandCorner * Theme.islandCornerPull

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: shp.fill
            strokeWidth: -1
            startX: shp.t
            startY: 0

            PathLine {
                x: shp.width - shp.t
                y: 0
            }
            PathCubic {
                x: shp.width
                y: shp.t
                control1X: shp.width - shp.c
                control1Y: 0
                control2X: shp.width
                control2Y: shp.c
            }
            PathLine {
                x: shp.width
                y: shp.height - shp.t
            }
            PathCubic {
                x: shp.width - shp.t
                y: shp.height
                control1X: shp.width
                control1Y: shp.height - shp.c
                control2X: shp.width - shp.c
                control2Y: shp.height
            }
            PathLine {
                x: shp.t
                y: shp.height
            }
            PathCubic {
                x: 0
                y: shp.height - shp.t
                control1X: shp.c
                control1Y: shp.height
                control2X: 0
                control2Y: shp.height - shp.c
            }
            PathLine {
                x: 0
                y: shp.t
            }
            PathCubic {
                x: shp.t
                y: 0
                control1X: 0
                control1Y: shp.c
                control2X: shp.c
                control2Y: 0
            }
        }
    }

    Item {
        id: island
        // fills the window and reaches into Plasma's frame (see reach())
        anchors.fill: parent
        anchors.topMargin: -root.reachTop
        anchors.bottomMargin: -root.reachBottom
        anchors.leftMargin: -root.reachLeft
        anchors.rightMargin: -root.reachRight
        clip: true

        IslandShape {
            z: -1
        }

        // ── panel ──
        Item {
            id: panel
            anchors.fill: parent
            anchors.margins: 14
            anchors.bottomMargin: 12

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
                        // fixed width from an all-zeros template: tnum makes digits equal in fonts
                        // that support it, this covers user-picked fonts that don't
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
                                font.features: Theme.numFeatures
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
                                font.features: Theme.numFeatures
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
                                    color: fechaMa.containsMouse ? Theme.fg : Theme.fgDim
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

                    // ── red · bluetooth ──
                    StatusPills {
                        width: parent.width
                        onRequestPanel: mode => root.openOverlay(mode)
                    }

                    // ── sound (and brightness): full-width sliders ──
                    SliderCard {
                        id: sliderCard
                        width: parent.width
                        // down to the island's bottom margin (above the notification
                        // strip), from this card's top
                        dropRoom: panel.height - sliderCard.y
                        onRequestPanel: mode => root.openOverlay(mode)
                    }

                    // ── reproductor ──
                    MediaCard {
                        width: parent.width
                        onRaised: root.closeRequested()
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
                                // the card opens the recording view (status and stop
                                // while recording); the round button starts/stops directly
                                onClicked: root.openOverlay("rec")
                            }

                            Rectangle {
                                id: recDot
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                height: 30
                                radius: height / 2
                                // a step above surfaceHigh on hover, or it vanishes when
                                // the whole card hovers to surfaceHigh
                                color: Recorder.recording ? "transparent" : recBtnMa.containsMouse ? Theme.surfaceTop : Theme.surfaceHigh
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

                                // above the card's MouseArea, so the button doesn't open the view
                                MouseArea {
                                    id: recBtnMa
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Recorder.toggle()
                                }
                            }

                            Column {
                                anchors.left: recDot.right
                                anchors.leftMargin: 10
                                anchors.right: recInfo.left
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
                                    font.features: Theme.numFeatures
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }
                            }

                            // current settings at a glance, top to bottom on the card's
                            // right: screen or window, system audio, microphone.
                            // on = dim, off = faint + the crossed-out glyph
                            Column {
                                id: recInfo
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Text {
                                    text: Recorder.mode === "w" ? "select_window" : "desktop_windows"
                                    color: Theme.fgDim
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 15
                                }

                                Text {
                                    text: Recorder.systemAudio ? "volume_up" : "volume_off"
                                    color: Recorder.systemAudio ? Theme.fgDim : Theme.fgFaint
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 15
                                }

                                Text {
                                    text: Recorder.microphone ? "mic" : "mic_off"
                                    color: Recorder.microphone ? Theme.fgDim : Theme.fgFaint
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 15
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
                        onLyricsToggled: root.lyricsToggled()
                    }
                }
            }

        }

        // ── vistas superpuestas ──
        // cuelgan de la isla entera, no del recuadro interior, si no queda un borde sin oscurecer
        // same outline as the island, or its corners would darken Plasma's frame
        IslandShape {
            fill: "#000000"
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
            anchors.bottomMargin: 12
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
                }
        }
    }
}
