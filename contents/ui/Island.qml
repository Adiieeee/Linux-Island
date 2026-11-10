import QtQuick
import "."

// isla que crece en el lugar como en hyprland, sin usar (ver readme)
// solo funciona con panel propio y transparente; el alto hay que pedírselo a plasmashell
Item {
    id: root

    property bool expanded: false

    readonly property int collapsedH: Theme.collapsedHeight
    readonly property int bodyH: body.implicitHeight

    // isla abierta más un respiro abajo
    readonly property int panelAlto: collapsedH + bodyH + 14
    readonly property int panelBajo: collapsedH + 8

    implicitWidth: expanded ? Theme.expandedWidth : Theme.collapsedWidth
    implicitHeight: expanded ? collapsedH + bodyH : collapsedH

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.durLong
            easing.type: Easing.Bezier
            easing.bezierCurve: Theme.emphasizedDecel
        }
    }
    Behavior on implicitHeight {
        NumberAnimation {
            duration: Theme.durLong
            easing.type: Easing.Bezier
            easing.bezierCurve: Theme.emphasizedDecel
        }
    }

    // busca solo el panel donde está, sin id fijo que se rompa si el panel se recrea
    function pedirAlto(h) {
        Exec.run('qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
                 + '\'for (var i = 0; i < panelIds.length; i++) { var p = panelById(panelIds[i]); '
                 + 'if (p.widgets("org.omar.nothingisland").length > 0) p.height = ' + h + '; }\'');
    }

    onExpandedChanged: {
        if (expanded) {
            encoger.stop();
            // primero agrandar el panel, si no la isla queda recortada
            pedirAlto(panelAlto);
        } else {
            // al revés: espera a que la isla encoja y recién ahí achica el panel
            encoger.restart();
        }
    }

    Timer {
        id: encoger
        interval: Theme.durLong + 80
        onTriggered: root.pedirAlto(root.panelBajo)
    }

    // arranca del tamaño correcto aunque plasmashell se reinicie con la isla abierta
    Component.onCompleted: pedirAlto(expanded ? panelAlto : panelBajo)

    Rectangle {
        id: shell
        anchors.fill: parent
        color: Theme.surface
        clip: true

        // píldora cerrada, tarjeta con esquinas suaves abierta
        radius: root.expanded ? Theme.expandedRadius : height / 2

        Behavior on radius {
            NumberAnimation {
                duration: Theme.durMedium
                easing.type: Easing.Bezier
                easing.bezierCurve: Theme.emphasized
            }
        }

        // clic en cualquier parte libre abre/cierra, va primero para quedar debajo de los controles
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }

        // fila de siempre arriba, no se mueve al abrir
        CompactPill {
            id: pill
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.width
            height: root.collapsedH
        }

        // cuerpo debajo, ancho fijo abierto para que el contenido no se reacomode al crecer
        ExpandedPanel {
            id: body
            anchors.top: pill.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.expandedWidth

            opacity: root.expanded ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durMedium
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Theme.emphasized
                }
            }
        }
    }
}
