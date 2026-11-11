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
    property bool cfg_showBattery: true
    property bool cfg_showMini: true
    property bool cfg_showLyrics: true
    property bool cfg_tintIsland: false
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
                texto: page.esp ? "Español" : "Spanish",
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

    // the desktop dots and the clock are always there, so their checkboxes
    // are gone (showWorkspaces/showClock stay in main.xml). weather and
    // battery don't do anything yet either
    QQC2.CheckBox {
        Kirigami.FormData.label: page.esp ? "Mostrar en la isla chica:" : "Show in the small island:"
        text: page.esp ? "Clima" : "Weather"
        checked: page.cfg_showWeather
        onToggled: page.cfg_showWeather = checked
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
        text: page.esp ? "En la muesca de la isla, mientras hay música o video sonando o en pausa. Apagado: solo la fecha." : "In the island's notch, while music or video is playing or paused. Off: just the date."
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
        text: page.esp ? "En el centro de la muesca mientras se canta una línea (♪ entre líneas, ♫ si la canción no tiene letra; apagado: la fecha). Para encontrarla se envían a lrclib.net el título, el artista, el álbum y la duración de la canción." : "In the middle of the notch while a line is sung (♪ between lines, ♫ for a song without lyrics; off: the date). To find them, the song's title, artist, album and length are sent to lrclib.net."
        opacity: 0.7
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
    }

    QQC2.CheckBox {
        text: page.esp ? "Colorear la isla con la carátula" : "Colour the island with the album art"
        enabled: page.cfg_showMini
        checked: page.cfg_tintIsland
        onToggled: page.cfg_tintIsland = checked
    }

    QQC2.Label {
        Kirigami.FormData.label: ""
        text: page.esp ? "Con los colores de la carátula, como la tarjeta del reproductor en el centro de control. Apagado: negra, como el centro de control." : "In the cover's colours, like the media card in the control center. Off: black, like the control center."
        opacity: 0.7
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
    }
}
