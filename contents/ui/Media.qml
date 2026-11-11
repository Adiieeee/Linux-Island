pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.private.mpris as Mpris
import "."

// one MPRIS model for the whole widget. Plasma lists a "multiplexer" row
// (its own pick: the player that's playing, else the last active one) plus
// one row per player (Spotify, a browser tab with YouTube, ...).
// - active: the multiplexer's pick, read from its row. the panel island
//   shows it. the model's currentPlayer isn't used: when player rows arrived
//   before the multiplexer row, currentIndex stayed on whichever player was
//   row 0, and the island showed a paused YouTube while Spotify played
// - cardPlayer: what the control center's media card shows. its arrows step
//   through the players that have something loaded; with nothing picked it
//   follows active
QtObject {
    id: root

    readonly property Mpris.Mpris2Model model: Mpris.Mpris2Model {}

    // one small object per row, kept in sync by the model's roles
    component RowInfo: QtObject {
        required property int index
        required property bool isMultiplexer
        required property var container

        // a player counts once it has a track and is playing or paused. a
        // browser or Spotify open with nothing loaded (or stopped) still
        // has an MPRIS row: counted, it showed the card's arrows next to a
        // lone YouTube video, and they led to an empty "Nothing playing"
        readonly property bool loaded: (container?.track ?? "") !== "" && (container?.playbackStatus ?? Mpris.PlaybackStatus.Stopped) !== Mpris.PlaybackStatus.Stopped
        onLoadedChanged: Qt.callLater(root.rebuild)
    }

    readonly property Instantiator rows: Instantiator {
        model: root.model
        // a row can also get a new container (a player restarted) or turn
        // into the multiplexer row as rows move
        delegate: RowInfo {
            onContainerChanged: Qt.callLater(root.rebuild)
            onIsMultiplexerChanged: Qt.callLater(root.rebuild)
        }
        onObjectAdded: Qt.callLater(root.rebuild)
        onObjectRemoved: Qt.callLater(root.rebuild)
    }

    property RowInfo muxRow: null
    // the players' containers, multiplexer excluded and only the loaded
    // ones, in model order
    property var players: []

    function rebuild(): void {
        let mux = null;
        const list = [];
        for (let i = 0; i < root.rows.count; i++) {
            const r = root.rows.objectAt(i) as RowInfo;
            if (!r)
                continue;
            if (r.isMultiplexer)
                mux = r;
            else if (r.container && r.loaded)
                list.push(r.container);
        }
        root.muxRow = mux;
        root.players = list;
        // a picked player that went away: back to following active
        if (root.picked && list.indexOf(root.picked) < 0)
            root.picked = null;
    }

    readonly property var active: root.muxRow?.container ?? (root.players.length > 0 ? root.players[0] : null)

    // the card's own pick through its arrows; null = follow active
    property var picked: null
    readonly property var cardPlayer: root.picked ?? root.active
    readonly property bool canStep: root.players.length > 1

    function step(direction: int): void {
        const n = root.players.length;
        if (n < 2)
            return;
        let i = root.players.indexOf(root.cardPlayer);
        if (i < 0)
            i = 0;
        const next = root.players[(i + direction + n) % n];
        // stepping back onto the active player follows it again
        root.picked = next === root.active ? null : next;
    }
}
