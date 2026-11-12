pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NM
import "."

// bandeja de notificaciones: todas las que llegaron, silencio y vaciar
Item {
    id: popup

    signal closed

    implicitHeight: col.implicitHeight + 44

    readonly property int count: Notifs.count
    // the list scrolls past this height
    readonly property int listMax: 300

    // the folders opened (app key → true), reassigned so bindings see it
    property var openApps: ({})

    function toggle(key: string): void {
        const next = Object.assign({}, popup.openApps);
        next[key] = !next[key];
        popup.openApps = next;
    }

    // "09:41" today, "11 Nov" before
    function when(ms: real): string {
        const d = new Date(ms);
        const today = new Date();
        if (d.toDateString() === today.toDateString())
            return Qt.formatDateTime(d, "HH:mm");
        return Cfg.locale.toString(d, "d MMM");
    }

    // one notification, or a folder's own row
    component Entry: Rectangle {
        id: entry

        property string icon: ""
        property string title: ""
        property string text: ""
        property string detail: ""
        property int lines: 2
        property int badge: 0
        property bool indent: false
        property bool expandable: false
        property bool expanded: false
        signal activated
        signal dismissed

        width: parent ? parent.width : 0
        height: Math.max(52, texts.implicitHeight + 16)
        radius: Theme.shapeMd
        color: entryMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)

        Behavior on color {
            ColorAnimation {
                duration: Theme.durShort
            }
        }

        Kirigami.Icon {
            id: entryIcon
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 26
            implicitHeight: 26
            source: entry.icon
            visible: !entry.indent && entry.icon !== ""
        }

        Text {
            anchors.centerIn: entryIcon
            visible: !entry.indent && entry.icon === ""
            text: "notifications"
            color: Theme.fgFaint
            font.family: Theme.fontIcons
            font.pixelSize: 20
        }

        Column {
            id: texts
            anchors.left: parent.left
            // inside an open folder there's no icon, but the text stays
            // lined up with the folder's
            anchors.leftMargin: 46
            anchors.right: tail.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Item {
                width: parent.width
                height: titleText.implicitHeight

                Text {
                    id: titleText
                    anchors.left: parent.left
                    anchors.right: detailText.left
                    anchors.rightMargin: detailText.text !== "" ? 8 : 0
                    text: entry.title
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.bodySmall
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    id: detailText
                    anchors.right: parent.right
                    anchors.baseline: titleText.baseline
                    width: Math.min(implicitWidth, parent.width * 0.45)
                    text: entry.detail
                    color: Theme.fgFaint
                    font.family: Theme.fontDots
                    font.features: Theme.numFeatures
                    font.pixelSize: Theme.labelSmall
                    elide: Text.ElideLeft
                }
            }

            Text {
                width: parent.width
                text: entry.text
                color: Theme.fgVariant
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                wrapMode: Text.Wrap
                maximumLineCount: entry.lines
                elide: Text.ElideRight
                visible: text !== ""
            }
        }

        MouseArea {
            id: entryMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: entry.expandable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: entry.activated()
        }

        // the count and the arrow on a folder, then the dismiss cross
        Row {
            id: tail
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: entry.badge > 0
                width: Math.max(20, badgeText.implicitWidth + 10)
                height: 18
                radius: height / 2
                color: Theme.surfaceHigh

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: entry.badge
                    color: Theme.fg
                    font.family: Theme.fontDots
                    font.features: Theme.numFeatures
                    font.pixelSize: Theme.labelSmall
                    font.weight: Font.Medium
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: entry.expandable
                text: entry.expanded ? "expand_less" : "expand_more"
                color: Theme.fgDim
                font.family: Theme.fontIcons
                font.pixelSize: 18
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "close"
                color: dismissMa.containsMouse ? Theme.fg : Theme.fgFaint
                font.family: Theme.fontIcons
                font.pixelSize: 16

                MouseArea {
                    id: dismissMa
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: entry.dismissed()
                }
            }
        }
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 10

        // ── barra de título ──
        Item {
            width: parent.width
            height: 26

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Cfg.t("NOTIFICACIONES")
                color: Theme.fgFaint
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                font.letterSpacing: Theme.labelSpacing
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 26
                radius: height / 2
                color: closeMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "close"
                    color: closeMa.containsMouse ? Theme.fg : Theme.fgDim
                    font.family: Theme.fontIcons
                    font.pixelSize: 15
                }

                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.closed()
                }
            }
        }

        // ── silencio + vaciar ──
        Row {
            width: parent.width
            spacing: 8

            // tarjeta invertida cuando el silencio está puesto
            Rectangle {
                width: (parent.width - 8) * 0.62
                height: 46
                radius: Theme.shapeLg
                color: Notifs.muted ? Theme.inverted : muteMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durMedium
                    }
                }

                Text {
                    id: muteIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifs.muted ? "notifications_off" : "notifications"
                    color: Notifs.muted ? Theme.invertedFg : Theme.fgDim
                    font.family: Theme.fontIcons
                    font.pixelSize: 19
                }

                Text {
                    anchors.left: muteIcon.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifs.muted ? Cfg.t("SILENCIADAS") : Cfg.t("SILENCIAR")
                    color: Notifs.muted ? Theme.invertedFg : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.bodySmall
                    font.weight: Font.Medium
                    font.letterSpacing: Theme.labelSpacing
                }

                MouseArea {
                    id: muteMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.toggleMute()
                }
            }

            Rectangle {
                width: (parent.width - 8) * 0.38
                height: 46
                radius: Theme.shapeLg
                // as bright as MUTE next to it, also with nothing to clear (then
                // it just doesn't react): at 40% opacity it looked switched off
                color: clearMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }

                Text {
                    id: clearIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "delete_sweep"
                    color: Theme.fgDim
                    font.family: Theme.fontIcons
                    font.pixelSize: 19
                }

                Text {
                    anchors.left: clearIcon.right
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: Cfg.t("VACIAR")
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.bodySmall
                    font.weight: Font.Medium
                    font.letterSpacing: Theme.labelSpacing
                }

                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: popup.count > 0
                    onClicked: Notifs.clearAll()
                }
            }
        }

        Text {
            text: popup.count + " " + Cfg.t("EN LA BANDEJA")
            color: Theme.fgFaint
            font.family: Theme.font
            font.pixelSize: Theme.labelSmall
            font.weight: Font.Medium
            font.letterSpacing: 0.6
            visible: popup.count > 0
        }

        // ── lista ──
        // the island's own copy of the notifications, one folder per app
        // (Notifs.groups): an app with several shows one row with its newest
        // and a count, and opens to list them all; an app with one shows it
        // straight away. it scrolls (wheel or drag) past listMax, like the
        // Wi-Fi list. bodies get two lines and each row its time, and a
        // browser's notification the site behind it (LINE in Chromium)
        Item {
            width: parent.width
            height: Math.min(popup.listMax, lista.contentHeight)
            visible: popup.count > 0

            Flickable {
                id: lista
                anchors.fill: parent
                contentHeight: dentro.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 3500

                Column {
                    id: dentro
                    // room for the scroll bar
                    width: lista.width - 8
                    spacing: 2

                    Repeater {
                        model: Notifs.groups

                        Column {
                            id: group
                            required property var modelData
                            readonly property bool folder: modelData.items.length > 1
                            readonly property bool open: folder && popup.openApps[modelData.key] === true

                            width: dentro.width
                            spacing: 2

                            // the folder's own row: the app, how many, the newest
                            Entry {
                                visible: group.folder
                                icon: group.modelData.icon
                                title: group.modelData.name || Cfg.t("OTRA")
                                text: group.modelData.items[0].summary + (group.modelData.items[0].body !== "" ? " · " + group.modelData.items[0].body : "")
                                detail: popup.when(group.modelData.items[0].created)
                                lines: 1
                                badge: group.modelData.items.length
                                expandable: true
                                expanded: group.open
                                onActivated: popup.toggle(group.modelData.key)
                                onDismissed: Notifs.dismissApp(group.modelData.key)
                            }

                            Repeater {
                                model: !group.folder || group.open ? group.modelData.items : []

                                Entry {
                                    required property var modelData
                                    // inside an open folder: no icon, indented
                                    indent: group.folder
                                    icon: group.folder ? "" : group.modelData.icon
                                    title: modelData.summary || group.modelData.name
                                    text: modelData.body
                                    detail: (modelData.originName !== "" && modelData.originName !== group.modelData.name ? modelData.originName + " · " : "") + popup.when(modelData.created)
                                    onDismissed: Notifs.dismiss(modelData.nid)
                                }
                            }
                        }
                    }
                }
            }

            // where the list is, while it's longer than the space
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 1
                width: 3
                radius: 1.5
                color: Theme.fgFaint

                visible: lista.contentHeight > lista.height
                height: Math.max(24, lista.height * (lista.height / lista.contentHeight))
                y: (lista.contentHeight <= lista.height) ? 0 : (lista.contentY / (lista.contentHeight - lista.height)) * (lista.height - height)

                opacity: lista.moving ? 0.9 : 0.25
                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durMedium
                    }
                }
            }
        }

        // ── bandeja vacía ──
        Column {
            width: parent.width
            spacing: 8
            visible: popup.count === 0
            topPadding: 16
            bottomPadding: 16

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "notifications_none"
                color: Theme.fgFaint
                font.family: Theme.fontIcons
                font.pixelSize: 34
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Cfg.t("SIN NOTIFICACIONES")
                color: Theme.fgFaint
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
                font.weight: Font.Medium
                font.letterSpacing: Theme.labelSpacing
            }
        }
    }
}
