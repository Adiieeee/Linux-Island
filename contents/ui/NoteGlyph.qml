pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import "."

// a music note drawn as a vector, for the panel island's middle:
// - "eighth": one eighth note (♪), an instrumental break in a song with lyrics
// - "beamed": two eighth notes joined by one beam (♫), a song without lyrics
// drawn rather than typed: Material Symbols only has music_note, and how ♪
// and ♫ look as text depends on the system font (the Windhawk island this
// follows draws its ♫ for the same reason: Segoe UI gives it a double beam,
// which reads as sixteenths). one SVG path, filled with the winding rule so
// the overlapping head, stem, flag and beam make one shape; CurveRenderer
// antialiases without a layer (hard rule 3)
Shape {
    id: shp

    property string kind: "eighth"
    // height of the drawing; the width follows from it
    property real size: Theme.noteSize
    property color color: Theme.fg

    implicitHeight: shp.size
    implicitWidth: Math.ceil(shp.size * (shp.kind === "beamed" ? 1.03 : 0.83))

    preferredRendererType: Shape.CurveRenderer

    // a note head: an ellipse tilted up to the right, as two half arcs
    function head(cx: real, cy: real): string {
        const h = shp.size, rx = 0.24 * h, ry = 0.17 * h, rot = -20;
        const t = rot * Math.PI / 180;
        const x1 = cx - rx * Math.cos(t), y1 = cy - rx * Math.sin(t);
        const x2 = cx + rx * Math.cos(t), y2 = cy + rx * Math.sin(t);
        return `M ${x1} ${y1} A ${rx} ${ry} ${rot} 1 1 ${x2} ${y2} A ${rx} ${ry} ${rot} 1 1 ${x1} ${y1} Z `;
    }

    // clockwise, like the heads, so the winding rule fills the overlaps
    function rect(x1: real, y1: real, x2: real, y2: real): string {
        return `M ${x1} ${y1} L ${x2} ${y1} L ${x2} ${y2} L ${x1} ${y2} Z `;
    }

    readonly property string glyph: {
        const h = shp.size;
        // the stem rises from the head's right edge
        const stem = 0.085 * h, attach = 0.225 * h;
        if (shp.kind === "beamed") {
            // the second note sits higher, under a beam that rises to match
            const c1x = 0.24 * h, c1y = 0.8 * h, c2x = c1x + 0.56 * h, c2y = c1y - 0.1 * h;
            const s1 = c1x + attach, s2 = c2x + attach;
            const top1 = 0.12 * h, top2 = 0.02 * h, beam = 0.17 * h;
            return shp.head(c1x, c1y) + shp.head(c2x, c2y) + shp.rect(s1 - stem, top1, s1, c1y) + shp.rect(s2 - stem, top2, s2, c2y) + `M ${s1 - stem} ${top1} L ${s2} ${top2} L ${s2} ${top2 + beam} L ${s1 - stem} ${top1 + beam} Z`;
        }
        const cx = 0.26 * h, cy = 0.81 * h, s = cx + attach;
        // the flag: out from the stem's top, curling down to a point
        const flag = `M ${s - stem} 0 L ${s} 0 C ${s + 0.05 * h} ${0.12 * h} ${s + 0.34 * h} ${0.22 * h} ${s + 0.26 * h} ${0.52 * h} C ${s + 0.3 * h} ${0.3 * h} ${s + 0.08 * h} ${0.27 * h} ${s} ${0.3 * h} L ${s - stem} ${0.3 * h} Z`;
        return shp.head(cx, cy) + shp.rect(s - stem, 0, s, cy) + flag;
    }

    ShapePath {
        fillColor: shp.color
        fillRule: ShapePath.WindingFill
        strokeWidth: -1

        PathSvg {
            path: shp.glyph
        }
    }
}
