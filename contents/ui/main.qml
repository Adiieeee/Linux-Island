import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.layershell as LayerShell
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.taskmanager as TaskManager
import "."
import "game.js" as Game

// isla dinámica para plasma: píldora en el panel + panel emergente al clic
PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    // ── preferencias ──
    Binding {
        target: Cfg
        property: "lang"
        value: Plasmoid.configuration.lang
    }
    Binding {
        target: Cfg
        property: "clock24"
        value: Plasmoid.configuration.clock24
    }
    Binding {
        target: Cfg
        property: "ramUsage"
        value: Plasmoid.configuration.ramUsage
    }
    Binding {
        target: Cfg
        property: "showWorkspaces"
        value: Plasmoid.configuration.showWorkspaces
    }
    Binding {
        target: Cfg
        property: "showWeather"
        value: Plasmoid.configuration.showWeather
    }
    Binding {
        target: Cfg
        property: "showClock"
        value: Plasmoid.configuration.showClock
    }
    Binding {
        target: Cfg
        property: "showBattery"
        value: Plasmoid.configuration.showBattery
    }
    Binding {
        target: Cfg
        property: "showMini"
        value: Plasmoid.configuration.showMini
    }
    Binding {
        target: Cfg
        property: "showLyrics"
        value: Plasmoid.configuration.showLyrics
    }
    Binding {
        target: Cfg
        property: "tintIsland"
        value: Plasmoid.configuration.tintIsland
    }
    Binding {
        target: Cfg
        property: "notchOverGames"
        value: Plasmoid.configuration.notchOverGames
    }
    Binding {
        target: Cfg
        property: "weatherCity"
        value: Plasmoid.configuration.weatherCity
    }
    Binding {
        target: Cfg
        property: "colorFondo"
        value: Plasmoid.configuration.colorFondo
    }
    Binding {
        target: Cfg
        property: "colorTarjeta"
        value: Plasmoid.configuration.colorTarjeta
    }
    Binding {
        target: Cfg
        property: "colorInvertida"
        value: Plasmoid.configuration.colorInvertida
    }
    Binding {
        target: Cfg
        property: "colorAlerta"
        value: Plasmoid.configuration.colorAlerta
    }
    Binding {
        target: Cfg
        property: "colorTexto"
        value: Plasmoid.configuration.colorTexto
    }
    Binding {
        target: Cfg
        property: "fuenteUi"
        value: Plasmoid.configuration.fuenteUi
    }
    Binding {
        target: Cfg
        property: "fuenteNumeros"
        value: Plasmoid.configuration.fuenteNumeros
    }
    Binding {
        target: Cfg
        property: "recFolder"
        value: Plasmoid.configuration.recFolder
    }
    Binding {
        target: Cfg
        property: "recMode"
        value: Plasmoid.configuration.recMode
    }

    // the meters, the volume and the Wi-Fi / Bluetooth state are only read
    // while the control center is open (singletons can't see `expanded`)
    Binding {
        target: SysInfo
        property: "open"
        value: root.expanded
    }
    Binding {
        target: Audio
        property: "open"
        value: root.expanded
    }
    Binding {
        target: Net
        property: "open"
        value: root.expanded
    }

    // folder and mode picked in the recording view (Recorder can't write the config)
    Connections {
        target: Recorder
        function onFolderChosen(path) {
            Plasmoid.configuration.recFolder = path;
        }
        function onModeChosen(mode) {
            Plasmoid.configuration.recMode = mode;
        }
    }

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // ── the keyboard stays where the user was typing ──
    // opening on hover must not take the keyboard. KWin activates every
    // window it shows (Qt.WindowDoesNotAcceptFocus didn't stop it: tested,
    // Qt drops requestActivate() but KWin activates the window on show
    // anyway), so the popup does get it, and is handed straight back: on
    // entering the notch the active window is remembered, and if the popup
    // becomes active within Theme.keyboardReturnWindow after that, the
    // remembered window is activated again. a later activation, a click
    // into the popup (the wifi password), keeps the keyboard in the popup.
    // Plasma would close its popup as soon as it lost focus, so that's off;
    // the hover timer below closes it
    hideOnWindowDeactivate: false

    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupDisabled
    }

    // ── a fullscreen window on the island's screen ──
    // for "Keep the notch over games": the active window is fullscreen (a
    // game, a video) on the screen the island's panel is on. read from the
    // same tasks model, recomputed when the active window or any window's
    // state changes (a binding can't see the model's dataChanged)
    property bool gameOnIsland: false

    function refreshGame() {
        const i = tasks.activeTask;
        const island = root.compactRepresentationItem?.screenRect ?? null;
        root.gameOnIsland = i.valid && Game.gameOnIsland(tasks.data(i, TaskManager.AbstractTasksModel.IsFullScreen), tasks.data(i, TaskManager.AbstractTasksModel.ScreenGeometry), island);
    }

    Connections {
        target: tasks
        function onActiveTaskChanged() {
            root.refreshGame();
        }
        function onDataChanged() {
            root.refreshGame();
        }
        function onCountChanged() {
            root.refreshGame();
        }
    }

    // the control center was opened from the floating notch. the popup
    // isn't a window in the tasks model, and while it has the keyboard the
    // game isn't the active window, so gameOnIsland drops; without this the
    // floating notch would vanish under the pointer as the popup opens
    property bool gameNotchHeld: false
    onExpandedChanged: {
        // Plasma expanding on the shortcut, see Plasmoid.onActivated
        if (root.expanded && root.activating) {
            root.expanded = false;
            return;
        }
        if (root.expanded)
            return;
        root.gameNotchHeld = false;
        // back to the game the control center was opened over
        const owner = root.gameOwner;
        root.gameOwner = "";
        root.activateWindowId(owner);
    }

    // ── the notch over a fullscreen game ──
    // a fullscreen active window sits above Plasma's panels, so the panel's
    // notch is covered. this is a copy of just the notch in its own window,
    // on layer-shell's Overlay layer (above fullscreen windows), pinned to
    // the top edge of the island's screen. it never takes the keyboard, so
    // the game keeps it (prototyped outside plasmashell first: drawn above
    // a fullscreen window, hover and clicks reach it, the fullscreen window
    // stays active and gets every key)
    Window {
        id: gameNotch

        visible: Cfg.notchOverGames && (root.gameOnIsland || (root.expanded && root.gameNotchHeld))
        screen: root.compactRepresentationItem?.islandScreen ?? null
        // the larger of the notch's width and the width it's heading to:
        // a growing notch isn't clipped, and the window is never much wider
        // than the notch, so it doesn't swallow the game's clicks around it
        width: Math.ceil(Math.max(gamePill.notchWidth, gamePill.notchTarget))
        height: root.compactRepresentationItem?.notchHeight ?? Theme.collapsedHeight
        color: "transparent"

        LayerShell.Window.layer: LayerShell.Window.LayerOverlay
        LayerShell.Window.anchors: LayerShell.Window.AnchorTop
        LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityNone
        LayerShell.Window.exclusionZone: -1
        LayerShell.Window.screenConfiguration: LayerShell.Window.ScreenFromQWindow
        LayerShell.Window.scope: "linuxisland-game-notch"

        // it may appear right under the pointer: don't let that open the
        // control center (CompactPill.hoverArmed)
        onVisibleChanged: if (visible)
            gamePill.disarmHover()

        // as tall as the panel's notch; the window is exactly its height,
        // so the pill's reach (to the panel's edges) is 0
        CompactPill {
            id: gamePill
            notchOnly: true
            anchors.horizontalCenter: parent.horizontalCenter
            width: implicitWidth
            height: parent.height
            onOpenRequested: root.openFromNotch()
        }
    }

    // the window id of whoever had the keyboard when hover opened the popup;
    // empty when there's nothing to hand back
    property string keyboardOwner: ""

    // the active window's id, "" when there's none
    function activeWindowId() {
        const i = tasks.activeTask;
        const ids = i.valid ? tasks.data(i, TaskManager.AbstractTasksModel.WinIdList) : null;
        return ids && ids.length ? String(ids[0]) : "";
    }

    function activateWindowId(id) {
        if (!id)
            return;
        for (let r = 0; r < tasks.count; r++) {
            const idx = tasks.index(r, 0);
            const ids = tasks.data(idx, TaskManager.AbstractTasksModel.WinIdList);
            if (ids && ids.length && String(ids[0]) === id) {
                tasks.requestActivate(idx);
                return;
            }
        }
    }

    function rememberKeyboardOwner() {
        root.keyboardOwner = root.activeWindowId();
        if (root.keyboardOwner)
            keyboardReturn.restart();
    }

    function giveKeyboardBack() {
        const owner = root.keyboardOwner;
        root.keyboardOwner = "";
        keyboardReturn.stop();
        root.activateWindowId(owner);
    }

    // ── over a game, the keyboard goes back on close instead ──
    // handing the keyboard straight back doesn't work over a fullscreen
    // game: KWin keeps a fullscreen window above the panels only while it's
    // the active one, so the popup taking the keyboard sends the game behind
    // the panel (the whole panel shows), and handing it back raises the game
    // above everything again, the control center included (seen live: the
    // panel and the control center flashed for a frame and were gone).
    // Plasma's popup can't sit above an active fullscreen window. so when the
    // control center opens from the floating notch, it keeps the keyboard
    // and the game waits behind the panel, as when any Plasma popup opens
    // over a game; when it closes, the game is activated again
    property string gameOwner: ""

    // past this, a popup activation is the user's own click, not the show
    Timer {
        id: keyboardReturn
        interval: Theme.keyboardReturnWindow
        onTriggered: root.keyboardOwner = ""
    }

    // the pointer reached a notch (the panel's or the one over a game):
    // open the control center, and hand the keyboard back afterwards
    function openFromNotch() {
        if (root.expanded)
            return;
        // opened from the floating notch: keep it up while the control
        // center is open (see gameNotchHeld), and give the game its keyboard
        // back only when it closes (see gameOwner)
        root.gameNotchHeld = gameNotch.visible;
        if (root.gameNotchHeld)
            root.gameOwner = root.activeWindowId();
        else
            root.rememberKeyboardOwner();
        root.expanded = true;
    }

    // the control center closes on its own once the pointer has been off
    // the notches and the popup for Theme.hoverCloseDelay
    Timer {
        interval: Theme.hoverCloseDelay
        running: root.expanded && !(root.compactRepresentationItem?.notchHovered ?? false) && !gamePill.notchHovered && !(root.fullRepresentationItem?.engaged ?? false)
        onTriggered: root.expanded = false
    }

    // no tooltip: hovering the island used to show the time and weather after
    // a moment. both empty, explicitly: left unset, Plasma falls back to the
    // applet's name and still shows one
    toolTipMainText: ""
    toolTipSubText: ""

    // the widget's keyboard shortcut (Configure → Keyboard Shortcuts; Meta+Space
    // is the suggested one) flips "Keep the notch over games" instead of
    // opening the control center: in a game it only shows or hides the
    // floating notch and never takes the game's focus. the control center
    // opens by moving the pointer onto a notch.
    // Plasma can't be told not to expand on activation: its own handler
    // runs setExpanded(!(expanded && activationTogglesExpanded)), so with
    // this false it always expands ("never collapse" rather than "don't
    // open"; first read the other way, and live the shortcut flashed the
    // control center and, over a game, the whole panel). so an activation
    // collapses straight back, within the same signal, whichever of
    // Plasma's handler and this one runs first (activating lets
    // onExpandedChanged undo an expand that comes after this handler)
    activationTogglesExpanded: false
    property bool activating: false
    Plasmoid.onActivated: {
        Plasmoid.configuration.notchOverGames = !Plasmoid.configuration.notchOverGames;
        root.activating = true;
        root.expanded = false;
        Qt.callLater(() => root.activating = false);
    }

    // an Item, not a MouseArea: only the notch opens the popup, on hover
    // (CompactPill), not the desktop dots or the empty space beside it
    compactRepresentation: Item {
        id: compact

        readonly property bool horizontal: Plasmoid.formFactor !== PlasmaCore.Types.Vertical

        // reserve exactly what is drawn. a hardcoded width here made the pill
        // spill past its slot into the neighbouring widgets
        readonly property real targetWidth: compactPill.implicitWidth

        Layout.minimumWidth: horizontal ? targetWidth : -1
        Layout.preferredWidth: horizontal ? targetWidth : -1
        Layout.maximumWidth: horizontal ? targetWidth : Infinity
        Layout.fillHeight: horizontal
        Layout.minimumHeight: horizontal ? -1 : Theme.collapsedHeight
        Layout.preferredHeight: horizontal ? -1 : Theme.collapsedHeight

        implicitWidth: targetWidth
        implicitHeight: Theme.collapsedHeight

        // read by the close timer above
        readonly property bool notchHovered: compactPill.notchHovered

        // the island's screen, for refreshGame() (and, later, the floating
        // notch's window): its rect in the virtual desktop's logical
        // coordinates, the same space as TaskManager's ScreenGeometry
        readonly property rect screenRect: Qt.rect(compact.Screen.virtualX, compact.Screen.virtualY, compact.Screen.width, compact.Screen.height)
        onScreenRectChanged: root.refreshGame()
        // the floating notch's window goes on this screen, as tall as this
        // notch (the panel's thickness: it reaches the panel's edges)
        readonly property var islandScreen: compact.Window.window ? compact.Window.window.screen : null
        readonly property real notchHeight: compactPill.capsuleHeight

        // Plasma's panel wrapper (CompactApplet.qml) marks an open applet
        // with its expandedFeedback item: the theme's "active tab" frame,
        // which Ant-Dark draws as a 3 px pale line along the panel's bottom
        // edge, showing beside the black notch under the dots and the
        // clock. there's no setting for it, so it's found up the parent
        // chain and hidden. assigning visible drops Plasma's
        // "visible: opacity > 0" binding, so it stays hidden. nothing else
        // in Plasma reads expandedFeedback; if a Plasma update renames it,
        // this finds nothing and the line simply comes back
        function hideExpandedFeedback() {
            for (let p = compact.parent; p; p = p.parent) {
                if (p.expandedFeedback !== undefined) {
                    if (p.expandedFeedback)
                        p.expandedFeedback.visible = false;
                    return;
                }
            }
        }
        // Plasma reparents the compact representation after creating it
        onParentChanged: hideExpandedFeedback()
        Component.onCompleted: hideExpandedFeedback()

        // the whole island: desktop dots · notch · (room for the clock). it
        // takes the slot's height and the notch reaches past it to the
        // panel's edges on its own
        CompactPill {
            id: compactPill
            anchors.centerIn: parent
            width: implicitWidth
            height: compact.height
            horizontal: compact.horizontal
            bottomEdge: Plasmoid.location === PlasmaCore.Types.BottomEdge
            onOpenRequested: root.openFromNotch()
            asleep: gameNotch.visible
        }
    }

    fullRepresentation: ExpandedPanel {
        id: full

        // the popup took the keyboard when it showed: hand it back
        onWindowActiveChanged: if (windowActive && root.keyboardOwner)
            root.giveKeyboardBack()

        onLyricsToggled: Plasmoid.configuration.showLyrics = !Plasmoid.configuration.showLyrics
        onGameNotchToggled: Plasmoid.configuration.notchOverGames = !Plasmoid.configuration.notchOverGames
        onCloseRequested: root.expanded = false

        // smaller than Theme.expandedWidth by the part of Plasma's frame the
        // island covers (ExpandedPanel.reach)
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Layout.maximumWidth: implicitWidth

        // min = preferred = max = implicitHeight, set by hand in an order that
        // keeps min <= max at every step. Plasma reacts to each of the three on
        // its own (setMinimumHeight, resize, setMaximumHeight on the popup
        // window); as three bindings, growing went through min 710 / max 524
        // for an instant
        function applyHeight() {
            const h = full.implicitHeight;
            if (h > full.Layout.maximumHeight) {
                full.Layout.maximumHeight = h;
                full.Layout.preferredHeight = h;
                full.Layout.minimumHeight = h;
            } else {
                full.Layout.minimumHeight = h;
                full.Layout.preferredHeight = h;
                full.Layout.maximumHeight = h;
            }
        }
        onImplicitHeightChanged: applyHeight()
        Component.onCompleted: applyHeight()
    }
}
