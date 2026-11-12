pragma ComponentBehavior: Bound

import QtQuick
import org.kde.taskmanager as TaskManager
import "."

// mismos puntitos que hyprland, leyendo los escritorios virtuales de kwin
// virtualdesktopinfo es de solo lectura, se cambia por dbus directo a kwin
// raíz es Item y no Row: un hijo con anchors adentro de un Row rompe el Row
Item {
    id: root

    // clicking a dot switches to that desktop, the wheel steps through them
    property bool clickable: true
    property bool scrollable: true

    implicitWidth: dots.implicitWidth
    implicitHeight: dots.implicitHeight

    function activate(id) {
        if (!id)
            return;
        // busctl: plain "qdbus" isn't installed on Plasma 6 systems (only qdbus6)
        Exec.run('busctl --user set-property org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager current s "' + id + '"');
    }

    function step(delta) {
        const ids = desktops.desktopIds;
        if (ids.length === 0)
            return;
        let idx = ids.indexOf(desktops.currentDesktop);
        if (idx === -1)
            idx = 0;
        idx = Math.max(0, Math.min(ids.length - 1, idx + delta));
        root.activate(ids[idx]);
    }

    TaskManager.VirtualDesktopInfo {
        id: desktops
    }

    // solo para saber en qué escritorio hay ventanas
    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupDisabled
    }

    readonly property var occupied: {
        const set = {};
        for (var i = 0; i < tasks.count; i++) {
            const vd = tasks.data(tasks.index(i, 0), TaskManager.AbstractTasksModel.VirtualDesktops);
            if (!vd)
                continue;
            for (var j = 0; j < vd.length; j++)
                set[vd[j]] = true;
        }
        return set;
    }

    Row {
        id: dots
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Repeater {
            model: desktops.desktopIds

            Rectangle {
                required property int index
                required property var modelData

                readonly property bool focused: desktops.currentDesktop === modelData
                readonly property bool occupied: root.occupied[modelData] === true

                // all in the text colour, since they sit on the panel and
                // not on the island: greys got lost on a light wallpaper. the
                // shape tells them apart instead: the current desktop is a
                // long pill, one with windows a filled dot, an empty one a ring
                width: focused ? 22 : 8
                height: 8
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                color: focused || occupied ? Theme.fg : Qt.alpha(Theme.fg, 0)
                border.width: 1.5
                border.color: Theme.fg

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }

                // half the row spacing on each side, so neighbouring hit
                // areas meet without overlapping, and taller than the 8 px
                // dot so it's easy to hit
                MouseArea {
                    anchors.fill: parent
                    anchors.leftMargin: -dots.spacing / 2
                    anchors.rightMargin: -dots.spacing / 2
                    anchors.topMargin: -8
                    anchors.bottomMargin: -8
                    enabled: root.clickable
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activate(parent.modelData)
                }
            }
        }
    }

    // rueda sobre toda la fila, sin botones aceptados así los clics siguen llegando a cada punto
    // one step per wheel notch (120 units), not per event: a touchpad sends
    // many small events per swipe and would run through every desktop.
    // same height as a dot's click area
    MouseArea {
        anchors.fill: parent
        anchors.leftMargin: -4
        anchors.rightMargin: -4
        anchors.topMargin: -8
        anchors.bottomMargin: -8
        enabled: root.scrollable
        acceptedButtons: Qt.NoButton

        property real pending: 0

        onWheel: wheel => {
            pending += wheel.angleDelta.y;
            while (Math.abs(pending) >= 120) {
                const up = pending > 0;
                root.step(up ? -1 : 1);
                pending += up ? -120 : 120;
            }
        }
    }
}
