import QtQuick
import "."

// fila inferior: modo café + accesos rápidos
Row {
    id: root
    spacing: 8

    property bool coffee: false

    // la isla escucha esto para abrir notificaciones
    signal requestNotifs

    // …y esto para el panel de apagado
    signal requestPower

    // …y esto para el lanzador de apps
    signal requestLauncher

    // powerdevil ata la inhibición a la conexión de quien la pidió, un qdbus suelto no dura nada
    // por eso lo hace coffee.py, que se queda vivo. encender = lanzarlo, apagar = matarlo
    readonly property string coffeeScript: Qt.resolvedUrl("../code/coffee.py").toString().replace("file://", "")

    function coffeeStart() {
        // sin sh -c propio, plasma ya lo corre en un shell y se comen las comillas
        Exec.run(`pkill -f coffee.py; python3 "${root.coffeeScript}" >/dev/null 2>&1 &`);
    }

    function coffeeStop() {
        Exec.run("pkill -f coffee.py");
    }

    // si plasmashell se reinicia con el café puesto, queda un huérfano: se limpia al arrancar
    Component.onCompleted: if (!root.coffee) root.coffeeStop()

    readonly property int btnSize: 44

    // cuenta los hijos en vez de un número a mano, así no se corta al agregar botones
    readonly property int botones: Math.max(1, root.children.length - 1)

    // ── modo café ──
    Rectangle {
        width: root.width - (root.btnSize + root.spacing) * root.botones
        height: 44
        radius: Theme.shapeLg
        color: root.coffee ? Theme.inverted : coffeeMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

        Behavior on color {
            ColorAnimation {
                duration: Theme.durMedium
            }
        }

        Text {
            id: coffeeIcon
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "coffee"
            color: root.coffee ? Theme.invertedFg : Theme.fgDim
            font.family: Theme.fontIcons
            font.pixelSize: 20
        }

        Text {
            anchors.left: coffeeIcon.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: Cfg.t("MODO CAFÉ")
            color: root.coffee ? Theme.invertedFg : Theme.fg
            font.letterSpacing: Theme.labelSpacing
            font.family: Theme.font
            font.pixelSize: Theme.bodyMedium
            font.weight: Font.Medium
        }

        // interruptor m3
        Rectangle {
            id: track
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 24
            radius: height / 2
            color: root.coffee ? Theme.invertedFg : Theme.surfaceHigh
            border.width: root.coffee ? 0 : 2
            border.color: Theme.outline

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durMedium
                }
            }

            Rectangle {
                width: root.coffee ? 18 : 14
                height: width
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                x: root.coffee ? parent.width - width - 3 : 4
                color: root.coffee ? Theme.inverted : Theme.fgFaint

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
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durMedium
                    }
                }
            }
        }

        MouseArea {
            id: coffeeMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.coffee = !root.coffee;
                if (root.coffee)
                    root.coffeeStart();
                else
                    root.coffeeStop();
            }
        }
    }

    component ActionButton: Rectangle {
        id: ab
        property string icon: ""
        property bool danger: false
        signal activated

        width: root.btnSize
        height: 44
        radius: Theme.shapeMd
        // los tres opacos, si no mezclar opaco+translúcido da un fogonazo gris al animar
        color: abMa.pressed ? Theme.surfaceTop : abMa.containsMouse ? Theme.surfaceHigh : Theme.containerHigh

        // empuja al hover, se hunde al apretar
        scale: abMa.pressed ? 0.98 : abMa.containsMouse ? 1.04 : 1.0

        Behavior on color {
            ColorAnimation {
                duration: Theme.durShort
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.durShort
                easing.type: Easing.Bezier
                easing.bezierCurve: Theme.emphasizedDecel
            }
        }

        Text {
            anchors.centerIn: parent
            text: ab.icon
            color: ab.danger ? Theme.error : Theme.fgVariant
            font.family: Theme.fontIcons
            font.pixelSize: 19
        }

        MouseArea {
            id: abMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ab.activated()
        }
    }

    ActionButton {
        icon: "apps"
        onActivated: root.requestLauncher()
    }

    ActionButton {
        icon: "lock"
        onActivated: Exec.run("qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock")
    }

    ActionButton {
        icon: Notifs.muted ? "notifications_off" : "notifications"
        onActivated: root.requestNotifs()
    }

    ActionButton {
        icon: "power_settings_new"
        onActivated: root.requestPower()
    }

}
