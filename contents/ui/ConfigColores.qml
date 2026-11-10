import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQC
import "."

// colores de la isla, plasma conecta solo cada cfg_<clave> con main.xml
Kirigami.FormLayout {
    id: page

    property color cfg_colorFondo
    property color cfg_colorTarjeta
    property color cfg_colorInvertida
    property color cfg_colorAlerta

    // los de fábrica los rellena plasma desde main.xml, solo hay que declararlos
    property color cfg_colorFondoDefault
    property color cfg_colorTarjetaDefault
    property color cfg_colorInvertidaDefault
    property color cfg_colorAlertaDefault

    // cfg_lang es el mismo valor en vivo del combo de Idioma en la página
    // General, no el ya aplicado (Cfg.esp): las páginas comparten un solo
    // KConfigPropertyMap, así que esto cambia sin cerrar el diálogo
    property string cfg_lang: "auto"
    readonly property bool esp: page.cfg_lang === "es" || (page.cfg_lang === "auto" && Qt.locale().name.startsWith("es"))

    // al elegir un color el botón se escribe el suyo y deja sin efecto el binding,
    // así que restablecer también tiene que devolvérselo a mano
    function restablecer() {
        page.cfg_colorFondo = page.cfg_colorFondoDefault;
        page.cfg_colorTarjeta = page.cfg_colorTarjetaDefault;
        page.cfg_colorInvertida = page.cfg_colorInvertidaDefault;
        page.cfg_colorAlerta = page.cfg_colorAlertaDefault;

        fondoBtn.color = page.cfg_colorFondoDefault;
        tarjetaBtn.color = page.cfg_colorTarjetaDefault;
        invertidaBtn.color = page.cfg_colorInvertidaDefault;
        alertaBtn.color = page.cfg_colorAlertaDefault;
    }

    // sin alfa en ninguno: la isla se dibuja opaca y un color a medias deja
    // ver el escritorio por debajo
    KQC.ColorButton {
        id: fondoBtn
        Kirigami.FormData.label: page.esp ? "Fondo:" : "Background:"
        showAlphaChannel: false
        color: page.cfg_colorFondo
        onAccepted: page.cfg_colorFondo = color
    }

    QQC2.Label {
        Kirigami.FormData.label: ""
        text: page.esp ? "El fondo de la isla abierta." : "The background of the open island."
        opacity: 0.7
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
    }

    KQC.ColorButton {
        id: tarjetaBtn
        Kirigami.FormData.label: page.esp ? "Tarjetas:" : "Cards:"
        showAlphaChannel: false
        color: page.cfg_colorTarjeta
        onAccepted: page.cfg_colorTarjeta = color
    }

    QQC2.Label {
        Kirigami.FormData.label: ""
        text: page.esp ? "Los bloques de adentro. Los grises más claros (barras, bordes) salen de este." : "The blocks inside. The lighter greys (bars, borders) come from this one."
        opacity: 0.7
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
    }

    KQC.ColorButton {
        id: invertidaBtn
        Kirigami.FormData.label: page.esp ? "Encendido:" : "Active:"
        showAlphaChannel: false
        color: page.cfg_colorInvertida
        onAccepted: page.cfg_colorInvertida = color
    }

    QQC2.Label {
        Kirigami.FormData.label: ""
        text: page.esp ? "La tarjeta invertida cuando algo está conectado o activo. El texto de adentro se pone blanco o negro solo, según el brillo." : "The inverted card when something is connected or active. The text inside turns white or black on its own, by brightness."
        opacity: 0.7
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
    }

    KQC.ColorButton {
        id: alertaBtn
        Kirigami.FormData.label: page.esp ? "Alerta:" : "Alert:"
        showAlphaChannel: false
        color: page.cfg_colorAlerta
        onAccepted: page.cfg_colorAlerta = color
    }

    QQC2.Label {
        Kirigami.FormData.label: ""
        text: page.esp ? "Solo estados críticos: temperatura alta, grabando, volumen sobre 100 %." : "Critical states only: high temperature, recording, volume above 100%."
        opacity: 0.7
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.Button {
        Kirigami.FormData.label: ""
        text: page.esp ? "Restablecer colores" : "Reset colours"
        icon.name: "edit-undo"
        enabled: page.cfg_colorFondo !== page.cfg_colorFondoDefault || page.cfg_colorTarjeta !== page.cfg_colorTarjetaDefault || page.cfg_colorInvertida !== page.cfg_colorInvertidaDefault || page.cfg_colorAlerta !== page.cfg_colorAlertaDefault
        onClicked: page.restablecer()
    }
}
