import QtQuick
import QtQuick.Window
import org.kde.plasma.private.brightnesscontrolplugin as BC
import org.kde.plasma.private.volume as PA
import "."

// full-width sliders for sound and brightness. a long track is easier to
// drag precisely than the small bar the sound card used to have
Rectangle {
    id: root

    // the island listens to this to open the matching overlay
    signal requestPanel(string mode)

    // same backend as Plasma's brightness applet: talks to PowerDevil over
    // DBus in-process and updates live, so nothing gets polled.
    // isSilent: no brightness OSD while dragging, the slider already shows it
    BC.ScreenBrightnessControl {
        id: screens
        isSilent: true
    }

    // KDE's own audio models (plasma-pa): live, no polling. declared here with
    // an id, not inline as a Repeater model, so the GC never owns them.
    // the main volume row still goes through Audio (wpctl)
    PA.SinkModel {
        id: paSinks
    }
    PA.SourceModel {
        id: paSources
    }

    implicitHeight: rows.implicitHeight + 20
    radius: Theme.shapeLg
    color: Theme.containerHigh

    // which dropdown is open: "", "sound", "screens"
    property string menu: ""

    // ── which display is "main": the one the island is on ──
    // the popup window sits on the panel's screen. the built-in panel is
    // eDP/LVDS/DSI; an external monitor matches by model, which Qt and
    // PowerDevil report the same way ("24G2W1G3-")
    readonly property bool hereInternal: /^(eDP|LVDS|DSI)/.test(Screen.name)
    readonly property string hereModel: Screen.model

    // bumped whenever probe gains or loses a row, so mainScreen re-evaluates
    property int screensRev: 0

    // displayName of the row shown up front: the island's screen, else the
    // built-in panel, else the first one. the others go in the dropdown
    readonly property string mainScreen: {
        root.screensRev;
        let here = "", internal = "", first = "";
        for (let i = 0; i < probe.count; i++) {
            const d = probe.itemAt(i);
            if (!d)
                continue;
            if (!first)
                first = d.key;
            if (d.internal && !internal)
                internal = d.key;
            if (!here && (root.hereInternal ? d.internal : d.label === root.hereModel))
                here = d.key;
        }
        return here || internal || first;
    }

    function setScreenLevel(key, value) {
        screens.setBrightness(key, value);
    }

    // invisible copy of the display list, only to pick mainScreen
    Repeater {
        id: probe
        model: screens.isBrightnessAvailable ? screens.displays : null
        delegate: Item {
            readonly property string key: model.displayName
            readonly property string label: model.label
            readonly property bool internal: model.isInternal
        }
        onItemAdded: root.screensRev++
        onItemRemoved: root.screensRev++
    }

    function toggle(name) {
        root.menu = root.menu === name ? "" : name;
    }

    // all label columns are as wide as the widest label, so the tracks line
    // up. walks into the dropdowns too, so opening one doesn't shift anything
    readonly property real labelWidth: Math.min(root.widestLabel(rows), 110)

    function widestLabel(item) {
        let w = 0;
        for (let i = 0; i < item.children.length; i++) {
            const c = item.children[i];
            if (c.labelImplicitWidth !== undefined)
                w = Math.max(w, c.labelImplicitWidth);
            else
                w = Math.max(w, root.widestLabel(c));
        }
        return w;
    }

    // a device worth listing: real hardware whose active port is connected.
    // virtual sinks (Easy Effects…) only when they are the default
    function usable(dev) {
        if (!dev)
            return false;
        if (dev.virtualDevice && !dev.default)
            return false;
        const port = dev.ports[dev.activePortIndex];
        return !port || port.availability !== PA.Port.Unavailable;
    }

    // "HDA NVidia Digital Stereo (HDMI) [24G2W1G3-]" → "24G2W1G3",
    // "Alder Lake … Controller Headphones" → "Headphones", bluetooth names as they are
    function deviceName(dev) {
        const desc = dev?.description ?? "";
        const bracket = desc.match(/\[(.+?)\]\s*$/);
        if (bracket)
            return bracket[1].replace(/[-\s]+$/, "");
        const port = dev?.ports[dev.activePortIndex]?.description ?? "";
        if (port && desc.endsWith(port))
            return port;
        return desc || Cfg.t("Desconocido");
    }

    function deviceIcon(dev, input) {
        const name = dev?.name ?? "";
        const text = (dev?.description ?? "") + " " + (dev?.ports[dev.activePortIndex]?.description ?? "");
        if (name.startsWith("bluez"))
            return input ? "headset_mic" : "earbuds";
        if (input)
            return "mic";
        if (/HDMI|DisplayPort/i.test(text))
            return "tv";
        if (/Headphone|Headset/i.test(text))
            return "headphones";
        return "speaker";
    }

    TextMetrics {
        id: valueMetrics
        font.family: Theme.fontDots
        font.features: Theme.numFeatures
        font.pixelSize: Theme.bodySmall
        font.weight: Font.Medium
        text: "150%"
    }

    // icon · label · track with knob · value
    component SliderRow: Item {
        id: row

        property string icon
        property color iconColor: Theme.fgVariant
        property string label
        property string valueText
        property color valueColor: Theme.fg

        // position on the track, 0..1
        property real value: 0
        // past this point the fill turns red (volume boost). 1 = never
        property real boostFrom: 1
        property color fillColor: Theme.fg
        // thin tick on the track at boostFrom, so 100% is easy to find
        property bool showMark: false
        property bool iconClickable: true
        // a clickable label lights up on hover. by default it gets a chevron
        // and opens a dropdown; device rows use a check for the selected one
        property bool labelClickable: false
        property bool expanded: false
        property bool selected: false
        property string labelIcon: row.labelClickable ? "expand_more" : ""
        // keep room for the icon even while it's hidden, so widths don't jump
        property bool reserveLabelIcon: row.labelIcon !== ""
        readonly property int labelIconSpace: 18

        // left button only: a right-click opens a panel, it doesn't drag
        readonly property bool pressed: dragArea.pressed && (dragArea.pressedButtons & Qt.LeftButton) !== 0
        readonly property real labelImplicitWidth: labelText.implicitWidth + (row.reserveLabelIcon ? row.labelIconSpace : 0)

        signal moved(real fraction)
        signal stepped(int direction)
        signal iconClicked
        signal labelClicked
        signal rightClicked

        width: parent ? parent.width : 0
        height: 30

        Text {
            id: iconText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            horizontalAlignment: Text.AlignHCenter
            text: row.icon
            color: row.iconColor
            font.family: Theme.fontIcons
            font.pixelSize: 18

            MouseArea {
                anchors.fill: parent
                anchors.margins: -5
                cursorShape: row.iconClickable ? Qt.PointingHandCursor : Qt.ArrowCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        row.rightClicked();
                    else
                        row.iconClicked();
                }
            }
        }

        Item {
            id: labelBox
            anchors.left: iconText.right
            anchors.leftMargin: 10
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.labelWidth

            readonly property bool lit: row.selected || (row.labelClickable && (row.expanded || labelMa.containsMouse))

            Text {
                id: labelText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, parent.width - (row.reserveLabelIcon ? row.labelIconSpace : 0))
                text: row.label
                color: labelBox.lit ? Theme.fg : Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                font.letterSpacing: Theme.labelSpacing
                elide: Text.ElideRight

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }
            }

            Text {
                id: chevron
                anchors.left: labelText.right
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                visible: row.labelIcon !== ""
                text: row.labelIcon
                color: labelText.color
                font.family: Theme.fontIcons
                font.pixelSize: 16
                rotation: row.expanded && row.labelIcon === "expand_more" ? 180 : 0

                Behavior on rotation {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }
            }

            MouseArea {
                id: labelMa
                anchors.fill: parent
                enabled: row.labelClickable
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: row.labelClicked()
            }
        }

        Text {
            id: valueText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: valueMetrics.advanceWidth
            horizontalAlignment: Text.AlignRight
            text: row.valueText
            color: row.valueColor
            font.family: Theme.fontDots
            font.features: Theme.numFeatures
            font.pixelSize: Theme.bodySmall
            font.weight: Font.Medium
        }

        Item {
            id: trackArea
            anchors.left: labelBox.right
            anchors.leftMargin: 12
            anchors.right: valueText.left
            anchors.rightMargin: 14
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            readonly property real fillTo: Math.max(0, Math.min(1, row.value))

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                radius: 3
                color: Theme.containerHighest

                Rectangle {
                    width: track.width * Math.min(trackArea.fillTo, row.boostFrom)
                    height: parent.height
                    radius: parent.radius
                    color: row.fillColor

                    Behavior on width {
                        enabled: !dragArea.pressed
                        NumberAnimation {
                            duration: Theme.durShort
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Theme.emphasized
                        }
                    }
                }

                // boost: from boostFrom up to the value, in red
                Rectangle {
                    x: track.width * row.boostFrom
                    width: track.width * Math.max(0, trackArea.fillTo - row.boostFrom)
                    height: parent.height
                    radius: parent.radius
                    color: Theme.alert
                    visible: width > 0
                }

                Rectangle {
                    visible: row.showMark
                    x: track.width * row.boostFrom - 1
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: 10
                    radius: 1
                    color: Theme.outline
                }
            }

            Rectangle {
                id: knob
                anchors.verticalCenter: parent.verticalCenter
                x: track.width * trackArea.fillTo - width / 2
                width: dragArea.pressed || dragArea.containsMouse ? 16 : 12
                height: width
                radius: width / 2
                color: trackArea.fillTo > row.boostFrom ? Theme.alert : row.fillColor

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durShort
                    }
                }
                Behavior on x {
                    enabled: !dragArea.pressed
                    NumberAnimation {
                        duration: Theme.durShort
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }
            }

            // the whole row height is grabbable, not just the 6 px track
            MouseArea {
                id: dragArea
                anchors.fill: parent
                anchors.leftMargin: -6
                anchors.rightMargin: -6
                hoverEnabled: true
                preventStealing: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                function apply(mx) {
                    row.moved(Math.max(0, Math.min(1, (mx - 6) / track.width)));
                }

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        row.rightClicked();
                }
                onPressed: mouse => {
                    if (mouse.button === Qt.LeftButton)
                        apply(mouse.x);
                }
                onPositionChanged: mouse => {
                    if (pressed && (mouse.buttons & Qt.LeftButton))
                        apply(mouse.x);
                }
                onWheel: wheel => row.stepped(wheel.angleDelta.y > 0 ? 1 : -1)
            }
        }
    }

    // brightness of one display. the model only updates after PowerDevil
    // confirms (slower over DDC for external monitors), so the row shows the
    // requested level while dragging and for a moment after, or the knob
    // would bounce back
    component ScreenRow: SliderRow {
        id: sr

        property string key
        property int brightness
        property int maxBrightness
        readonly property real level: sr.maxBrightness > 0 ? sr.brightness / sr.maxBrightness : 0
        property real wanted: 0

        function request(f) {
            // never fully black: 0 switches some backlights off
            sr.wanted = Math.max(0.01, Math.min(1, f));
            settle.restart();
            root.setScreenLevel(sr.key, Math.round(sr.wanted * sr.maxBrightness));
        }

        Timer {
            id: settle
            interval: 1000
        }

        icon: "light_mode"
        iconClickable: false
        value: sr.pressed || settle.running ? sr.wanted : sr.level
        valueText: Math.round(sr.value * 100) + "%"

        onMoved: f => sr.request(f)
        onStepped: d => sr.request(sr.value + d * 0.05)
    }

    // small uppercase heading inside a dropdown
    component SectionLabel: Text {
        width: parent ? parent.width : 0
        topPadding: 2
        bottomPadding: 2
        color: Theme.fgFaint
        font.family: Theme.font
        font.pixelSize: Theme.labelSmall
        font.letterSpacing: Theme.labelSpacing
    }

    // thin line that sets a dropdown apart from the rows around it
    component Divider: Item {
        width: parent ? parent.width : 0
        height: 11

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 1
            color: Theme.outline
        }
    }

    // one audio device with its own level, like KDE's audio applet.
    // click the name to make it the default (a check marks the current one),
    // click the icon to mute it. dev is owned by plasma-pa's model, not by JS
    component DeviceSlider: SliderRow {
        id: ds

        property QtObject dev
        property bool isInput: false
        // outputs go to 150% like the main row, inputs stop at 100%
        property real maxLevel: ds.isInput ? 1 : 1.5

        readonly property bool devMuted: ds.dev ? ds.dev.muted : false
        readonly property real level: ds.dev ? ds.dev.volume / PA.PulseAudio.NormalVolume : 0

        function setLevel(v) {
            if (!ds.dev)
                return;
            if (ds.dev.muted)
                ds.dev.muted = false;
            ds.dev.volume = Math.round(Math.max(0, Math.min(ds.maxLevel, v)) * PA.PulseAudio.NormalVolume);
        }

        icon: root.deviceIcon(ds.dev, ds.isInput)
        iconColor: ds.devMuted ? Theme.outline : ds.level > 1 ? Theme.alert : ds.selected ? Theme.fg : Theme.fgVariant
        label: root.deviceName(ds.dev).toUpperCase()
        selected: ds.dev ? ds.dev.default : false
        labelClickable: !ds.selected
        labelIcon: ds.selected ? "check" : ""
        reserveLabelIcon: true
        value: ds.level / ds.maxLevel
        boostFrom: 1 / ds.maxLevel
        showMark: ds.maxLevel > 1
        fillColor: ds.devMuted ? Theme.outline : Theme.fg
        valueText: Math.round(ds.level * 100) + "%"
        valueColor: ds.devMuted ? Theme.outline : ds.level > 1 ? Theme.alert : Theme.fg

        onMoved: f => ds.setLevel(f * ds.maxLevel)
        onStepped: d => ds.setLevel(ds.level + d * 0.05)
        onIconClicked: ds.dev.muted = !ds.devMuted
        onLabelClicked: ds.dev.default = true
    }

    Column {
        id: rows
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 4

        // ── sound: real ceiling 150%, past 100% the fill turns red ──
        SliderRow {
            icon: Audio.muted ? "volume_off" : "volume_up"
            iconColor: Audio.muted ? Theme.outline : Audio.boosted ? Theme.alert : Theme.fgVariant
            label: Cfg.t("SONIDO")
            labelClickable: true
            expanded: root.menu === "sound"
            value: Audio.volume / Audio.maxVolume
            boostFrom: 1 / Audio.maxVolume
            showMark: true
            // muted keeps the level visible, just dimmed
            fillColor: Audio.muted ? Theme.outline : Theme.fg
            valueText: Audio.percent + "%"
            valueColor: Audio.muted ? Theme.outline : Audio.boosted ? Theme.alert : Theme.fg

            // the 1 s poll would overwrite the value mid-drag and make it jump
            onPressedChanged: Audio.holding = pressed
            onMoved: f => Audio.setVolume(f * Audio.maxVolume)
            onStepped: d => Audio.step(d * 0.05)
            onIconClicked: Audio.toggleMute()
            onLabelClicked: root.toggle("sound")
            onRightClicked: root.requestPanel("audio")
        }

        // ── sound dropdown: every output and input with its own level ──
        Column {
            width: parent.width
            visible: root.menu === "sound"

            Divider {}

            SectionLabel {
                text: Cfg.t("SALIDA")
            }

            Repeater {
                model: paSinks
                delegate: DeviceSlider {
                    visible: root.usable(model.PulseObject)
                    dev: model.PulseObject
                }
            }

            SectionLabel {
                topPadding: 6
                text: Cfg.t("ENTRADA")
            }

            Repeater {
                model: paSources
                delegate: DeviceSlider {
                    visible: root.usable(model.PulseObject)
                    dev: model.PulseObject
                    isInput: true
                }
            }

            // sets the dropdown apart from the brightness row below
            Divider {}
        }

        // ── brightness: the island's own screen up front ──
        Repeater {
            model: screens.isBrightnessAvailable ? screens.displays : null

            delegate: ScreenRow {
                visible: key === root.mainScreen
                key: model.displayName
                brightness: model.brightness
                maxBrightness: model.maxBrightness
                label: Cfg.t("BRILLO")
                labelClickable: probe.count > 1
                expanded: root.menu === "screens"
                onLabelClicked: root.toggle("screens")
            }
        }

        // ── brightness dropdown: every other screen ──
        Column {
            width: parent.width
            visible: root.menu === "screens"

            // sets the island's own screen apart from the others
            Divider {}

            Repeater {
                model: screens.isBrightnessAvailable ? screens.displays : null

                delegate: ScreenRow {
                    visible: key !== root.mainScreen
                    key: model.displayName
                    brightness: model.brightness
                    maxBrightness: model.maxBrightness
                    label: model.isInternal ? Cfg.t("PORTÁTIL") : model.label.replace(/[-\s]+$/, "").toUpperCase()
                }
            }
        }
    }
}
