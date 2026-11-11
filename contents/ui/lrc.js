.pragma library

// synced lyrics (LRC) helpers for Lyrics.qml: plain functions, no QML and no
// network, so they can be tested on their own. a line is { t: seconds,
// text: string }; a line with no words (empty, or only ♪) is a gap: an
// intro, a break between verses or the end of the song

// the pill starts widening this long before a line, so it's open by the time
// the line is sung, and the line shows this much early
var LEAD = 0.3;
// a gap shorter than this between two sung lines keeps the pill wide
// instead of shrinking and growing back within a few seconds
var SHORT_GAP = 4;
// a last line with nothing after it counts as sung for this long
var LAST_HOLD = 6;
// and any other line for at most this long: not every file marks an
// instrumental break with an empty line, and without one the pill would stay
// wide, showing the line before it, through the whole break
var MAX_LINE = 10;

var TAG = /^\[(\d+):(\d{1,2}(?:[.:]\d{1,3})?)\]/;
// word timings in "enhanced" LRC: <00:12.34>
var WORD_TAG = /<\d+:\d{1,2}(?:[.:]\d{1,3})?>/g;

function isGapText(text) {
    return text.replace(/[\s♪♫♬♩]/g, "") === "";
}

// "[mm:ss.xx] text", with several tags on one line allowed
// ("[00:12.00][01:30.00] chorus"). metadata tags such as [ar:...] don't match
// TAG, so those lines are skipped. returns the lines sorted by time
function parse(lrc) {
    const out = [];
    const rows = (lrc || "").split(/\r?\n/);
    for (let r = 0; r < rows.length; r++) {
        let rest = rows[r].trim();
        const times = [];
        let m;
        while ((m = TAG.exec(rest)) !== null) {
            times.push(parseInt(m[1], 10) * 60 + parseFloat(m[2].replace(":", ".")));
            rest = rest.slice(m[0].length);
        }
        if (times.length === 0)
            continue;
        let text = rest.replace(WORD_TAG, "").trim();
        if (isGapText(text))
            text = "";
        for (let i = 0; i < times.length; i++)
            out.push({
                t: times[i],
                text: text
            });
    }
    out.sort((a, b) => a.t - b.t);
    // end a sung line that runs too long with a gap of its own: MAX_LINE in
    // the song, LAST_HOLD for the last one, or the pill would stay wide
    // through the outro
    const lines = [];
    for (let i = 0; i < out.length; i++) {
        lines.push(out[i]);
        if (out[i].text === "")
            continue;
        const last = i + 1 >= out.length;
        const hold = last ? LAST_HOLD : MAX_LINE;
        if (last || out[i + 1].t - out[i].t > hold)
            lines.push({
                t: out[i].t + hold,
                text: ""
            });
    }
    return lines;
}

// whether there's anything to sing at all
function hasWords(lines) {
    for (let i = 0; i < lines.length; i++)
        if (lines[i].text !== "")
            return true;
    return false;
}

// the line playing at `sec`: the last one that started, -1 before the first
function indexAt(lines, sec) {
    let lo = 0, hi = lines.length - 1, found = -1;
    while (lo <= hi) {
        const mid = (lo + hi) >> 1;
        if (lines[mid].t <= sec) {
            found = mid;
            lo = mid + 1;
        } else {
            hi = mid - 1;
        }
    }
    return found;
}

function isGap(lines, i) {
    return i < 0 || i >= lines.length || lines[i].text === "";
}

// whether the pill should be wide at `sec`: a line is sung (or starts within
// LEAD), or a short gap sits between two sung lines. before the first line,
// after the last one and in gaps of SHORT_GAP or more it goes back to the clock
function wantWide(lines, sec) {
    if (!isGap(lines, indexAt(lines, sec + LEAD)))
        return true;
    // a line still being sung keeps it wide even when the lookahead already
    // reaches the gap after it
    const now = indexAt(lines, sec);
    if (!isGap(lines, now))
        return true;
    // in a gap: before the first line, or right after another gap
    if (now < 1 || isGap(lines, now - 1))
        return false;
    let next = now + 1;
    while (next < lines.length && isGap(lines, next))
        next++;
    if (next >= lines.length)
        return false;
    return lines[next].t - lines[now].t < SHORT_GAP;
}

// the line to show while the pill is wide: the one starting within LEAD, or
// in a short gap the last one sung. -1 if there's none
function shownIndex(lines, sec) {
    let i = indexAt(lines, sec + LEAD);
    while (i >= 0 && isGap(lines, i))
        i--;
    return i;
}

// when line i stops showing: the start of whatever follows it
function lineEnd(lines, i) {
    return i + 1 < lines.length ? lines[i + 1].t : lines[i].t + LAST_HOLD;
}

// the next moment after `sec` when wantWide or shownIndex can change: a line
// start or a line start minus LEAD. Infinity when there's none left
function nextEvent(lines, sec) {
    let best = Infinity;
    for (let i = 0; i < lines.length; i++) {
        const early = lines[i].t - LEAD;
        if (early > sec && early < best)
            best = early;
        if (lines[i].t > sec && lines[i].t < best)
            best = lines[i].t;
        // sorted: every later line only comes later
        if (early > sec)
            break;
    }
    return best;
}

// a looser title for a second search: drops version notes such as
// " - Remastered 2011", ' - From "Tangled"/Score', "(feat. X)",
// "(Official Video)" and anything in [brackets]. the part before " - " is
// kept, because in a video title ("Artist - Song") that's half the name
var NOTE = "(?:feat\\.?|ft\\.?|with|from|official|lyrics?|audio|video|mv|hd|hq|live|remaster(?:ed)?|\\d{4} remaster(?:ed)?|version|edit|mix|mono|stereo|acoustic|demo|bonus|deluxe)";
var DASH_NOTE = new RegExp("\\s+-\\s+" + NOTE + "\\b.*$", "i");
var PAREN_NOTE = new RegExp("\\s*\\(" + NOTE + "\\b[^)]*\\)", "gi");

function simplify(title) {
    return (title || "").replace(/\s*\[[^\]]*\]/g, "").replace(PAREN_NOTE, "").replace(DASH_NOTE, "").replace(/\s+/g, " ").trim();
}

// from LRCLIB answers (one object from /api/get, an array from /api/search):
// the first with synced lyrics whose duration is within 3 s of the track's
// (any duration when the track's is unknown). null when none fits
function pick(results, lengthSec) {
    const list = Array.isArray(results) ? results : (results ? [results] : []);
    for (let i = 0; i < list.length; i++) {
        const r = list[i];
        if (!r || r.instrumental || !r.syncedLyrics)
            continue;
        if (lengthSec > 0 && r.duration > 0 && Math.abs(r.duration - lengthSec) > 3)
            continue;
        const lines = parse(r.syncedLyrics);
        if (hasWords(lines))
            return lines;
    }
    return null;
}
