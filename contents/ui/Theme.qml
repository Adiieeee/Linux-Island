pragma Singleton

import QtQuick
import "."

// estilo nothing os, no romper estas reglas:
//   1. monocromo estricto: negro, blanco, dos grises. nada más
//   2. rojo solo para estados críticos (temp alta, errores), nunca decorativo
//   3. all text in the system font; labels uppercase with letterspacing
//   4. sin gradientes/sombras/tintes, el contraste hace todo
//   5. pares invertidos (tarjeta blanca+negra) para dar ritmo
QtObject {
    // ── color ──
    // el usuario elige cuatro: fondo, tarjeta, invertida y alerta. los escalones
    // de en medio salen de mezclar esos con el texto, así la rampa queda pareja
    // con cualquier color y no hay que pedirle doce
    readonly property color bg: Cfg.colorFondo         // fondo de la isla
    readonly property color surface: Cfg.colorTarjeta  // tarjetas sobre el fondo
    readonly property color surfaceAlt: mezcla(surface, fg, 0.045)
    readonly property color surfaceHigh: mezcla(surface, fg, 0.098)
    readonly property color surfaceTop: mezcla(surface, fg, 0.143)  // tracks, bordes rellenos

    readonly property color inverted: Cfg.colorInvertida
    // el texto de la tarjeta invertida se decide por brillo, si no desaparece
    // cuando el usuario la deja oscura
    readonly property color invertedFg: brillo(inverted) > 0.5 ? "#000000" : "#FFFFFF"

    readonly property color fg: Cfg.colorTexto
    // text greys, evenly spaced: #B3B3B3 and #808080 with the defaults.
    // fgFaint is the dimmest grey still readable as text (about 5:1 on the
    // default card); outline is for lines and borders only, never for text
    readonly property color fgDim: mezcla(fg, bg, 0.3)
    readonly property color fgFaint: mezcla(fg, bg, 0.5)
    readonly property color outline: mezcla(bg, fg, 0.165)
    // the media card keeps the original dim grey (#9A9A9A with the defaults);
    // the brighter text greys above are not meant for it
    readonly property color mediaDim: mezcla(fg, bg, 0.396)

    // único color del sistema, solo estados críticos
    readonly property color alert: Cfg.colorAlerta

    // interpola dos colores, t va de 0 (a) a 1 (b)
    function mezcla(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    function brillo(c) {
        return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
    }

    // aliases para no reescribir cada módulo, en monocromo todo colapsa a blanco
    readonly property color primary: fg
    readonly property color primaryFg: invertedFg
    readonly property color secondary: fgDim
    readonly property color tertiary: fgDim
    readonly property color error: alert
    readonly property color fgVariant: fgDim
    readonly property color outlineVariant: outline
    readonly property color container: surface
    readonly property color containerLow: surface
    readonly property color containerHigh: surfaceAlt
    readonly property color containerHighest: surfaceHigh
    readonly property color primaryContainer: surfaceAlt
    readonly property color primaryContainerFg: fg

    // ── tipografía ──
    // text follows Plasma's general font (System Settings → Fonts) unless the
    // user picks another one in the widget settings. only the icon font ships
    // inside the widget: without it the icons show up as text ("skip_previous")
    readonly property FontLoader cargaIconos: FontLoader {
        source: Qt.resolvedUrl("../fonts/MaterialSymbolsRounded.ttf")
    }

    readonly property string font: Cfg.fuenteUi || Qt.application.font.family  // interface
    readonly property string fontDots: Cfg.fuenteNumeros || font                // numbers (clock, %, times)

    // tabular figures: every digit is equally wide, so numbers don't jiggle as
    // they change. set it on every Text that uses fontDots
    readonly property var numFeatures: ({
            "tnum": 1
        })

    // esta no se cambia: los iconos son ligaduras de material symbols, con
    // cualquier otra fuente vuelve el nombre en texto
    readonly property string fontIcons: cargaIconos.name

    readonly property int displayLarge: 40   // reloj del panel
    readonly property int displaySmall: 22
    readonly property int titleMedium: 16
    readonly property int titleSmall: 14
    readonly property int bodyMedium: 13
    readonly property int bodySmall: 12
    readonly property int labelMedium: 11
    readonly property int labelSmall: 10

    // etiquetas en mayúsculas y bien separadas
    readonly property real labelSpacing: 1.2

    // ── forma ──
    // círculos para acciones sueltas, píldoras con texto, esquinas generosas
    readonly property int shapeXs: 6
    readonly property int shapeSm: 10
    readonly property int shapeMd: 14
    readonly property int shapeLg: 18
    readonly property int shapeXl: 26

    // ── movimiento ──
    readonly property var emphasized: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var emphasizedDecel: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    readonly property var standard: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]

    readonly property int durShort: 180
    readonly property int durMedium: 280
    readonly property int durLong: 380

    // capas de estado, en monocromo blanco translúcido
    readonly property real stateHover: 0.10
    readonly property real statePressed: 0.16

    // ── medidas de la isla ──
    readonly property int collapsedHeight: 36
    readonly property int expandedHeight: 502
    readonly property int collapsedWidth: 460
    readonly property int expandedWidth: 580
    // se suma a la isla, no reemplaza, así lo de arriba sigue visible
    readonly property int notifStrip: 62
    readonly property int expandedRadius: shapeXl
    readonly property int topGap: 0
}
