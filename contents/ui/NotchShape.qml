import QtQuick
import QtQuick.Shapes
import "."

// the panel island's outline: a notch hanging from the screen's top edge,
// like a laptop's or an iPhone X's. flat along the top, round bottom corners
// (radius), and at each top corner a concave flare (ear) that curves the
// side out into the screen edge, so the ears take `ear` px on each side of
// the body. CurveRenderer antialiases without layer.enabled (hard rule 3)
Shape {
    id: shp

    property color fill: Theme.surface
    property real radius: Theme.notchCorner
    property real ear: Theme.notchEar
    // flat side at the bottom instead, for a panel on the screen's bottom edge
    property bool flipped: false

    // a body too narrow or short for the full radius gets a smaller one
    readonly property real r: Math.max(0, Math.min(shp.radius, (shp.width - 2 * shp.ear) / 2, shp.height - shp.ear))

    preferredRendererType: Shape.CurveRenderer
    transform: Scale {
        origin.y: shp.height / 2
        yScale: shp.flipped ? -1 : 1
    }

    ShapePath {
        fillColor: shp.fill
        strokeWidth: -1
        startX: 0
        startY: 0

        // left ear: from the screen edge down into the body's left side
        PathArc {
            x: shp.ear
            y: shp.ear
            radiusX: shp.ear
            radiusY: shp.ear
            direction: PathArc.Clockwise
        }
        PathLine {
            x: shp.ear
            y: shp.height - shp.r
        }
        PathArc {
            x: shp.ear + shp.r
            y: shp.height
            radiusX: shp.r
            radiusY: shp.r
            direction: PathArc.Counterclockwise
        }
        PathLine {
            x: shp.width - shp.ear - shp.r
            y: shp.height
        }
        PathArc {
            x: shp.width - shp.ear
            y: shp.height - shp.r
            radiusX: shp.r
            radiusY: shp.r
            direction: PathArc.Counterclockwise
        }
        PathLine {
            x: shp.width - shp.ear
            y: shp.ear
        }
        // right ear, back up to the screen edge
        PathArc {
            x: shp.width
            y: 0
            radiusX: shp.ear
            radiusY: shp.ear
            direction: PathArc.Clockwise
        }
        PathLine {
            x: 0
            y: 0
        }
    }
}
