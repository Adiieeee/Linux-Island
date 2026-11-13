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

    // a body with markup comes from Plasma as an XHTML fragment ("<?xml
    // version="1.0"?><html>…"); shown as is, ZapZap's messages read as that
    // code. the island shows plain text: tags dropped, line breaks kept,
    // entities turned back into characters (&amp; last). a body without that
    // wrapper is already plain text and stays as it is ("a < b > c")
    function plain(text): string {
        const s = String(text ?? "");
        if (!/^\s*<\?xml|<html[\s>]/i.test(s))
            return s.trim();
        return s.replace(/<\?xml[^>]*\?>/gi, "").replace(/<br\s*\/?>/gi, "\n").replace(/<\/(p|div|li)>/gi, "\n").replace(/<[^>]*>/g, "").replace(/&nbsp;/g, " ").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&#0*39;|&apos;/g, "'").replace(/&amp;/g, "&").replace(/[ \t]+\n/g, "\n").replace(/\n{3,}/g, "\n\n").trim();
    }

    function capture(row: int): void {
        const id = root.at(row, NM.Notifications.IdRole) ?? 0;
        const summary = root.at(row, NM.Notifications.SummaryRole) ?? "";
        const body = root.plain(root.at(row, NM.Notifications.BodyRole));
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
        const appName = root.at(row, NM.Notifications.ApplicationNameRole) ?? "";
        const desktopEntry = root.at(row, NM.Notifications.DesktopEntryRole) ?? "";
        const created = root.at(row, NM.Notifications.CreatedRole);
        root.history.insert(0, {
            nid: id,
            summary: summary,
            body: body,
            applicationIconName: root.at(row, NM.Notifications.ApplicationIconNameRole) ?? "",
            // the notification's own picture (a chat's sender or group photo),
            // an icon name or a file, when it sends one
            image: root.at(row, NM.Notifications.IconNameRole) ?? "",
            applicationName: appName,
            // the site or extension behind a browser's notification (LINE in
            // Chromium), when the browser says
            originName: root.at(row, NM.Notifications.OriginNameRole) ?? "",
            created: created ? new Date(created).getTime() : Date.now(),
            desktopEntry: desktopEntry,
            // the folder it goes in: one per app
            appKey: appName || desktopEntry || ""
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

    // apps shown under another name in the panel: a wrapper named after
    // its own project rather than the service it opens (ZapZap is
    // WhatsApp). match is tried on the desktop entry and the app's name.
    // logo: a local file, ignored by git (contents/local/), since a brand's
    // logo can't go in the repo; without it the app's own icon shows
    readonly property var aliases: [
        {
            match: /^(com\.rtosta\.)?zapzap/i,
            name: "WhatsApp",
            logo: Qt.resolvedUrl("../local/whatsapp.svg").toString()
        }
    ]

    function alias(appName, desktopEntry) {
        for (const a of root.aliases) {
            if (a.match.test(desktopEntry) || a.match.test(appName))
                return a;
        }
        return null;
    }

    // the history in folders, one per app, the app with the newest
    // notification first: [{ key, name, icon, logo, items: [entry, ...] }],
    // items newest first. plain data, rebuilt whenever the history changes
    property var groups: []

    function regroup(): void {
        const order = [];
        const byKey = {};
        for (let i = 0; i < root.history.count; i++) {
            const e = root.history.get(i);
            const item = {
                nid: e.nid,
                summary: e.summary,
                body: e.body,
                originName: e.originName,
                created: e.created,
                // its own picture, else its app's icon
                picture: e.image || e.applicationIconName
            };
            if (!(e.appKey in byKey)) {
                const a = root.alias(e.applicationName, e.desktopEntry);
                byKey[e.appKey] = {
                    key: e.appKey,
                    name: a ? a.name : e.applicationName,
                    icon: e.applicationIconName,
                    logo: a ? a.logo : "",
                    items: []
                };
                order.push(e.appKey);
            }
            byKey[e.appKey].items.push(item);
        }
        root.groups = order.map(k => byKey[k]);
    }

    readonly property Connections watchHistory: Connections {
        target: root.history
        function onCountChanged() {
            Qt.callLater(root.regroup);
        }
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

    // close Plasma's own copy too, if it still has one
    function closeSource(id: int): void {
        for (let r = 0; r < root.model.count; r++) {
            if (root.at(r, NM.Notifications.IdRole) === id) {
                root.model.close(root.model.index(r, 0));
                return;
            }
        }
    }

    function dismiss(id: int): void {
        for (let i = 0; i < root.history.count; i++) {
            if (root.history.get(i).nid === id) {
                root.history.remove(i);
                break;
            }
        }
        root.closeSource(id);
    }

    // a whole folder
    function dismissApp(key: string): void {
        for (let i = root.history.count - 1; i >= 0; i--) {
            // read before removing: the object get() returns follows the row
            const e = root.history.get(i);
            const id = e.nid;
            if (e.appKey === key) {
                root.history.remove(i);
                root.closeSource(id);
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
