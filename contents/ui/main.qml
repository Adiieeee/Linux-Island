import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "."

// isla dinámica para plasma: píldora en el panel + panel emergente al clic
PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    // ── preferencias ──
    Binding {
        target: Cfg
        property: "lang"
        value: Plasmoid.configuration.lang
    }
    Binding {
        target: Cfg
        property: "clock24"
        value: Plasmoid.configuration.clock24
    }
    Binding {
        target: Cfg
        property: "ramUsage"
        value: Plasmoid.configuration.ramUsage
    }
    Binding {
        target: Cfg
        property: "showWorkspaces"
        value: Plasmoid.configuration.showWorkspaces
    }
    Binding {
        target: Cfg
        property: "showWeather"
        value: Plasmoid.configuration.showWeather
    }
    Binding {
        target: Cfg
        property: "showClock"
        value: Plasmoid.configuration.showClock
    }
    Binding {
        target: Cfg
        property: "showNetwork"
        value: Plasmoid.configuration.showNetwork
    }
    Binding {
        target: Cfg
        property: "showBattery"
        value: Plasmoid.configuration.showBattery
    }
    Binding {
        target: Cfg
        property: "showMini"
        value: Plasmoid.configuration.showMini
    }
    Binding {
        target: Cfg
        property: "weatherCity"
        value: Plasmoid.configuration.weatherCity
    }
    Binding {
        target: Cfg
        property: "colorFondo"
        value: Plasmoid.configuration.colorFondo
    }
    Binding {
        target: Cfg
        property: "colorTarjeta"
        value: Plasmoid.configuration.colorTarjeta
    }
    Binding {
        target: Cfg
        property: "colorInvertida"
        value: Plasmoid.configuration.colorInvertida
    }
    Binding {
        target: Cfg
        property: "colorAlerta"
        value: Plasmoid.configuration.colorAlerta
    }
    Binding {
        target: Cfg
        property: "colorTexto"
        value: Plasmoid.configuration.colorTexto
    }
    Binding {
        target: Cfg
        property: "fuenteUi"
        value: Plasmoid.configuration.fuenteUi
    }
    Binding {
        target: Cfg
        property: "fuenteNumeros"
        value: Plasmoid.configuration.fuenteNumeros
    }
    Binding {
        target: Cfg
        property: "recFolder"
        value: Plasmoid.configuration.recFolder
    }
    Binding {
        target: Cfg
        property: "recMode"
        value: Plasmoid.configuration.recMode
    }

    // folder and mode picked in the recording view (Recorder can't write the config)
    Connections {
        target: Recorder
        function onFolderChosen(path) {
            Plasmoid.configuration.recFolder = path;
        }
        function onModeChosen(mode) {
            Plasmoid.configuration.recMode = mode;
        }
    }

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    toolTipMainText: Qt.formatDateTime(new Date(), "HH:mm")
    toolTipSubText: Weather.ready ? Weather.temp + " · " + Weather.desc : ""

    compactRepresentation: MouseArea {
        id: compact
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded = !root.expanded

        readonly property bool horizontal: Plasmoid.formFactor !== PlasmaCore.Types.Vertical

        // reserve exactly what is drawn. a hardcoded width here made the pill
        // spill past its slot into the neighbouring widgets
        readonly property real targetWidth: compactPill.implicitWidth

        Layout.minimumWidth: horizontal ? targetWidth : -1
        Layout.preferredWidth: horizontal ? targetWidth : -1
        Layout.maximumWidth: horizontal ? targetWidth : Infinity
        Layout.fillHeight: horizontal
        Layout.minimumHeight: horizontal ? -1 : Theme.collapsedHeight
        Layout.preferredHeight: horizontal ? -1 : Theme.collapsedHeight

        implicitWidth: targetWidth
        implicitHeight: Theme.collapsedHeight

        // the whole island: album art · clock · waveform. it takes the slot's
        // height and reaches past it to the panel's edges on its own
        CompactPill {
            id: compactPill
            anchors.centerIn: parent
            width: implicitWidth
            height: compact.height
            horizontal: compact.horizontal
        }
    }

    fullRepresentation: ExpandedPanel {
        id: full

        // smaller than Theme.expandedWidth by the part of Plasma's frame the
        // island covers (ExpandedPanel.reach)
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Layout.maximumWidth: implicitWidth

        // min = preferred = max = implicitHeight, set by hand in an order that
        // keeps min <= max at every step. Plasma reacts to each of the three on
        // its own (setMinimumHeight, resize, setMaximumHeight on the popup
        // window); as three bindings, growing went through min 710 / max 524
        // for an instant
        function applyHeight() {
            const h = full.implicitHeight;
            if (h > full.Layout.maximumHeight) {
                full.Layout.maximumHeight = h;
                full.Layout.preferredHeight = h;
                full.Layout.minimumHeight = h;
            } else {
                full.Layout.minimumHeight = h;
                full.Layout.preferredHeight = h;
                full.Layout.maximumHeight = h;
            }
        }
        onImplicitHeightChanged: applyHeight()
        Component.onCompleted: applyHeight()
    }
}
