pragma Singleton

import QtQuick
import "."
import org.kde.notificationmanager as NM

// a diferencia de quickshell, acá el shell no es el servidor de notificaciones (eso es plasmashell)
// se lee el mismo historial de plasma, se puede cerrar/vaciar pero no interceptar antes
QtObject {
    id: root

    // silenciar = no molestar de plasma, lo que de verdad corta los avisos
    property bool muted: NM.Server.inhibited

    readonly property NM.Notifications model: NM.Notifications {
        showExpired: true
        showDismissed: true
        showJobs: false
        sortMode: NM.Notifications.SortByDate
        groupMode: NM.Notifications.GroupDisabled
    }

    readonly property int count: model.count

    // no strip of its own for a new notification any more: Plasma's own
    // popups show it. the island only lists the history (NotifPanel)

    function dismissAt(row) {
        root.model.close(root.model.index(row, 0));
    }

    // no hay "vaciar todo" en el modelo, se cierra una por una de atrás para adelante
    function clearAll() {
        for (var i = root.model.count - 1; i >= 0; i--)
            root.model.close(root.model.index(i, 0));
    }

    function toggleMute() {
        NM.Server.inhibited = !NM.Server.inhibited;
    }
}
