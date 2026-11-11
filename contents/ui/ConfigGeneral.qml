import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "."

// página de preferencias, plasma conecta solo cada cfg_<clave> con main.xml
Kirigami.FormLayout {
    id: page

    property string cfg_lang: "auto"
    property bool cfg_clock24: true
    property bool cfg_ramUsage: false
    property bool cfg_showWorkspaces: true
    property bool cfg_showWeather: true
    property bool cfg_showClock: true
    property bool cfg_showNetwork: true
    property bool cfg_showBattery: true
    property bool cfg_showMini: true
    property bool cfg_showLyrics: true
    property string cfg_weatherCity: ""

    // del combo en vivo, no de Cfg.esp (eso es el idioma ya aplicado, no el que se está eligiendo)
    readonly property bool esp: page.cfg_lang === "es" || (page.cfg_lang === "auto" && Qt.locale().name.startsWith("es"))

    QQC2.ComboBox {
        id: idiomaBox
        Kirigami.FormData.label: page.esp ? "Idioma:" : "Language:"
        textRole: "texto"
        valueRole: "valor"
        model: [
            {
                texto: page.esp ? "Automático (el del sistema)" : "Automatic (system)",
                valor: "auto"
            },
            {
                texto: "Español",
                valor: "es"
            },
            {
                texto: "English",
                valor: "en"
            }
        ]

        // índice fijado una sola vez, con binding a cfg_lang se pisaría solo
        Component.onCompleted: currentIndex = indexOfValue(page.cfg_lang)
        onActivated: page.cfg_lang = currentValue
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.ComboBox {
        id: horaBox
        Kirigami.FormData.label: page.esp ? "Hora:" : "Clock:"
        textRole: "texto"
        valueRole: "valor"
        model: [
            {
                texto: page.esp ? "24 horas" : "24-hour",
                valor: true
            },
            {
                texto: page.esp ? "12 horas (AM/PM)" : "12-hour (AM/PM)",
                valor: false
            }
        ]

        Component.onCompleted: currentIndex = indexOfValue(page.cfg_clock24)
        onActivated: page.cfg_clock24 = currentValue
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.TextField {
        id: ciudadField
        Kirigami.FormData.label: page.esp ? "Ciudad:" : "City:"
        placeholderText: page.esp ? "Automática (por IP)" : "Automatic (by IP)"
        text: page.cfg_weatherCity

        onEditingFinished: page.cfg_weatherCity = text
    }

    QQC2.Label {
        Kirigami.FormData.label: ""
        text: page.esp ? "Ej: Escobedo, Nuevo León, México. Vacío para detectarla sola." : "E.g: Escobedo, Nuevo Leon, Mexico. Leave empty to auto-detect."
        opacity: 0.7
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        Kirigami.FormData.label: page.esp ? "Medidores:" : "Meters:"
        text: page.esp ? "Mostrar la RAM usada en GiB (7.8) junto al porcentaje" : "Show RAM used in GiB (7.8) next to the percentage"
        checked: page.cfg_ramUsage
        onToggled: page.cfg_ramUsage = checked
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    // the desktop dots are off for now and the clock is always there, so
    // their checkboxes are gone (showWorkspaces/showClock stay in main.xml)
    QQC2.CheckBox {
        Kirigami.FormData.label: page.esp ? "Mostrar en la isla chica:" : "Show in the small island:"
        text: page.esp ? "Clima" : "Weather"
        checked: page.cfg_showWeather
        onToggled: page.cfg_showWeather = checked
    }

    QQC2.CheckBox {
        text: page.esp ? "Red" : "Network"
        checked: page.cfg_showNetwork
        onToggled: page.cfg_showNetwork = checked
    }

    QQC2.CheckBox {
        text: page.esp ? "Batería" : "Battery"
        checked: page.cfg_showBattery
        onToggled: page.cfg_showBattery = checked
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        Kirigami.FormData.label: page.esp ? "Reproductor:" : "Player:"
        text: page.esp ? "Mostrar la carátula y la onda al sonar algo" : "Show album art and waveform while something plays"
        checked: page.cfg_showMini
        onToggled: page.cfg_showMini = checked
    }

    QQC2.Label {
        Kirigami.FormData.label: ""
        text: page.esp ? "A los lados del reloj, mientras hay música o video sonando o en pausa." : "On both sides of the clock, while music or video is playing or paused."
        opacity: 0.7
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
    }

    QQC2.CheckBox {
        text: page.esp ? "Mostrar la letra sincronizada" : "Show synced lyrics"
        enabled: page.cfg_showMini
        checked: page.cfg_showLyrics
        onToggled: page.cfg_showLyrics = checked
    }

    QQC2.Label {
        Kirigami.FormData.label: ""
        text: page.esp ? "En lugar del reloj mientras se canta una línea. Para encontrarla se envían a lrclib.net el título, el artista, el álbum y la duración de la canción." : "In place of the clock while a line is sung. To find them, the song's title, artist, album and length are sent to lrclib.net."
        opacity: 0.7
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
    }
}
