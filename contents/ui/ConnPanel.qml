import QtQuick
import "."

// panel de red / bluetooth: interruptor arriba, lista arrastrable abajo
// tres secciones: conectado, conocido (guardado o emparejado), cerca
Item {
    id: popup

    // "wifi" o "bt"
    property string mode: "wifi"
    property bool visible_: true

    signal closed

    implicitHeight: col.implicitHeight + 44

    readonly property bool enabled: mode === "wifi" ? Net.wifiEnabled : Net.btEnabled

    // pasado esto se arrastra en vez de seguir estirando la isla
    readonly property int listMax: 250

    // ── las tres listas ──
    readonly property var connectedList: mode === "wifi" ? Net.nearbyNets.filter(n => n.connected) : Net.btKnown.filter(d => d.connected)

    readonly property var known: {
        if (mode === "wifi") {
            const puestas = {};
            for (const n of popup.connectedList)
                puestas[n.name] = true;
            return Net.savedNets.filter(n => !puestas[n.name]);
        }
        return Net.btKnown.filter(d => !d.connected);
    }

    readonly property var nearby: {
        if (mode === "wifi") {
            const guardadas = {};
            for (const n of Net.savedNets)
                guardadas[n.name] = true;
            return Net.nearbyNets.filter(n => !n.connected && !guardadas[n.name]);
        }
        return Net.btNearby;
    }

    // red protegida esperando contraseña
    property string asking: ""

    // fila abierta con clic derecho, una sola a la vez
    property string detail: ""

    function toggle(): void {
        if (mode === "wifi")
            Net.toggleWifi();
        else
            Net.toggleBt();
    }

    // mientras el panel está abierto, Net pide las listas largas
    Component.onCompleted: {
        if (popup.mode === "bt") {
            Net.btWatchers++;
            Net.scanBt(true);
        } else {
            Net.netWatchers++;
        }
        Net.refreshLists();
    }

    Component.onDestruction: {
        if (popup.mode === "bt")
            Net.btWatchers--;
        else
            Net.netWatchers--;
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
            // la x en su propia fila, si no se confunde con la tarjeta de abajo
            Item {
                width: parent.width
                height: 26

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: popup.mode === "wifi" ? Cfg.t("RED") : Cfg.t("DISPOSITIVOS")
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

            // ── encabezado con interruptor ──
            Rectangle {
                width: parent.width
                height: 46
                radius: Theme.shapeLg
                color: popup.enabled ? Theme.inverted : Theme.surfaceAlt

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durMedium
                    }
                }

                Text {
                    id: hIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: popup.mode === "wifi" ? (popup.enabled ? "wifi" : "wifi_off") : (popup.enabled ? "bluetooth" : "bluetooth_disabled")
                    color: popup.enabled ? Theme.invertedFg : Theme.fgDim
                    font.family: Theme.fontIcons
                    font.pixelSize: 20
                }

                Text {
                    anchors.left: hIcon.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: popup.mode === "wifi" ? "WI-FI" : "BLUETOOTH"
                    color: popup.enabled ? Theme.invertedFg : Theme.fg
                    font.letterSpacing: Theme.labelSpacing
                    font.family: Theme.font
                    font.pixelSize: Theme.bodyMedium
                    font.weight: Font.Medium
                }

                // interruptor m3
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 24
                    radius: height / 2
                    color: popup.enabled ? Theme.invertedFg : Theme.surfaceHigh
                    border.width: popup.enabled ? 0 : 2
                    border.color: Theme.outline

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durMedium
                        }
                    }

                    Rectangle {
                        width: popup.enabled ? 18 : 14
                        height: width
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: popup.enabled ? parent.width - width - 3 : 4
                        color: popup.enabled ? Theme.inverted : Theme.fgFaint

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
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.toggle()
                }
            }

            // ── botón chico del detalle ──
            component AccionBtn: Rectangle {
                id: ab
                property string etiqueta: ""
                // relleno = acción principal, delineado = la otra
                property bool fuerte: false
                property bool peligro: false
                signal apretado

                width: abTxt.implicitWidth + 22
                height: 28
                radius: height / 2

                color: ab.fuerte ? (abMa.containsMouse ? Qt.lighter(Theme.inverted, 1.1) : Theme.inverted) : abMa.containsMouse ? Qt.alpha(ab.peligro ? Theme.alert : Theme.fg, Theme.stateHover) : "transparent"
                border.width: ab.fuerte ? 0 : 1
                border.color: ab.peligro ? Theme.alert : Theme.outline

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }

                Text {
                    id: abTxt
                    anchors.centerIn: parent
                    text: ab.etiqueta
                    color: ab.fuerte ? Theme.invertedFg : ab.peligro ? Theme.alert : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.labelSmall
                    font.weight: Font.Medium
                    font.letterSpacing: Theme.labelSpacing
                }

                MouseArea {
                    id: abMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ab.apretado()
                }
            }

            // ── fila reutilizable ──
            component ConnRow: Rectangle {
                id: cr
                property var item: null
                property bool isKnown: false

                // nombre para redes, mac para dispositivos
                readonly property string ident: popup.mode === "wifi" ? (item?.name ?? "") : (item?.mac ?? "")

                readonly property bool isConnected: item?.connected ?? false
                readonly property bool isBusy: ident !== "" && Net.connecting === ident
                readonly property bool didFail: ident !== "" && Net.failed === ident
                readonly property bool askingPass: popup.asking !== "" && popup.asking === ident

                // fila desplegada con clic derecho
                readonly property bool abierto: popup.detail !== "" && popup.detail === ident

                readonly property string detalleTexto: {
                    if (popup.mode !== "wifi")
                        return cr.item?.mac ?? "";
                    const partes = [];
                    if (cr.item?.signal !== undefined)
                        partes.push(Cfg.t("Señal") + " " + cr.item.signal + "%");
                    if (cr.item?.secure !== undefined)
                        partes.push(cr.item.secure ? Cfg.t("Protegida") : Cfg.t("Abierta"));
                    return partes.join(" · ");
                }

                function conectar(): void {
                    const it = cr.item;
                    if (!it)
                        return;

                    if (popup.mode === "wifi") {
                        if (cr.isKnown) {
                            Net.connectNet(it.name);
                            return;
                        }
                        // red nueva protegida, pide contraseña primero
                        if (it.secure) {
                            popup.asking = cr.askingPass ? "" : cr.ident;
                            return;
                        }
                        Net.joinNet(it.name, "");
                        return;
                    }

                    if (cr.isKnown)
                        Net.connectBt(it.mac);
                    else
                        Net.pairBt(it.mac);
                }

                function desconectar(): void {
                    if (!cr.item)
                        return;
                    if (popup.mode === "wifi")
                        Net.disconnectNet(cr.item.name);
                    else
                        Net.disconnectBt(cr.item.mac);
                }

                function olvidar(): void {
                    if (!cr.item)
                        return;
                    if (popup.mode === "wifi")
                        Net.forgetNet(cr.item.name);
                    else
                        Net.forgetBt(cr.item.mac);
                    popup.detail = "";
                }

                width: lista.width
                height: askingPass ? 90 : abierto ? 44 + detalle.implicitHeight + 8 : 44
                radius: Theme.shapeMd
                color: crMa.containsMouse || cr.isBusy || cr.askingPass || cr.abierto ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)

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

                    // icono normal de la fila
                    Text {
                        id: crIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !cr.isBusy
                        text: {
                            if (popup.mode === "wifi")
                                return cr.isConnected ? "wifi" : (cr.item?.secure ?? false) ? "lock" : "wifi_find";
                            const n = (cr.item?.name ?? "").toLowerCase();
                            if (n.includes("head") || n.includes("buds") || n.includes("audio"))
                                return "headphones";
                            if (n.includes("phone"))
                                return "call";
                            if (n.includes("keyboard") || n.includes("teclado"))
                                return "keyboard";
                            if (n.includes("mouse"))
                                return "mouse";
                            return "bluetooth";
                        }
                        color: cr.didFail ? Theme.alert : cr.isConnected ? Theme.fg : Theme.fgFaint
                        font.family: Theme.fontIcons
                        font.pixelSize: 18
                    }

                    // spinner aparte del icono, si no queda torcido al frenar
                    Item {
                        id: spinner
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        visible: cr.isBusy

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.width: 2
                            border.color: Theme.outline
                        }

                        Item {
                            anchors.fill: parent

                            RotationAnimator on rotation {
                                running: spinner.visible
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 1100
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 0
                                width: 6
                                height: 6
                                radius: 3
                                color: Theme.fg
                            }
                        }
                    }

                    Column {
                        anchors.left: crIcon.right
                        anchors.leftMargin: 10
                        anchors.right: crAction.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Text {
                            width: parent.width
                            text: cr.item?.name || Cfg.t("Desconocido")
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.bodySmall
                            font.weight: cr.isConnected ? Font.Medium : Font.Normal
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: {
                                if (cr.isBusy)
                                    return popup.mode === "wifi" || cr.isKnown ? Cfg.t("Conectando…") : Cfg.t("Emparejando…");
                                if (cr.askingPass)
                                    return Cfg.t("Escribí la contraseña");
                                if (cr.didFail)
                                    return Cfg.t("No se pudo conectar");
                                if (cr.isConnected)
                                    return Cfg.t("Conectado");
                                if (cr.isKnown)
                                    return Cfg.t("Guardado");
                                return Cfg.t("Disponible");
                            }
                            color: cr.didFail ? Theme.alert : Theme.fgVariant
                            font.family: Theme.font
                            font.pixelSize: Theme.labelSmall
                            elide: Text.ElideRight
                        }
                    }

                    // flechita, avisa que la fila se abre (clic derecho hace lo mismo)
                    Text {
                        id: crAction
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "expand_more"
                        color: cr.abierto || detMa.containsMouse ? Theme.fg : Theme.outline
                        font.family: Theme.fontIcons
                        font.pixelSize: 18

                        rotation: cr.abierto ? 180 : 0

                        Behavior on rotation {
                            NumberAnimation {
                                duration: Theme.durMedium
                                easing.type: Easing.Bezier
                                easing.bezierCurve: Theme.emphasized
                            }
                        }

                        MouseArea {
                            id: detMa
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.detail = cr.abierto ? "" : cr.ident
                        }
                    }

                    MouseArea {
                        id: crMa
                        anchors.fill: parent
                        anchors.rightMargin: 30
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !cr.isBusy
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                popup.detail = cr.abierto ? "" : cr.ident;
                                return;
                            }
                            if (cr.isConnected)
                                cr.desconectar();
                            else
                                cr.conectar();
                        }
                    }
                }

                // ── detalle ──
                // olvidar solo aparece en lo ya guardado/emparejado
                Column {
                    id: detalle
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: fila.bottom
                    anchors.leftMargin: 40
                    anchors.rightMargin: 10
                    spacing: 8
                    visible: cr.abierto && !cr.askingPass
                    opacity: visible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durShort
                        }
                    }

                    Text {
                        width: parent.width
                        visible: cr.detalleTexto !== ""
                        text: cr.detalleTexto
                        color: Theme.fgVariant
                        font.family: Theme.font
                        font.pixelSize: Theme.labelSmall
                        elide: Text.ElideRight
                    }

                    Row {
                        spacing: 6

                        AccionBtn {
                            etiqueta: Cfg.t("CONECTAR")
                            fuerte: true
                            visible: !cr.isConnected
                            onApretado: cr.conectar()
                        }

                        AccionBtn {
                            etiqueta: Cfg.t("DESCONECTAR")
                            fuerte: true
                            visible: cr.isConnected
                            onApretado: cr.desconectar()
                        }

                        AccionBtn {
                            etiqueta: Cfg.t("OLVIDAR")
                            peligro: true
                            visible: cr.isKnown
                            onApretado: cr.olvidar()
                        }
                    }
                }

                // ── contraseña ──
                // solo para redes protegidas sin guardar, se escribe acá mismo
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: fila.bottom
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 2
                    height: 36
                    radius: Theme.shapeSm
                    color: Theme.surfaceAlt
                    visible: cr.askingPass
                    clip: true

                    // el foco va acá, el visible del hijo no cambia cuando se esconde el padre
                    onVisibleChanged: if (visible) {
                        passIn.text = "";
                        passIn.forceActiveFocus();
                    }

                    TextInput {
                        id: passIn
                        anchors.left: parent.left
                        anchors.right: okBtn.left
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.bodySmall
                        echoMode: TextInput.Password
                        selectByMouse: true
                        selectionColor: Qt.alpha(Theme.fg, 0.25)
                        clip: true

                        onAccepted: okBtn.entrar()

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: passIn.text === ""
                            text: Cfg.t("Contraseña")
                            color: Theme.fgFaint
                            font.family: Theme.font
                            font.pixelSize: Theme.bodySmall
                        }
                    }

                    Rectangle {
                        id: okBtn
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: height / 2
                        color: okMa.containsMouse ? Theme.inverted : "transparent"

                        function entrar() {
                            if (passIn.text === "")
                                return;
                            Net.joinNet(cr.item.name, passIn.text);
                            popup.asking = "";
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durShort
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "arrow_forward"
                            color: okMa.containsMouse ? Theme.invertedFg : Theme.fgDim
                            font.family: Theme.fontIcons
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: okMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: okBtn.entrar()
                        }
                    }
                }
            }

            component SectionLabel: Text {
                color: Theme.outline
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                font.weight: Font.Medium
                font.letterSpacing: 0.6
            }

            // ── lista ──
            // todo esto adentro de un Flickable para poder arrastrar con muchas redes
            Item {
                width: parent.width
                height: Math.min(popup.listMax, lista.contentHeight)
                visible: popup.enabled

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
                        spacing: 10

                        // ── conectados ──
                        SectionLabel {
                            text: popup.mode === "wifi" ? Cfg.t("CONECTADO") : Cfg.t("CONECTADOS")
                            visible: popup.connectedList.length > 0
                        }

                        Column {
                            width: parent.width
                            spacing: 2
                            visible: popup.connectedList.length > 0

                            Repeater {
                                model: popup.connectedList

                                ConnRow {
                                    required property var modelData
                                    item: modelData
                                    isKnown: true
                                }
                            }
                        }

                        // ── conocidos ──
                        SectionLabel {
                            text: popup.mode === "wifi" ? Cfg.t("REDES GUARDADAS") : Cfg.t("DISPOSITIVOS CONOCIDOS")
                            visible: popup.known.length > 0
                        }

                        Column {
                            width: parent.width
                            spacing: 2
                            visible: popup.known.length > 0

                            Repeater {
                                model: popup.known

                                ConnRow {
                                    required property var modelData
                                    item: modelData
                                    isKnown: true
                                }
                            }
                        }

                        // ── cerca ──
                        SectionLabel {
                            text: popup.mode === "wifi" ? Cfg.t("REDES CERCANAS") : Cfg.t("DISPOSITIVOS CERCANOS")
                        }

                        Column {
                            width: parent.width
                            spacing: 2

                            Repeater {
                                model: popup.nearby

                                ConnRow {
                                    required property var modelData
                                    item: modelData
                                    isKnown: false
                                }
                            }

                            Text {
                                width: parent.width
                                visible: popup.nearby.length === 0
                                horizontalAlignment: Text.AlignHCenter
                                topPadding: 8
                                bottomPadding: 8
                                text: Cfg.t("Buscando…")
                                color: Theme.outline
                                font.family: Theme.font
                                font.pixelSize: Theme.bodySmall
                            }
                        }
                    }
                }

                // barrita de scroll, aparece sola si hay más lista de la que entra
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

            Text {
                width: parent.width
                visible: !popup.enabled
                horizontalAlignment: Text.AlignHCenter
                topPadding: 10
                bottomPadding: 10
                text: popup.mode === "wifi" ? Cfg.t("Wi-Fi apagado") : Cfg.t("Bluetooth apagado")
                color: Theme.outline
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
            }
        }
    }
}
