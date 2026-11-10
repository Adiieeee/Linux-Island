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

    // la franja de la isla muestra la más reciente unos segundos
    property var current: null

    function at(row, role) {
        return root.model.data(root.model.index(row, 0), role);
    }

    readonly property Connections watch: Connections {
        target: root.model

        function onRowsInserted(parent, first) {
            if (root.muted)
                return;
            root.current = {
                summary: root.at(first, NM.Notifications.SummaryRole) ?? "",
                body: root.at(first, NM.Notifications.BodyRole) ?? "",
                icon: root.at(first, NM.Notifications.ApplicationIconNameRole) ?? ""
            };
            root.popupTimer.restart();
        }
    }

    readonly property Timer popupTimer: Timer {
        interval: 5000
        onTriggered: root.current = null
    }

    function dismissAt(row) {
        root.model.close(root.model.index(row, 0));
    }

    // no hay "vaciar todo" en el modelo, se cierra una por una de atrás para adelante
    function clearAll() {
        for (var i = root.model.count - 1; i >= 0; i--)
            root.model.close(root.model.index(i, 0));
        root.current = null;
    }

    function toggleMute() {
        NM.Server.inhibited = !NM.Server.inhibited;
        if (NM.Server.inhibited)
            root.current = null;
    }
}
