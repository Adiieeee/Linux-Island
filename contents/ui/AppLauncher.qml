import QtQuick
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "."

// lanzador de apps: lee los .desktop con apps.py y busca difuso, como el de quickshell
Item {
    id: root

    signal closed

    implicitHeight: col.implicitHeight

    readonly property int maxResults: 8
    property int selected: 0
    property var apps: []

    readonly property string scanScript: Qt.resolvedUrl("../code/apps.py").toString().replace("file://", "")

    readonly property P5Support.DataSource source: P5Support.DataSource {
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            try {
                root.apps = JSON.parse(data["stdout"] ?? "[]");
            } catch (e) {
                root.apps = [];
            }
        }
    }

    Component.onCompleted: {
        root.source.connectSource(`python3 "${root.scanScript}"`);
        search.forceActiveFocus();
    }

    function quote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    readonly property var results: {
        const q = search.text.trim().toLowerCase();
        const scored = [];

        for (const app of root.apps) {
            const name = (app.name ?? "").toLowerCase();
            const generic = (app.generic ?? "").toLowerCase();

            if (q === "") {
                scored.push({
                    app: app,
                    score: 0
                });
                continue;
            }

            let score = -1;
            if (name.startsWith(q))
                score = 100 - name.length;
            else if (name.includes(q))
                score = 50 - name.indexOf(q);
            else if (generic.includes(q))
                score = 20;

            if (score >= 0)
                scored.push({
                    app: app,
                    score: score
                });
        }

        scored.sort((a, b) => {
            if (b.score !== a.score)
                return b.score - a.score;
            return (a.app.name ?? "").localeCompare(b.app.name ?? "");
        });

        return scored.slice(0, root.maxResults).map(s => s.app);
    }

    onResultsChanged: selected = 0

    function launch() {
        const app = root.results[root.selected];
        if (app) {
            Exec.run(`gio launch ${root.quote(app.path)}`);
            root.closed();
        }
    }

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
                text: Cfg.t("APLICACIONES")
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
                    onClicked: root.closed()
                }
            }
        }

        // ── campo de búsqueda ──
        Rectangle {
            width: parent.width
            height: 44
            radius: height / 2
            color: Theme.surfaceAlt

            Text {
                id: searchIcon
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                color: Theme.fgVariant
                font.family: Theme.fontIcons
                font.pixelSize: 20
            }

            TextInput {
                id: search
                anchors.left: searchIcon.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter

                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.bodyMedium
                selectByMouse: true
                selectionColor: Qt.alpha(Theme.fg, 0.25)
                clip: true

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text === ""
                    text: Cfg.t("Buscar aplicaciones…")
                    color: Theme.outline
                    font: search.font
                }

                Keys.onEscapePressed: root.closed()
                Keys.onReturnPressed: root.launch()
                Keys.onEnterPressed: root.launch()

                Keys.onDownPressed: {
                    if (root.results.length > 0)
                        root.selected = (root.selected + 1) % root.results.length;
                }
                Keys.onUpPressed: {
                    if (root.results.length > 0)
                        root.selected = (root.selected - 1 + root.results.length) % root.results.length;
                }
            }
        }

        // ── resultados ──
        // tope de alto + arrastre, si no con muchos resultados se cortan contra el borde
        readonly property int listMax: 300

        Item {
            width: parent.width
            height: Math.min(col.listMax, lista.contentHeight)

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
                    spacing: 2

                    Repeater {
                        model: root.results

                        Rectangle {
                            id: row
                            required property var modelData
                            required property int index

                            width: parent.width
                            height: 52
                            radius: Theme.shapeMd

                    readonly property bool current: root.selected === index

                    color: current ? Qt.alpha(Theme.fg, 0.14) : rowMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durShort
                        }
                    }

                    Kirigami.Icon {
                        id: appIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30
                        height: 30
                        source: row.modelData.icon ?? ""
                        fallback: "widgets"
                    }

                    Column {
                        anchors.left: appIcon.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            width: parent.width
                            text: row.modelData.name ?? ""
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.bodyMedium
                            font.weight: row.current ? Font.Medium : Font.Normal
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: row.modelData.generic ?? ""
                            color: Theme.fgVariant
                            font.family: Theme.font
                            font.pixelSize: Theme.labelSmall
                            elide: Text.ElideRight
                            visible: text !== ""
                        }
                    }

                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selected = row.index
                        onClicked: {
                            root.selected = row.index;
                            root.launch();
                        }
                    }
                }
            }

                    // sin resultados
                    Item {
                        width: parent.width
                        height: root.results.length === 0 ? 52 : 0
                        visible: root.results.length === 0

                        Text {
                            anchors.centerIn: parent
                            text: Cfg.t("Sin resultados")
                            color: Theme.outline
                            font.family: Theme.font
                            font.pixelSize: Theme.bodySmall
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
