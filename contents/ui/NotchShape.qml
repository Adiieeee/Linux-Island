pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import "."

// the panel island's outline: a notch hanging from the screen's top edge,
// like a laptop's or an iPhone X's. flat along the top, round bottom corners
// (radius), and at each top corner a concave flare (ear) that curves the
// side out into the screen edge, so the ears take `ear` px on each side of
// the body. CurveRenderer antialiases without layer.enabled (hard rule 3).
//
// it can be tinted with the album art's colours, the way the media card in
// the control center is: three soft blobs in the cover's palette under a
// dark veil that keeps white text readable. each layer is one more
// ShapePath over the same outline, so the colour stays inside the notch's
// curves with no clip or mask (a layer would be needed for that, and
// layer effects crash plasmashell)
Shape {
    id: shp

    property color fill: Theme.surface
    property real radius: Theme.notchCorner
    property real ear: Theme.notchEar
    // flat side at the bottom instead, for a panel on the screen's bottom edge
    property bool flipped: false

    // the cover's three colours (MediaCard.tonos), and how much they show:
    // 0 = plain fill, 1 = tinted like the media card
    property var tones: []
    property real tint: 0

    Behavior on tint {
        NumberAnimation {
            duration: Theme.durLong
            easing.type: Easing.Bezier
            easing.bezierCurve: Theme.emphasizedDecel
        }
    }

    // a body too narrow or short for the full radius gets a smaller one
    readonly property real r: Math.max(0, Math.min(shp.radius, (shp.width - 2 * shp.ear) / 2, shp.height - shp.ear))

    // the outline as SVG path data, shared by every layer. arcs: sweep 1 is
    // clockwise on screen (the ears), 0 counterclockwise (the bottom corners)
    readonly property string outline: {
        const w = shp.width, h = shp.height, e = shp.ear, r = shp.r;
        return `M 0 0 A ${e} ${e} 0 0 1 ${e} ${e} L ${e} ${h - r} A ${r} ${r} 0 0 0 ${e + r} ${h} L ${w - e - r} ${h} A ${r} ${r} 0 0 0 ${w - e} ${h - r} L ${w - e} ${e} A ${e} ${e} 0 0 1 ${w} 0 Z`;
    }

    preferredRendererType: Shape.CurveRenderer
    transform: Scale {
        origin.y: shp.height / 2
        yScale: shp.flipped ? -1 : 1
    }

    // one blob of colour: a radial gradient centred at cx (a fraction of the
    // width), wider than the island so the three blend into one mass. the
    // stops follow the media card's curve, 1 - e^(-1.15·(1 - t²)): it fills
    // most of the blob and only fades to nothing at the edge
    component Blob: ShapePath {
        id: blob
        property real cx: 0.5
        property color tone: Theme.surface
        readonly property real a: shp.tint

        strokeWidth: -1
        fillGradient: RadialGradient {
            centerX: shp.width * blob.cx
            centerY: shp.height / 2
            centerRadius: shp.width * 0.55
            focalX: centerX
            focalY: centerY

            GradientStop {
                position: 0
                color: Qt.alpha(blob.tone, 0.683 * blob.a)
            }
            GradientStop {
                position: 0.25
                color: Qt.alpha(blob.tone, 0.660 * blob.a)
            }
            GradientStop {
                position: 0.5
                color: Qt.alpha(blob.tone, 0.578 * blob.a)
            }
            GradientStop {
                position: 0.75
                color: Qt.alpha(blob.tone, 0.394 * blob.a)
            }
            GradientStop {
                position: 0.9
                color: Qt.alpha(blob.tone, 0.196 * blob.a)
            }
            GradientStop {
                position: 1
                color: Qt.alpha(blob.tone, 0)
            }
        }

        PathSvg {
            path: shp.outline
        }
    }

    ShapePath {
        fillColor: shp.fill
        strokeWidth: -1

        PathSvg {
            path: shp.outline
        }
    }

    Blob {
        cx: 0.15
        tone: shp.tones[0] ?? shp.fill
    }
    Blob {
        cx: 0.85
        tone: shp.tones[1] ?? shp.fill
    }
    Blob {
        cx: 0.5
        tone: shp.tones[2] ?? shp.fill
    }

    // dark veil, as on the media card, so white text stays readable
    ShapePath {
        fillColor: Qt.alpha(Theme.surfaceAlt, 0.45 * shp.tint)
        strokeWidth: -1

        PathSvg {
            path: shp.outline
        }
    }
}
