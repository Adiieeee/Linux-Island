import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import org.kde.taskmanager as TaskManager
import "."

// tarjeta del reproductor: carátula, controles, onda
// la onda no es audio real, es un patrón fijo por título de la pista
Item {
    id: root

    // the active player (the one playing) unless the arrows at the card's
    // edges picked another one (see Media.qml)
    readonly property var player: Media.cardPlayer
    readonly property bool active: player !== null

    // the art or the title was clicked and the player was asked to show
    // itself: the control center closes (ExpandedPanel → main.qml)
    signal raised

    // ── the player's window ──
    // the player being raised (an existing container, not created here)
    property var raising: null

    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupDisabled
    }

    // bring the player's window to the front: its windows are the ones of
    // its process (AppPid = the MPRIS player's pid), or failing that of its
    // app (AppId = its desktop entry). with several, the one demanding
    // attention (it just asked to be shown), else the one used last
    function activateWindow(p): void {
        if (!p)
            return;
        const pid = Number(p.instancePid ?? 0);
        const entry = String(p.desktopEntry ?? "").toLowerCase();
        const R = TaskManager.AbstractTasksModel;
        let byPid = [], byApp = [];
        for (let i = 0; i < tasks.count; i++) {
            const idx = tasks.index(i, 0);
            if (!tasks.data(idx, R.IsWindow))
                continue;
            const appId = String(tasks.data(idx, R.AppId) ?? "").toLowerCase();
            if (pid > 0 && Number(tasks.data(idx, R.AppPid)) === pid)
                byPid.push(idx);
            else if (entry !== "" && (appId === entry || appId.indexOf(entry) >= 0))
                byApp.push(idx);
        }
        const found = byPid.length > 0 ? byPid : byApp;
        if (found.length === 0)
            return;
        let best = found[0];
        for (const idx of found) {
            if (tasks.data(idx, R.IsDemandingAttention)) {
                best = idx;
                break;
            }
            const t = tasks.data(idx, R.LastActivated);
            const bt = tasks.data(best, R.LastActivated);
            if (t && (!bt || new Date(t) > new Date(bt)))
                best = idx;
        }
        tasks.requestActivate(best);
    }

    // ── a skip in progress ──
    // after previous or next, both stay grey and can't be pressed until the
    // player reports the new track, so a second press doesn't land while a
    // browser is still loading. measured: YouTube (through the Plasma
    // Integration extension) reported the new title after ~470 ms and the
    // loaded video (its length) after ~870 ms; Spotify after 10-20 ms. at
    // least skipMin, so a double click doesn't skip twice; at most skipMax,
    // for a player that ignores the command (YouTube sometimes does)
    readonly property int skipMin: 400
    readonly property int skipMax: 1500
    property bool skipping: false
    property string skipFrom: ""
    property real skipLength: 0
    // the new track is in: another title, and its length if the player
    // gives one (a browser sends the title first, the length once loaded)
    readonly property bool skipLanded: root.skipping && (root.player?.track ?? "") !== root.skipFrom && (root.length <= 0 || root.length !== root.skipLength)

    function skip(direction: int): void {
        const p = root.player;
        if (!p || root.skipping)
            return;
        root.skipFrom = p.track ?? "";
        root.skipLength = root.length;
        root.skipping = true;
        skipMinTimer.restart();
        skipMaxTimer.restart();
        if (direction > 0)
            p.Next();
        else
            p.Previous();
    }

    function endSkip(): void {
        skipMinTimer.stop();
        skipMaxTimer.stop();
        root.skipping = false;
    }

    onSkipLandedChanged: {
        if (root.skipLanded && !skipMinTimer.running)
            root.endSkip();
    }
    // another player in the card: whatever it was waiting for is moot
    onPlayerChanged: root.endSkip()

    Timer {
        id: skipMinTimer
        interval: root.skipMin
        onTriggered: {
            if (root.skipLanded)
                root.endSkip();
        }
    }
    Timer {
        id: skipMaxTimer
        interval: root.skipMax
        onTriggered: root.endSkip()
    }

    // shuffle and repeat, as the player reports them. Unknown = the player
    // doesn't have them (browsers usually), and the buttons stay hidden
    readonly property int shuffle: player?.shuffle ?? Mpris.ShuffleStatus.Unknown
    readonly property int loop: player?.loopStatus ?? Mpris.LoopStatus.Unknown

    // a small round toggle beside the transport buttons: white with a dot
    // under it while on, the card's dim grey while off
    component ModeButton: Rectangle {
        id: mb

        property string icon: ""
        property bool on: false
        signal activated

        width: 28
        height: 28
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        color: mbMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)
        scale: mbMa.pressed ? 0.94 : mbMa.containsMouse ? 1.08 : 1.0

        Behavior on color {
            ColorAnimation {
                duration: Theme.durShort
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.durShort
                easing.type: Easing.Bezier
                easing.bezierCurve: Theme.emphasizedDecel
            }
        }

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1
            text: mb.icon
            color: mb.on ? Theme.fg : Theme.mediaDim
            font.family: Theme.fontIcons
            font.pixelSize: 16
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            width: 3
            height: 3
            radius: 1.5
            color: Theme.fg
            visible: mb.on
        }

        MouseArea {
            id: mbMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mb.activated()
        }
    }

    // room for the arrows at both edges, only with more than one player
    property int side: Media.canStep ? 22 : 0
    Behavior on side {
        NumberAnimation {
            duration: Theme.durMedium
            easing.type: Easing.Bezier
            easing.bezierCurve: Theme.emphasized
        }
    }

    readonly property bool isPlaying: (player?.playbackStatus ?? 0) === Mpris.PlaybackStatus.Playing

    // plasma ya manda la url de la carátula resuelta
    readonly property string artUrl: player?.artUrl ?? ""

    // icono de la app si no hay carátula
    readonly property string appIcon: player?.iconName ?? ""

    // mpris usa microsegundos, acá todo en segundos
    readonly property real length: (player?.length ?? 0) / 1000000
    readonly property real position: (player?.position ?? 0) / 1000000
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0
    // the player reports where it is and how long the track is. a browser
    // doesn't always: Zen's own MPRIS player with YouTube reports position 0
    // and no length on some videos, and on the others stops reporting both
    // after any seek (measured: 56 s, Seek +3 s, then 0 s and no length from
    // then on, while the video plays on). the bar then jumped to the start.
    // without a length it's plain and can't be clicked, and the times are
    // hidden. the Plasma Integration browser extension reports the video's
    // real time (see README)
    readonly property bool timed: length > 0
    readonly property bool canSkip: (player?.canGoPrevious ?? false) || (player?.canGoNext ?? false)

    // where the player is now: the last reported position plus the time
    // since, so a seek lands where it's aimed (the position is only asked
    // for once a second)
    property real posAt: 0
    Connections {
        target: root.player
        function onPositionChanged() {
            root.posAt = Date.now();
        }
    }
    function playhead(): real {
        const since = root.isPlaying && root.posAt > 0 ? (Date.now() - root.posAt) / 1000 * (root.player?.rate ?? 1) : 0;
        return Math.max(0, Math.min(root.length, root.position + since));
    }

    // MPRIS here only seeks relative to where the player is (no SetPosition)
    function seekTo(seconds: real): void {
        const p = root.player;
        if (!p || !root.timed)
            return;
        p.Seek(Math.round((seconds - root.playhead()) * 1000000));
        p.updatePosition();
    }

    // refresca posición mientras suena
    Timer {
        interval: 1000
        running: root.active && root.isPlaying
        repeat: true
        onTriggered: root.player?.updatePosition()
    }

    function fmt(seconds) {
        if (!seconds || seconds < 0)
            return "0:00";
        const m = Math.floor(seconds / 60);
        const s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    implicitHeight: 118

    // colores de la carátula via kirigami
    // hay que pasarle la Image ya cargada, no la url: con url remota da gris
    Kirigami.ImageColors {
        id: paleta
        source: artImg.status === Image.Ready ? artImg : null
    }

    // see artImg.onSourceChanged. an uncached cover goes through Loading, so
    // the source binding above changes and recomputes on its own
    function refreshTones() {
        if (artImg.status === Image.Ready)
            paleta.update();
    }

    // tono real de la carátula (palette), no highlight/average que a veces inventan un color que no está
    readonly property var tonos: {
        const p = paleta.palette;
        if (!p || p.length === 0)
            return [paleta.dominant, paleta.dominant, paleta.dominant];
        return [p[0].color, p[Math.min(1, p.length - 1)].color, p[Math.min(2, p.length - 1)].color];
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.shapeLg
        color: Theme.surfaceAlt
        clip: true
        antialiasing: true

        // ── manchas de color ──
        // tres burbujas con los colores de la carátula, moviéndose atrás
        // nada de multieffect acá: revienta plasmashell (ver readme). canvas con degradado radial en vez
        Item {
            id: liquido
            anchors.fill: parent
            // clip no redondea, por eso el margen igual al radio de la tarjeta
            anchors.margins: card.radius
            visible: root.artUrl !== ""
            opacity: 1.0

            // the control center's popup is on screen. Qt keeps animating
            // items in a hidden window (measured: ~144 updates a second
            // with the window hidden), so the blobs pause while it's closed,
            // and while there's no cover. always running, only paused
            // toggles: running: false would restart the swing from its
            // start, and Qt ignores paused while an animation isn't running
            // ("setPaused() cannot be used"), so a cover arriving with the
            // popup closed set it going unseen
            readonly property bool shown: liquido.Window.window?.visible ?? false

            component Mancha: Item {
                id: mancha
                property color tono: "#808080"
                property int periodo: 9000
                property real desdeX: 0
                property real hastaX: 0
                property real desdeY: 0
                property real hastaY: 0

                // más ancha que la tarjeta, así se ven como una sola masa y no tres manchas
                width: card.width * 1.4
                height: width
                // start where the path starts. at the default 0,0 the blob's
                // centre sat far below the card, and the card stayed dark and
                // grey for the 10-20 s its first swing took, every time the
                // popup was created
                x: mancha.desdeX - mancha.width / 2
                y: mancha.desdeY - mancha.height / 2

                // se pinta chico (220px) y se estira, mucho más liviano y sin escalones
                Canvas {
                    id: lienzo
                    anchors.centerIn: parent
                    width: 220
                    height: 220
                    scale: mancha.width / width
                    // smooth para que el estirado no salga en bloques
                    smooth: true

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();

                        const r = width / 2;
                        const g = ctx.createRadialGradient(r, r, 0, r, r, r);

                        // curva tipo campana ancha, llena casi todo y se va a nada en el borde
                        const c = mancha.tono;
                        for (var i = 0; i <= 24; i++) {
                            const t = i / 24;
                            g.addColorStop(t, Qt.rgba(c.r, c.g, c.b, 1 - Math.exp(-1.15 * (1 - t * t))));
                        }

                        ctx.fillStyle = g;
                        ctx.fillRect(0, 0, width, height);
                    }

                    // cambio de canción: repinta directo, sin cruce de color (cuesta mucho acá adentro)
                    Connections {
                        target: mancha
                        function onTonoChanged() {
                            lienzo.requestPaint();
                        }
                    }
                }

                // cada mancha va y viene sola, tiempos distintos para que no se repita
                // los valores son el centro de la mancha, no la esquina (si no, queda siempre afuera)
                SequentialAnimation on x {
                    running: true
                    paused: !liquido.visible || !liquido.shown
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: mancha.hastaX - mancha.width / 2
                        duration: mancha.periodo
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: mancha.desdeX - mancha.width / 2
                        duration: mancha.periodo
                        easing.type: Easing.InOutSine
                    }
                }
                SequentialAnimation on y {
                    running: true
                    paused: !liquido.visible || !liquido.shown
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: mancha.hastaY - mancha.height / 2
                        duration: mancha.periodo * 1.4
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: mancha.desdeY - mancha.height / 2
                        duration: mancha.periodo * 1.4
                        easing.type: Easing.InOutSine
                    }
                }
            }

            Mancha {
                tono: root.tonos[0]
                periodo: 9000
                desdeX: card.width * 0.15
                hastaX: card.width * 0.55
                desdeY: card.height * 0.15
                hastaY: card.height * 0.8
            }
            Mancha {
                tono: root.tonos[1]
                periodo: 12000
                desdeX: card.width * 0.75
                hastaX: card.width * 0.35
                desdeY: card.height * 0.85
                hastaY: card.height * 0.2
            }
            Mancha {
                tono: root.tonos[2]
                periodo: 15000
                desdeX: card.width * 0.45
                hastaX: card.width * 0.85
                desdeY: card.height * 0.35
                hastaY: card.height * 0.95
            }
        }

        // velo oscuro para que el texto blanco se siga leyendo
        Rectangle {
            anchors.fill: parent
            radius: card.radius
            antialiasing: true
            color: Theme.surfaceAlt
            opacity: root.artUrl !== "" ? 0.45 : 1
        }

        // ── esquinas ──
        // clip no redondea, las manchas pintan las esquinas cuadradas
        // se tapan a mano con canvas, nada de multieffect (revienta plasmashell)
        Canvas {
            id: esquinas
            anchors.fill: parent
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();

                const r = card.radius;
                const w = width;
                const h = height;

                // x, y del cuadradito, centro x, centro y
                const cuatro = [[0, 0, r, r], [w - r, 0, w - r, r], [0, h - r, r, h - r], [w - r, h - r, w - r, h - r]];

                for (var i = 0; i < cuatro.length; i++) {
                    const c = cuatro[i];
                    ctx.save();

                    // solo dentro del cuadrado r×r
                    ctx.beginPath();
                    ctx.rect(c[0], c[1], r, r);
                    ctx.clip();

                    ctx.fillStyle = Theme.surface;
                    ctx.fillRect(c[0], c[1], r, r);

                    // borra el cuarto de círculo, abajo sigue la mancha
                    ctx.globalCompositeOperation = "destination-out";
                    ctx.beginPath();
                    ctx.arc(c[2], c[3], r, 0, 2 * Math.PI);
                    ctx.fill();

                    ctx.restore();
                }
            }
        }

        // ── fila superior: carátula, título, controles ──
        Item {
            id: art
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 10
            anchors.leftMargin: 10 + root.side
            width: 46
            height: 46

            // casilla de fondo mientras no hay carátula
            Rectangle {
                anchors.fill: parent
                radius: Theme.shapeSm
                color: Theme.containerHighest
            }

            // se carga igual sin mostrarse, kirigami saca el color de acá
            Image {
                id: artImg
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                sourceSize.width: 92
                sourceSize.height: 92
                visible: false
                // a cover already in Qt's image cache loads at once and status
                // stays Ready, so paleta's source binding never changes and
                // it kept the previous cover's colours (YouTube → Spotify →
                // YouTube stayed blue). recompute after every new picture;
                // callLater runs once the new source has loaded
                onSourceChanged: Qt.callLater(root.refreshTones)
            }

            // shadowedimage redondea de verdad, un rectangle+clip la dejaba cuadrada
            Kirigami.ShadowedImage {
                anchors.fill: parent
                radius: Theme.shapeSm
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 92
                sourceSize.height: 92
                visible: artImg.status === Image.Ready
            }

            // firefox no manda miniatura por mpris, al menos mostramos el icono de la app
            Kirigami.Icon {
                anchors.centerIn: parent
                width: 26
                height: 26
                visible: artImg.status !== Image.Ready && root.appIcon !== ""
                source: root.appIcon
            }

            Text {
                anchors.centerIn: parent
                visible: artImg.status !== Image.Ready && root.appIcon === ""
                text: Icons.music
                color: Theme.mediaDim
                font.family: Theme.fontIcons
                font.pixelSize: 22
            }
        }

        Column {
            anchors.left: art.right
            anchors.leftMargin: 12
            anchors.right: controls.left
            anchors.rightMargin: 12
            anchors.verticalCenter: art.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: root.player?.track || Cfg.t("Nada reproduciéndose")
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.bodyMedium
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.player?.artist ?? ""
                color: Qt.alpha(Theme.fg, Theme.mediaArtistAlpha)
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
                elide: Text.ElideRight
                visible: text !== ""
            }
        }

        // ── open the player ──
        // a click on the art or the title asks the player to show itself
        // (MPRIS Raise): Spotify's window; Firefox-based browsers (Zen) also
        // switch to the tab that plays. on Wayland a browser isn't allowed
        // to bring its own window forward (KWin's focus stealing
        // prevention): Zen switched the tab but stayed behind. so a moment
        // later the card activates the player's window itself, through
        // Plasma's task manager, which plasmashell may do. players that
        // can't be raised (canRaise false) ignore the click
        MouseArea {
            anchors.left: art.left
            anchors.top: art.top
            anchors.bottom: art.bottom
            anchors.right: controls.left
            enabled: root.player?.canRaise ?? false
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.raising = root.player;
                root.player.Raise();
                raiseLater.restart();
            }
        }

        // after Raise has switched the tab, so a browser window that asked to
        // be shown is marked as demanding attention
        Timer {
            id: raiseLater
            interval: 250
            onTriggered: {
                root.activateWindow(root.raising);
                root.raising = null;
                root.raised();
            }
        }

        // ── controles ──
        Row {
            id: controls
            anchors.right: parent.right
            anchors.rightMargin: 10 + root.side
            anchors.verticalCenter: art.verticalCenter
            spacing: 2

            ModeButton {
                visible: root.shuffle !== Mpris.ShuffleStatus.Unknown
                icon: "shuffle"
                on: root.shuffle === Mpris.ShuffleStatus.On
                onActivated: root.player.shuffle = on ? Mpris.ShuffleStatus.Off : Mpris.ShuffleStatus.On
            }

            Repeater {
                model: 3

                Rectangle {
                    id: btn
                    required property int index
                    readonly property bool isPlay: index === 1

                    width: isPlay ? 40 : 32
                    height: isPlay ? 40 : 32
                    radius: height / 2
                    anchors.verticalCenter: parent.verticalCenter

                    // previous and next wait out a skip (root.skipping), and are
                    // off while the player says it can't go there: YouTube only
                    // offers them inside a playlist (CanGoNext/CanGoPrevious
                    // false otherwise), and a press then did nothing
                    readonly property bool unavailable: index === 0 ? !(root.player?.canGoPrevious ?? false) : index === 2 ? !(root.player?.canGoNext ?? false) : false
                    readonly property bool waiting: !isPlay && (root.skipping || unavailable)

                    // a player with neither (YouTube outside a playlist) shows
                    // no previous and next at all; with one of them both stay,
                    // the missing one grey. kept through a skip, while a browser
                    // between videos may briefly report neither
                    visible: isPlay || root.canSkip || root.skipping

                    color: isPlay ? Theme.fg : bma.containsMouse && !waiting ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)
                    opacity: root.active ? 1 : 0.38

                    // mismo hover/press que los botones de abajo
                    scale: bma.pressed ? 0.94 : bma.containsMouse ? 1.08 : 1.0

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durShort
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.durShort
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Theme.emphasizedDecel
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (btn.index === 0)
                                return Icons.prev;
                            if (btn.index === 2)
                                return Icons.next;
                            return root.isPlaying ? Icons.pause : Icons.play;
                        }
                        color: btn.isPlay ? Theme.surface : btn.waiting ? Theme.fgFaint : Theme.fg
                        font.family: Theme.fontIcons
                        font.pixelSize: btn.isPlay ? 22 : 18

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durShort
                            }
                        }
                    }

                    MouseArea {
                        id: bma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: btn.waiting ? Qt.ArrowCursor : Qt.PointingHandCursor
                        enabled: root.active && !btn.waiting
                        onClicked: {
                            const p = root.player;
                            if (!p)
                                return;
                            if (btn.index === 1)
                                p.PlayPause();
                            else
                                root.skip(btn.index === 2 ? 1 : -1);
                        }
                    }
                }
            }

            // off → repeat all → repeat one, like Spotify's own button
            ModeButton {
                visible: root.loop !== Mpris.LoopStatus.Unknown
                icon: root.loop === Mpris.LoopStatus.Track ? "repeat_one" : "repeat"
                on: root.loop === Mpris.LoopStatus.Playlist || root.loop === Mpris.LoopStatus.Track
                onActivated: {
                    if (root.loop === Mpris.LoopStatus.None)
                        root.player.loopStatus = Mpris.LoopStatus.Playlist;
                    else if (root.loop === Mpris.LoopStatus.Playlist)
                        root.player.loopStatus = Mpris.LoopStatus.Track;
                    else
                        root.player.loopStatus = Mpris.LoopStatus.None;
                }
            }
        }

        // ── onda / barra de progreso ──
        Item {
            id: wave
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12 + root.side
            anchors.rightMargin: 12 + root.side
            anchors.top: art.bottom
            anchors.topMargin: 8
            height: 30

            readonly property int barCount: 64
            readonly property real barW: width / barCount

            // mismo título, misma onda
            readonly property var pattern: {
                const title = root.player?.track ?? "";
                let seed = 0;
                for (var i = 0; i < title.length; i++)
                    seed = (seed * 31 + title.charCodeAt(i)) & 0x7fffffff;
                if (seed === 0)
                    seed = 12345;

                const out = [];
                for (var b = 0; b < barCount; b++) {
                    // lcg simple, determinista
                    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
                    const r = (seed >>> 8) / 0x7fffff;
                    // extremos más bajos
                    const env = Math.sin(Math.PI * (b + 0.5) / barCount);
                    out.push(0.18 + 0.82 * r * (0.45 + 0.55 * env));
                }
                return out;
            }

            Row {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: wave.barCount

                    Item {
                        required property int index
                        width: wave.barW
                        height: wave.height

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.max(1.5, wave.barW - 1.5)
                            height: Math.max(2, wave.height * (wave.pattern[index] ?? 0.3))
                            radius: width / 2
                            // played: full text colour. not yet: the same colour,
                            // translucent (same RGB, so the fade has no grey flash)
                            color: root.timed && (index / wave.barCount) <= (seekMa.dragging ? seekMa.at : root.progress) ? Theme.primary : Qt.alpha(Theme.primary, Theme.mediaTrackAlpha)

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.durShort
                                }
                            }
                        }
                    }
                }
            }

            // click or drag: while held the bar and the elapsed time follow the
            // pointer, and the seek happens on release. dragging past either
            // end clamps there, so the start is easy to reach
            MouseArea {
                id: seekMa
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: root.active && root.timed && (root.player?.canSeek ?? false)
                preventStealing: true

                property bool dragging: false
                // 0..1 along the bar
                property real at: 0

                function follow(x: real): void {
                    seekMa.at = Math.max(0, Math.min(1, x / width));
                }

                onPressed: mouse => {
                    seekMa.follow(mouse.x);
                    seekMa.dragging = true;
                }
                onPositionChanged: mouse => {
                    if (seekMa.dragging)
                        seekMa.follow(mouse.x);
                }
                onReleased: {
                    if (!seekMa.dragging)
                        return;
                    seekMa.dragging = false;
                    root.seekTo(seekMa.at * root.length);
                }
                onCanceled: seekMa.dragging = false
            }
        }

        // ── tiempos ──
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12 + root.side
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            text: root.fmt(seekMa.dragging ? seekMa.at * root.length : root.position)
            visible: root.timed
            color: Theme.mediaDim
            font.family: Theme.fontDots
            font.features: Theme.numFeatures
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 12 + root.side
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            text: root.fmt(root.length)
            visible: root.timed
            color: Theme.mediaDim
            font.family: Theme.fontDots
            font.features: Theme.numFeatures
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        // ── switch player: arrows at the card's edges, only with more than
        // one player (Spotify, a browser tab with YouTube, ...) ──
        Repeater {
            model: [-1, 1]

            Rectangle {
                id: arrow
                required property int modelData

                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 6
                x: arrow.modelData < 0 ? 4 : parent.width - width - 4
                width: Math.max(0, root.side - 4)
                visible: width > 2
                radius: Theme.shapeSm
                // transparent at rest: fade from Qt.alpha, not "transparent" (hard rule 6)
                color: arrowMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: arrow.modelData < 0 ? "chevron_left" : "chevron_right"
                    color: arrowMa.containsMouse ? Theme.fg : Theme.mediaDim
                    font.family: Theme.fontIcons
                    font.pixelSize: 20
                }

                MouseArea {
                    id: arrowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.step(arrow.modelData)
                }
            }
        }
    }
}
