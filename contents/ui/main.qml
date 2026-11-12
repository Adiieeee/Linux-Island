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
        property: "showLyrics"
        value: Plasmoid.configuration.showLyrics
    }
    Binding {
        target: Cfg
        property: "tintIsland"
        value: Plasmoid.configuration.tintIsland
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

    // the meters, the volume and the Wi-Fi / Bluetooth state are only read
    // while the control center is open (singletons can't see `expanded`)
    Binding {
        target: SysInfo
        property: "open"
        value: root.expanded
    }
    Binding {
        target: Audio
        property: "open"
        value: root.expanded
    }
    Binding {
        target: Net
        property: "open"
        value: root.expanded
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

    // the control center closes on its own once the pointer has been off
    // both the notch and the popup for Theme.hoverCloseDelay
    Timer {
        interval: Theme.hoverCloseDelay
        running: root.expanded && !(root.compactRepresentationItem?.notchHovered ?? false) && !(root.fullRepresentationItem?.engaged ?? false)
        onTriggered: root.expanded = false
    }

    // no tooltip: hovering the island used to show the time and weather after
    // a moment. both empty, explicitly: left unset, Plasma falls back to the
    // applet's name and still shows one
    toolTipMainText: ""
    toolTipSubText: ""

    // an Item, not a MouseArea: only the notch takes clicks (CompactPill),
    // not the desktop dots or the empty space beside it
    compactRepresentation: Item {
        id: compact

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

        // the whole island: desktop dots · notch · (room for the clock). it
        // takes the slot's height and the notch reaches past it to the
        // panel's edges on its own
        // read by the close timer above
        readonly property bool notchHovered: compactPill.notchHovered

        CompactPill {
            id: compactPill
            anchors.centerIn: parent
            width: implicitWidth
            height: compact.height
            horizontal: compact.horizontal
            bottomEdge: Plasmoid.location === PlasmaCore.Types.BottomEdge
            onActivated: root.expanded = !root.expanded
            onOpenRequested: root.expanded = true
        }
    }

    fullRepresentation: ExpandedPanel {
        id: full

        onLyricsToggled: Plasmoid.configuration.showLyrics = !Plasmoid.configuration.showLyrics
        onCloseRequested: root.expanded = false

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
