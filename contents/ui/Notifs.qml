pragma Singleton

import QtQuick
import "."
import org.kde.notificationmanager as NM

// a diferencia de quickshell, acá el shell no es el servidor de notificaciones (eso es plasmashell)
// se lee el mismo historial de plasma, se puede cerrar/vaciar pero no interceptar antes
//
// the island keeps its own copy of every notification (history), because
// Plasma's history loses many: when the app that sent a notification closes
// it (CloseNotification), Plasma removes it from its model altogether. chat
// apps do that all the time (ZapZap and LINE in Chromium close theirs once
// the message is read, or replace them), so their messages never showed in
// the island. each notification is copied as it arrives and stays until
// it's dismissed or cleared here
QtObject {
    id: root

    // silenciar = no molestar de plasma, lo que de verdad corta los avisos
    property bool muted: NM.Server.inhibited

    // Plasma's notifications, the source. every urgency and the ones that
    // arrived during Do Not Disturb, so nothing is filtered out before it's
    // copied
    readonly property NM.Notifications model: NM.Notifications {
        showExpired: true
        showDismissed: true
        showJobs: false
        showAddedDuringInhibition: true
        urgencies: NM.Notifications.LowUrgency | NM.Notifications.NormalUrgency | NM.Notifications.CriticalUrgency
        sortMode: NM.Notifications.SortByDate
        groupMode: NM.Notifications.GroupDisabled
    }

    // the island's copy, newest first. same role names as Plasma's model,
    // so NotifPanel's delegates read them the same way
    readonly property ListModel history: ListModel {}
    readonly property int count: history.count
    // oldest copies beyond this are dropped
    readonly property int limit: 100

    // id → "summary\u001fbody" last copied, plain data. a row that changes
    // without new content (it expired, was read, was closed) is left alone;
    // one whose text changed (a chat app's "2 new messages", same id) is
    // copied again, even if its older copy was dismissed
    property var seen: ({})
    property int seenCount: 0

    function at(row, role) {
        return root.model.data(root.model.index(row, 0), role);
    }

    function capture(row: int): void {
        const id = root.at(row, NM.Notifications.IdRole) ?? 0;
        const summary = root.at(row, NM.Notifications.SummaryRole) ?? "";
        const body = root.at(row, NM.Notifications.BodyRole) ?? "";
        const key = summary + "\u001f" + body;
        if (id && root.seen[id] === key)
            return;
        if (id) {
            if (!(id in root.seen))
                root.seenCount++;
            root.seen[id] = key;
        }
        // the same notification updated in place: its older copy goes, the
        // new text goes on top
        if (id) {
            for (let i = 0; i < root.history.count; i++) {
                if (root.history.get(i).nid === id) {
                    root.history.remove(i);
                    break;
                }
            }
        }
        root.history.insert(0, {
            nid: id,
            summary: summary,
            body: body,
            applicationIconName: root.at(row, NM.Notifications.ApplicationIconNameRole) ?? "",
            applicationName: root.at(row, NM.Notifications.ApplicationNameRole) ?? ""
        });
        if (root.history.count > root.limit)
            root.history.remove(root.limit, root.history.count - root.limit);
        // keep the id map from growing for ever: only what's still listed
        if (root.seenCount > 4 * root.limit) {
            const keep = {};
            for (let i = 0; i < root.history.count; i++) {
                const e = root.history.get(i);
                keep[e.nid] = e.summary + "\u001f" + e.body;
            }
            root.seen = keep;
            root.seenCount = root.history.count;
        }
    }

    // copy several rows, oldest first, so the newest ends on top whatever
    // order the model keeps them in
    function captureRows(first: int, last: int): void {
        const rows = [];
        for (let r = first; r <= last; r++) {
            const created = root.at(r, NM.Notifications.CreatedRole);
            rows.push({
                row: r,
                t: created ? new Date(created).getTime() : 0
            });
        }
        rows.sort((a, b) => a.t - b.t);
        for (const e of rows)
            root.capture(e.row);
    }

    readonly property Connections watch: Connections {
        target: root.model

        function onRowsInserted(parent, first, last) {
            root.captureRows(first, last);
        }

        function onDataChanged(topLeft, bottomRight) {
            for (let r = topLeft.row; r <= bottomRight.row; r++)
                root.capture(r);
        }
    }

    // what Plasma already had when plasmashell started
    Component.onCompleted: Qt.callLater(() => {
        if (root.model.count > 0)
            root.captureRows(0, root.model.count - 1);
    })

    function dismissAt(row: int): void {
        const id = root.history.get(row).nid;
        root.history.remove(row);
        // and from Plasma's history, if it's still there
        for (let r = 0; r < root.model.count; r++) {
            if (root.at(r, NM.Notifications.IdRole) === id) {
                root.model.close(root.model.index(r, 0));
                break;
            }
        }
    }

    // no hay "vaciar todo" en el modelo, se cierra una por una de atrás para adelante
    function clearAll() {
        root.history.clear();
        for (var i = root.model.count - 1; i >= 0; i--)
            root.model.close(root.model.index(i, 0));
    }

    function toggleMute() {
        NM.Server.inhibited = !NM.Server.inhibited;
    }
}
