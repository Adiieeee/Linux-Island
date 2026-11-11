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

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    toolTipMainText: Qt.formatDateTime(new Date(), "HH:mm")
    toolTipSubText: Weather.ready ? Weather.temp + " · " + Weather.desc : ""

    compactRepresentation: MouseArea {
        id: compact
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded = !root.expanded

        readonly property bool horizontal: Plasmoid.formFactor !== PlasmaCore.Types.Vertical

        readonly property bool musicActive: Cfg.showMini && musicPill.active
        // reserve exactly what is drawn: the pill, plus the 6 px gap and the
        // music pill while something plays. a hardcoded width here made the
        // pill spill past its slot into the neighbouring widgets
        readonly property real targetWidth: compactPill.implicitWidth + (musicActive ? musicPill.implicitWidth + 6 : 0)

        Layout.minimumWidth: horizontal ? targetWidth : -1
        Layout.preferredWidth: horizontal ? targetWidth : -1
        Layout.maximumWidth: horizontal ? targetWidth : Infinity
        Layout.fillHeight: horizontal
        Layout.minimumHeight: horizontal ? -1 : Theme.collapsedHeight
        Layout.preferredHeight: horizontal ? -1 : Theme.collapsedHeight

        implicitWidth: targetWidth
        implicitHeight: Theme.collapsedHeight

        // Using a Row with a clean gap ensures they never overlap
        Row {
            anchors.centerIn: parent
            spacing: 6

            // both pills take the full panel thickness
            CompactPill {
                id: compactPill
                anchors.verticalCenter: parent.verticalCenter
                height: compact.height
            }

            MusicPill {
                id: musicPill
                anchors.verticalCenter: parent.verticalCenter
                height: compact.height
            }
        }
    }

    fullRepresentation: ExpandedPanel {
        Layout.minimumWidth: Theme.expandedWidth
        Layout.preferredWidth: Theme.expandedWidth
        Layout.maximumWidth: Theme.expandedWidth
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
        Layout.maximumHeight: implicitHeight
    }
}
