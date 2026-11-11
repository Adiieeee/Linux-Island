pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.private.mpris as Mpris
import "."
import "lrc.js" as Lrc

// synced lyrics for the player the panel island shows (Media.active), looked
// up on lrclib.net with XHR, like Weather: the title never goes through a
// shell, so it needs no escaping.
//
// timing: MPRIS only reports the position when asked (updatePosition) or on
// a seek, so the playhead is the last known position plus the time since,
// times the rate. one single-shot Timer is set for the next moment anything
// changes (a line starts, or is LEAD away), so nothing ticks between lines;
// while lyrics show, the position is asked again every few seconds to stay
// in step
QtObject {
    id: root

    readonly property var player: Media.active
    // off (the setting, or the island's whole player part) = no lookups
    readonly property bool enabled: Cfg.showMini && Cfg.showLyrics
    readonly property bool playing: (root.player?.playbackStatus ?? Mpris.PlaybackStatus.Stopped) === Mpris.PlaybackStatus.Playing
    readonly property real rate: Math.max(0.01, root.player?.rate ?? 1)

    readonly property string track: root.player?.track ?? ""
    readonly property string artist: root.player?.artist ?? ""
    readonly property string album: root.player?.album ?? ""
    readonly property real lengthSec: (root.player?.length ?? 0) / 1000000
    // one song: title + artist. the pill also watches it for its track peek
    readonly property string key: root.track === "" ? "" : root.track + "\u001f" + root.artist

    // this song's lyrics: "idle" (no song, or turned off), "loading" (looking
    // them up or waiting to retry), "found", "none" (instrumental, not on
    // LRCLIB, or no synced version)
    property string status: "idle"
    property var lines: []

    // ── what the pill shows ──
    // wide: there's a line to show now (see Lrc.wantWide)
    property bool wide: false
    // the line on show, its text and when it starts and stops showing
    // (seconds). shown changes last, so a view reacting to it reads the rest
    // already updated, and the same text sung twice still counts as new
    property string text: ""
    property real lineStart: 0
    property real lineEnd: 0
    property int shown: -1

    // ── playhead ──
    property real basePos: 0
    property real baseAt: 0
    property bool basePlaying: false

    function playhead(): real {
        return root.basePos + (root.basePlaying ? (Date.now() - root.baseAt) / 1000 * root.rate : 0);
    }

    function rebase(pos: real): void {
        root.basePos = pos;
        root.baseAt = Date.now();
        root.basePlaying = root.playing;
    }

    // recompute what shows now, and set the timer for the next change
    function refresh(): void {
        root.tick.stop();
        if (root.status !== "found") {
            root.wide = false;
            root.text = "";
            root.shown = -1;
            return;
        }
        const sec = root.playhead();
        root.wide = Lrc.wantWide(root.lines, sec);
        const i = Lrc.shownIndex(root.lines, sec);
        if (i !== root.shown) {
            root.text = i >= 0 ? root.lines[i].text : "";
            root.lineStart = i >= 0 ? root.lines[i].t : 0;
            root.lineEnd = i >= 0 ? Lrc.lineEnd(root.lines, i) : 0;
            root.shown = i;
        }
        if (root.basePlaying) {
            const next = Lrc.nextEvent(root.lines, sec);
            if (next !== Infinity) {
                // a few ms late rather than early, so the line has started
                root.tick.interval = Math.max(30, Math.round((next - sec) / root.rate * 1000) + 5);
                root.tick.start();
            }
        }
    }

    readonly property Timer tick: Timer {
        onTriggered: root.refresh()
    }

    // the extrapolated playhead drifts a little from the player's own clock
    readonly property Timer resync: Timer {
        interval: 5000
        repeat: true
        running: root.status === "found" && root.playing && root.wide
        onTriggered: root.player?.updatePosition()
    }

    readonly property Connections watchPlayer: Connections {
        target: root.player
        // after updatePosition() and after a seek
        function onPositionChanged() {
            root.rebase((root.player?.position ?? 0) / 1000000);
            root.refresh();
        }
        function onRateChanged() {
            root.rebase(root.playhead());
            root.refresh();
        }
    }

    onPlayerChanged: {
        root.rebase((root.player?.position ?? 0) / 1000000);
        root.player?.updatePosition();
        root.refresh();
    }

    // the last known position can be long stale here (it's only fetched
    // when asked), so carry the extrapolated one over, then ask for the real
    onPlayingChanged: {
        root.rebase(root.playhead());
        root.player?.updatePosition();
        root.refresh();
        if (root.playing && root.held) {
            root.held = false;
            root.request(root.asking, root.retryStep);
        }
    }

    // ── lookup ──
    // metadata can arrive in pieces (title first, artist or length a moment
    // later), so wait for it to settle before asking
    readonly property Timer settle: Timer {
        interval: 600
        onTriggered: root.lookup()
    }

    onKeyChanged: {
        // the old song's lookup stops here: its late answers are dropped
        root.stopAsking();
        // not 0: the first key comes with the player, which may be paused
        // halfway through, and a paused player's position doesn't change, so
        // updatePosition() wouldn't correct it. on a real track change the
        // stale value is replaced as soon as the fresh one arrives
        root.rebase((root.player?.position ?? 0) / 1000000);
        root.player?.updatePosition();
        root.status = root.key === "" || !root.enabled ? "idle" : "loading";
        root.lines = [];
        root.refresh();
        root.settle.restart();
    }
    onLengthSecChanged: {
        if (root.status === "loading")
            root.settle.restart();
    }
    onEnabledChanged: root.settle.restart()

    // key → lines, or null for "none". plain data, at most cacheMax songs
    property var cache: ({})
    property var cacheOrder: []
    readonly property int cacheMax: 30

    // the song being looked up, and where a retry picks up
    property string asking: ""
    property int retryStep: 0
    property int attempt: 0
    // a retry that came due while paused, sent when playback resumes
    property bool held: false
    // after a busy server or a network error; then every 20 s while the
    // song lasts
    readonly property var retryDelays: [2000, 5000, 10000, 20000]

    readonly property Timer retry: Timer {
        onTriggered: {
            // the first two retries go out even while paused; later ones wait
            if (!root.playing && root.attempt > 2) {
                root.held = true;
                return;
            }
            root.request(root.asking, root.retryStep);
        }
    }

    function lookup(): void {
        const k = root.key;
        if (!root.enabled || k === "") {
            root.stopAsking();
            root.status = "idle";
            root.lines = [];
            root.refresh();
            return;
        }
        if (k in root.cache) {
            root.stopAsking();
            root.apply(root.cache[k]);
            return;
        }
        // already on it (the length changed while asking)
        if (root.asking === k)
            return;
        root.stopAsking();
        root.asking = k;
        root.status = "loading";
        root.request(k, root.lengthSec > 0 ? 0 : 1);
    }

    function stopAsking(): void {
        root.retry.stop();
        root.asking = "";
        root.attempt = 0;
        root.held = false;
    }

    function apply(found): void {
        root.lines = found ?? [];
        root.status = found ? "found" : "none";
        root.player?.updatePosition();
        root.refresh();
    }

    function store(k: string, found): void {
        if (!(k in root.cache)) {
            root.cacheOrder.push(k);
            if (root.cacheOrder.length > root.cacheMax)
                delete root.cache[root.cacheOrder.shift()];
        }
        root.cache[k] = found;
    }

    function finish(k: string, found): void {
        root.store(k, found);
        if (k !== root.asking)
            return;
        root.stopAsking();
        if (k === root.key)
            root.apply(found);
    }

    // step 0: /api/get with title, artist, album and duration (needs the
    // length); 1: /api/search by title and artist; 2: /api/search with a
    // looser query (Lrc.simplify), for version notes and video titles
    function request(k: string, step: int): void {
        const sep = k.indexOf("\u001f");
        const track = k.slice(0, sep);
        const artist = k.slice(sep + 1);
        const e = encodeURIComponent;
        let url = "https://lrclib.net/api/";
        if (step === 0) {
            url += `get?track_name=${e(track)}&artist_name=${e(artist)}&album_name=${e(root.album)}&duration=${Math.round(root.lengthSec)}`;
        } else if (step === 1) {
            url += `search?track_name=${e(track)}&artist_name=${e(artist)}`;
        } else {
            const loose = Lrc.simplify(track);
            // a video title ("Artist - Song") already names the artist, and
            // the channel's name ("ArtistVEVO") would only get in the way
            url += `search?q=${e(loose.indexOf(" - ") >= 0 ? loose : loose + " " + artist)}`;
        }
        const len = root.lengthSec;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE)
                root.answer(k, step, len, xhr.status, xhr.responseText);
        };
        xhr.open("GET", url);
        xhr.send();
    }

    // only 200 and 404 are answers. LRCLIB often replies 503 or 429 when
    // busy, and caching that as "no lyrics" lost songs it does have
    function answer(k: string, step: int, len: real, status: int, body: string): void {
        if (k !== root.asking)
            return;
        if (status === 200 || status === 404) {
            let data = null;
            if (status === 200) {
                try {
                    data = JSON.parse(body);
                } catch (err) {
                    data = null;
                }
            }
            const found = data ? Lrc.pick(data, len) : null;
            if (found) {
                root.finish(k, found);
                return;
            }
            // LRCLIB knows the song and says there's nothing to sing
            if (step === 0 && data && data.instrumental) {
                root.finish(k, null);
                return;
            }
            if (step < 2)
                root.request(k, step + 1);
            else
                root.finish(k, null);
            return;
        }
        root.retryStep = step;
        root.retry.interval = root.retryDelays[Math.min(root.attempt, root.retryDelays.length - 1)];
        root.attempt++;
        root.retry.start();
    }
}
