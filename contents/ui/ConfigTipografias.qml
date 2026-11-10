import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQC
import "."

// tipografías de la isla, plasma conecta solo cada cfg_<clave> con main.xml
Kirigami.FormLayout {
    id: page

    property string cfg_fuenteUi
    property string cfg_fuenteNumeros
    property color cfg_colorTexto

    // los de fábrica los rellena plasma desde main.xml, solo hay que declararlos
    property string cfg_fuenteUiDefault
    property string cfg_fuenteNumerosDefault
    property color cfg_colorTextoDefault

    // cfg_lang es el mismo valor en vivo del combo de Idioma en la página
    // General, no el ya aplicado (Cfg.esp): las páginas comparten un solo
    // KConfigPropertyMap, así que esto cambia sin cerrar el diálogo
    property string cfg_lang: "auto"
    readonly property bool esp: page.cfg_lang === "es" || (page.cfg_lang === "auto" && Qt.locale().name.startsWith("es"))

    // se pide una sola vez: recalcularla al cambiar de idioma movería el índice
    // de los dos combos
    readonly property var familias: Qt.fontFamilies()

    // el índice 0 de cada combo es la fuente empaquetada, guardada como texto vacío
    function indiceDe(familia) {
        return page.familias.indexOf(familia) + 1;
    }

    // los combos y el botón de color se escriben su propio valor al usarlos y
    // dejan sin efecto el binding, así que restablecer se los devuelve a mano
    function restablecer() {
        page.cfg_fuenteUi = page.cfg_fuenteUiDefault;
        page.cfg_fuenteNumeros = page.cfg_fuenteNumerosDefault;
        page.cfg_colorTexto = page.cfg_colorTextoDefault;

        uiBox.currentIndex = page.indiceDe(page.cfg_fuenteUiDefault);
        numerosBox.currentIndex = page.indiceDe(page.cfg_fuenteNumerosDefault);
        textoBtn.color = page.cfg_colorTextoDefault;
    }

    QQC2.ComboBox {
        id: uiBox
        Kirigami.FormData.label: page.esp ? "Interfaz:" : "Interface:"
        model: [page.esp ? "La que viene (Space Grotesk)" : "Bundled (Space Grotesk)"].concat(page.familias)

        Component.onCompleted: currentIndex = page.indiceDe(page.cfg_fuenteUi)
        onActivated: page.cfg_fuenteUi = currentIndex === 0 ? "" : page.familias[currentIndex - 1]
    }

    QQC2.Label {
        Kirigami.FormData.label: ""
        text: page.esp ? "Los textos y las etiquetas en mayúsculas." : "Labels and running text."
        opacity: 0.7
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
    }

    QQC2.ComboBox {
        id: numerosBox
        Kirigami.FormData.label: page.esp ? "Números:" : "Numbers:"
        model: [page.esp ? "La que viene (NDOT 47)" : "Bundled (NDOT 47)"].concat(page.familias)

        Component.onCompleted: currentIndex = page.indiceDe(page.cfg_fuenteNumeros)
        onActivated: page.cfg_fuenteNumeros = currentIndex === 0 ? "" : page.familias[currentIndex - 1]
    }

    QQC2.Label {
        Kirigami.FormData.label: ""
        text: page.esp ? "El reloj, los porcentajes y los tiempos del reproductor." : "The clock, the percentages and the player times."
        opacity: 0.7
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    KQC.ColorButton {
        id: textoBtn
        Kirigami.FormData.label: page.esp ? "Color del texto:" : "Text colour:"
        showAlphaChannel: false
        color: page.cfg_colorTexto
        onAccepted: page.cfg_colorTexto = color
    }

    QQC2.Label {
        Kirigami.FormData.label: ""
        text: page.esp ? "Los tonos apagados (subtítulos, iconos en reposo) salen de mezclar este con el fondo." : "The dimmed tones (subtitles, idle icons) come from mixing this one with the background."
        opacity: 0.7
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.Label {
        Kirigami.FormData.label: ""
        text: page.esp ? "Los iconos no se cambian: son ligaduras de Material Symbols y con otra fuente saldría el nombre en texto." : "Icons can't be changed: they are Material Symbols ligatures, another font would show their name as text."
        opacity: 0.7
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
    }

    QQC2.Button {
        Kirigami.FormData.label: ""
        text: page.esp ? "Restablecer tipografías" : "Reset fonts"
        icon.name: "edit-undo"
        enabled: page.cfg_fuenteUi !== page.cfg_fuenteUiDefault || page.cfg_fuenteNumeros !== page.cfg_fuenteNumerosDefault || page.cfg_colorTexto !== page.cfg_colorTextoDefault
        onClicked: page.restablecer()
    }
}
