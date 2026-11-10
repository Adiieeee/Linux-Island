import QtQuick
import org.kde.plasma.configuration
import "../ui"

// páginas de preferencias, plasma agrega sola la de atajos y "acerca de"
ConfigModel {
    ConfigCategory {
        name: Cfg.esp ? "Isla" : "Island"
        icon: "preferences-desktop-display"
        source: "ConfigGeneral.qml"
    }
    ConfigCategory {
        name: Cfg.esp ? "Colores" : "Colours"
        icon: "preferences-desktop-color"
        source: "ConfigColores.qml"
    }
    ConfigCategory {
        name: Cfg.esp ? "Tipografías" : "Fonts"
        icon: "preferences-desktop-font"
        source: "ConfigTipografias.qml"
    }
}
