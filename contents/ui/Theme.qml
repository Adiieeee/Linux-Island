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
    readonly property int islandClock: 13    // the panel island's clock (17 and 15 looked too big)
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
    // following a live value (the waveform's audio level): just enough to
    // smooth the steps between samples
    readonly property int durTick: 70
    // text too long for its space waits this long before sliding, so its
    // start can be read (MarqueeText)
    readonly property int marqueeHold: 700
    // how long the panel island shows a new song's title and artist
    readonly property int peekDuration: 4500
    // how long the pointer rests on the notch before the control center
    // opens: 300 felt slow; 100 still ignores a quick pass across the top
    // of the screen
    readonly property int hoverOpenDelay: 100

    // capas de estado, en monocromo blanco translúcido
    readonly property real stateHover: 0.10
    readonly property real statePressed: 0.16

    // ── medidas de la isla ──
    readonly property int collapsedHeight: 36
    readonly property int expandedHeight: 502
    readonly property int collapsedWidth: 460
    // the panel island's middle while it shows a lyric line instead of the
    // clock; the same for every line, so the island doesn't resize on each
    readonly property int lyricsWidth: 280
    // the panel island is a notch (NotchShape): its bottom corners' radius,
    // and how far the concave flares at its top corners reach out sideways
    readonly property int notchCorner: 14
    readonly property int notchEar: 7
    // a music note in the notch's middle (NoteGlyph: ♪ in a song's
    // instrumental break, ♫ for a song without lyrics): its height, and the
    // middle's width while it shows
    readonly property int noteSize: 9
    readonly property int noteWidth: 20
    // how far above the true centre each part of the panel island sits,
    // tuned by eye on screen. the text and notes first went up 1 px (their
    // ink had more room above than below: ♫ 16 px over 14, text 13 over 12
    // in a 34 px notch), then everything was set part by part
    readonly property int dotsLift: 1     // desktop dots
    readonly property int artLift: 2      // album art
    readonly property int middleLift: 2   // date, lyrics, notes
    readonly property int waveLift: 1     // waveform
    readonly property int clockLift: 1    // clock
    // and the album art this far right of its plain inset
    readonly property int artNudge: 1
    readonly property int expandedWidth: 580
    readonly property int expandedRadius: shapeXl
    // how much of Plasma's popup frame (the theme's translucent, blurred dialog
    // margin, 12 px with Ant-Dark) stays visible around the open island
    readonly property int popupRing: 4
    // corner of the open island (the control center), running parallel to
    // Plasma's dialog frame so the ring above has the same width all the way
    // round. the author's Ant-Dark dialogs/background.svg had a tight
    // "squircle" corner (control points 4 px from the corner), which made the
    // control center look boxy; it was edited to a quarter circle across its
    // 24 px corner tile (see README). the island's corner is the same circle
    // inset by popupRing: radius 20, control points 1 - 0.5523 of the tile
    // from the corner. another Plasma theme has another corner: measure it
    // there and change these two
    readonly property int islandCorner: 24 - popupRing
    readonly property real islandCornerPull: 1 - 0.5523
    readonly property int topGap: 0
}
