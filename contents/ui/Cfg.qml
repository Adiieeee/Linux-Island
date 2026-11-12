pragma Singleton

import QtQuick

// ajustes de la isla en un solo lugar
// los singletons no ven Plasmoid.configuration, main.qml copia los valores acá
QtObject {
    id: cfg

    // ── idioma ──
    // "auto" sigue el sistema, "es"/"en" lo fuerzan
    property string lang: "auto"

    readonly property string localeName: {
        if (cfg.lang === "es")
            return "es_ES";
        if (cfg.lang === "en")
            return "en_US";
        return Qt.locale().name;
    }

    readonly property var locale: Qt.locale(cfg.localeName)

    // sistema en idioma sin traducción cae en inglés
    readonly property bool esp: cfg.lang === "es" || (cfg.lang === "auto" && Qt.locale().name.startsWith("es"))

    // ── hora ──
    property bool clock24: true

    readonly property string fmtHora: cfg.clock24 ? "HH:mm" : "h:mm AP"
    readonly property string fmtHoraCorta: cfg.clock24 ? "HH:mm" : "h:mm"

    // ── medidores ──
    // off: RAM as a percentage only. on: also the used GiB ("7.8") next to it
    property bool ramUsage: true

    // ── qué se ve en la píldora chica ──
    // showWorkspaces and showClock are unused: the island always shows the
    // desktop dots and the clock (outside its notch). showWeather and
    // showBattery are unused too, kept for a later plan
    property bool showWorkspaces: true
    property bool showWeather: true
    property bool showClock: true
    property bool showBattery: true
    property bool showMini: true
    // synced lyrics in the small island (Lyrics.qml); off = nothing is sent
    // to lrclib.net
    property bool showLyrics: true
    // the panel island in the album art's colours, like the media card; off
    // = black, like the control center
    property bool tintIsland: false

    // ciudad para el clima; vacío = wttr.in detecta sola por ip
    property string weatherCity: ""

    // recordings folder picked in the recording view; empty = Recorder.defaultFolder
    property string recFolder: ""
    // recording mode: "s" whole screen, "w" one window
    property string recMode: "s"

    // ── aspecto ──
    // los valores de acá son solo el arranque, main.qml los pisa con lo guardado
    property color colorFondo: "#000000"
    property color colorTarjeta: "#0B0B0B"
    property color colorInvertida: "#FFFFFF"
    property color colorAlerta: "#D71921"
    property color colorTexto: "#FFFFFF"

    // empty = system font (numbers: the interface font)
    property string fuenteUi: ""
    property string fuenteNumeros: ""

    // ── textos ──
    // diccionario chico en vez del sistema de traducción de kde, cambia sin reiniciar
    readonly property var textos: ({
            "RED": ["RED", "NETWORK"],
            "DISPOSITIVOS": ["DISPOSITIVOS", "DEVICES"],
            "CONECTADO": ["CONECTADO", "CONNECTED"],
            "CONECTADOS": ["CONECTADOS", "CONNECTED"],
            "REDES GUARDADAS": ["REDES GUARDADAS", "SAVED NETWORKS"],
            "DISPOSITIVOS CONOCIDOS": ["DISPOSITIVOS CONOCIDOS", "KNOWN DEVICES"],
            "REDES CERCANAS": ["REDES CERCANAS", "NEARBY NETWORKS"],
            "DISPOSITIVOS CERCANOS": ["DISPOSITIVOS CERCANOS", "NEARBY DEVICES"],
            "Conectado": ["Conectado", "Connected"],
            "Guardado": ["Guardado", "Saved"],
            "Disponible": ["Disponible", "Available"],
            "Conectando…": ["Conectando…", "Connecting…"],
            "Emparejando…": ["Emparejando…", "Pairing…"],
            "No se pudo conectar": ["No se pudo conectar", "Couldn't connect"],
            "Escribí la contraseña": ["Escribí la contraseña", "Enter the password"],
            "Contraseña": ["Contraseña", "Password"],
            "Buscando…": ["Buscando…", "Searching…"],
            "Desconocido": ["Desconocido", "Unknown"],
            "Wi-Fi apagado": ["Wi-Fi apagado", "Wi-Fi off"],
            "Bluetooth apagado": ["Bluetooth apagado", "Bluetooth off"],
            "CALENDARIO": ["CALENDARIO", "CALENDAR"],
            "EN LA BANDEJA": ["EN LA BANDEJA", "IN THE TRAY"],
            "OTRA": ["Otra", "Other"],
            "HOY": ["HOY", "TODAY"],
            "Semana": ["Semana", "Week"],
            "GRABACIÓN": ["GRABACIÓN", "RECORDING"],
            "Nada reproduciéndose": ["Nada reproduciéndose", "Nothing playing"],

            // detalle de red/dispositivo
            "Señal": ["Señal", "Signal"],
            "Protegida": ["Protegida", "Secured"],
            "Abierta": ["Abierta", "Open"],
            "CONECTAR": ["CONECTAR", "CONNECT"],
            "DESCONECTAR": ["DESCONECTAR", "DISCONNECT"],
            "OLVIDAR": ["OLVIDAR", "FORGET"],

            // tarjetas de la isla
            "Sin red": ["Sin red", "No network"],
            "SIN RED": ["SIN RED", "NO NETWORK"],
            "APAGADO": ["APAGADO", "OFF"],
            "ENCENDIDO": ["ENCENDIDO", "ON"],
            "SONIDO": ["SONIDO", "SOUND"],
            "MODO CAFÉ": ["MODO CAFÉ", "COFFEE MODE"],

            // sonido
            "SALIDA": ["SALIDA", "OUTPUT"],
            "ENTRADA": ["ENTRADA", "INPUT"],
            "Sin salidas": ["Sin salidas", "No outputs"],

            // brightness
            "BRILLO": ["BRILLO", "BRIGHTNESS"],
            "PORTÁTIL": ["PORTÁTIL", "LAPTOP"],
            "Sin entradas": ["Sin entradas", "No inputs"],

            // notificaciones
            "NOTIFICACIONES": ["NOTIFICACIONES", "NOTIFICATIONS"],
            "SILENCIAR": ["SILENCIAR", "MUTE"],
            "SILENCIADAS": ["SILENCIADAS", "MUTED"],
            "VACIAR": ["VACIAR", "CLEAR"],
            "SIN NOTIFICACIONES": ["SIN NOTIFICACIONES", "NO NOTIFICATIONS"],

            // apagado
            "APAGADO_PANEL": ["APAGADO", "POWER"],
            "CERRAR SESIÓN": ["CERRAR SESIÓN", "LOG OUT"],
            "Cierra los programas abiertos": ["Cierra los programas abiertos", "Closes the open programs"],
            "SUSPENDER": ["SUSPENDER", "SLEEP"],
            "Se apaga la pantalla, todo queda como está": ["Se apaga la pantalla, todo queda como está", "Screen off, everything stays as it is"],
            "HIBERNAR": ["HIBERNAR", "HIBERNATE"],
            "Guarda todo en el disco y apaga": ["Guarda todo en el disco y apaga", "Saves everything to disk and powers off"],
            "REINICIAR": ["REINICIAR", "RESTART"],
            "Apaga y vuelve a arrancar": ["Apaga y vuelve a arrancar", "Powers off and starts again"],
            "APAGAR": ["APAGAR", "SHUT DOWN"],
            "Apaga el equipo": ["Apaga el equipo", "Powers off the computer"],

            // grabación
            "GRABACIÓN DE PANTALLA": ["GRABACIÓN DE PANTALLA", "SCREEN RECORDING"],
            "Grabando": ["Grabando", "Recording"],
            "Listo para grabar": ["Listo para grabar", "Ready to record"],
            "CARPETA": ["CARPETA", "FOLDER"],
            "Audio del sistema": ["Audio del sistema", "System audio"],
            "Micrófono": ["Micrófono", "Microphone"],
            "Detener grabación": ["Detener grabación", "Stop recording"],
            "Empezar a grabar": ["Empezar a grabar", "Start recording"],
            "Abrir carpeta de grabaciones": ["Abrir carpeta de grabaciones", "Open recordings folder"],
            "Se guarda en": ["Se guarda en", "Saved to"],
            "Cambiar": ["Cambiar", "Change"],
            "Predeterminada": ["Predeterminada", "Default"],
            "Carpeta de grabaciones": ["Carpeta de grabaciones", "Recordings folder"],
            "MODO": ["MODO", "MODE"],
            "Pantalla completa": ["Pantalla completa", "Full screen"],
            "Ventana": ["Ventana", "Window"],
            "Al empezar, hacé clic en la ventana": ["Al empezar, hacé clic en la ventana", "After starting, click the window"]
        })

    function t(clave) {
        const par = cfg.textos[clave];
        if (!par)
            return clave;
        return cfg.esp ? par[0] : par[1];
    }
}
