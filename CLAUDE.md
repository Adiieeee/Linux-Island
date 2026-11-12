# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A KDE Plasma 6 applet (plasmoid), "Linux Island": a Nothing OS-style dynamic island that sits in the middle of the panel and works as a control center. It is the user's personal fork of **Nothing Dynamic Island** by Omar (applet id `org.omar.nothingisland`, MIT), which was itself a port of a Quickshell/Hyprland island. The fork changes the UI to the user's own taste. The applet is a compact pill in a panel, with a Plasma popup (`fullRepresentation`) that opens on click. Pure QML plus one small Python helper (`coffee.py`). There is no build step and no test suite.

**Git:** public repo `github.com/Adiieeee/linuxisland`, branch `main`. The first commit is the unmodified upstream code; every later commit is a fork change. Use **micro commits**: commit each small, self-contained change on its own as soon as it's done, together with the README update it needs, and keep unrelated edits in separate commits. Keep `LICENSE` with the original author's copyright line, since MIT requires it.

`README.md` is the user-facing doc and design log, translated to English from the upstream Spanish. It records why things are done the way they are and each crash or bug found so far. Read the relevant section before changing an area. **Keep it current:** in the same change as the code, update any section the change makes stale, add new gotchas, and log every user-visible change under "What this fork changes".

**Upstream copy:** `../org.omar.nothingisland/` is the original install, with the same code as the first commit. It is not part of this repo. It stays installed **on purpose**, so the user can compare it side by side with this fork. Two islands on the desktop are expected. Never modify or remove that folder.

## Commands

```bash
# Reload after editing: the applet runs inside plasmashell, so restart it
kquitapp6 plasmashell && kstart plasmashell

# Static check with Qt 6's qmllint. /usr/bin/qmllint is Qt 5's (qt5-declarative):
# it can't parse this code and exits 255 with no output. The Qt 6 one resolves the
# Plasma imports but isn't clean: older files carry warnings (mostly unqualified
# access), so compare against the files you touched, not zero
/usr/lib/qt6/bin/qmllint contents/ui/*.qml

# Install/upgrade as a package (when working from a copy outside ~/.local/share/plasma/plasmoids)
kpackagetool6 -t Plasma/Applet -u .
```

`plasmoidviewer` (plasma-sdk) is not installed. To test a QML piece outside Plasma, `/usr/lib/qt6/bin/qml` works for files that don't need `Plasmoid` (import the folder with `import "file:///…/contents/ui"`). Add `QT_QPA_PLATFORM=offscreen` to skip the window, and `QT_FORCE_STDERR_LOGGING=1` to see `console.log`, which otherwise goes to the journal. The code is **not** `qmlformat`-clean, so don't run it over whole files; that would rewrite every file.

If you change the popup's size, Plasma keeps the old one in `popupHeight`/`popupWidth` under the applet's `[Configuration]` group in `~/.config/plasma-org.kde.plasma.desktop-appletsrc`. Stop plasmashell, delete those keys, then start it again.

## Architecture

**Entry:** `contents/ui/main.qml` (`PlasmoidItem`). `compactRepresentation` is a single `CompactPill`: one black notch (`NotchShape.qml`, flat top flush with the screen edge, round bottom corners, concave flares at the top corners; flipped on a bottom panel; black like the control center by default, or with `Cfg.tintIsland` tinted with the cover's palette like the media card while media shows, as extra `ShapePath`s with radial gradients over one shared SVG outline) with the album art, a middle and a waveform while media plays or is paused, only today's date otherwise. The middle (`mode`) is the date ("11 November 2026" alone, "11 Nov 2026" with the lyrics off or a browser video), a new song's title and artist for `Theme.peekDuration` (the track peek, once per `Lyrics.key`), the lyric line being sung (`LyricLine`/`MarqueeText`) while `Lyrics.wide` (these two at the fixed `Theme.lyricsWidth`), ♪ between lines and ♫ for a song without lyrics (`NoteGlyph.qml`, vectors). Pausing keeps whatever shows. The waveform (`LiveWave.qml`) is real audio: plasma-pa's `VolumeMonitor` on the default sink, connected only while something plays. It reaches past its panel slot to the panel's edges (`reach`). Outside the notch, on the panel: the desktop dots (`Workspaces.qml`, all white; a click switches desktop via `clickable`, the wheel steps through them via `scrollable`) on the left and the clock (`Clock.qml`, always `HH:mm`, fixed "00:00" width) on the right; both sides are `sideWidth` wide so the notch stays centred. The compact representation is a plain `Item`: only the notch's `MouseArea` opens the popup, at once when the pointer enters it (`CompactPill.openRequested`, only opens); clicks do nothing (`acceptedButtons: Qt.NoButton`). A `Timer` in main.qml closes it once the pointer has been off both the notch (`CompactPill.notchHovered`) and the popup (`ExpandedPanel.engaged`: a `HoverHandler` on the root with `margin` = Plasma's frame padding, so the frame ring counts as inside, or a text field with focus; on a child it would miss the pointer over any hover-enabled `MouseArea`) for `Theme.hoverCloseDelay`; it reads them through `compactRepresentationItem`/`fullRepresentationItem`. Plasma's tooltip is off: `toolTipMainText`/`toolTipSubText` are set to `""` (unset falls back to the applet name). So is Plasma's "applet is open" line on the panel: the compact item's `hideExpandedFeedback()` finds `expandedFeedback` up its parent chain (Plasma's `CompactApplet.qml`) and sets it invisible. `fullRepresentation` is `ExpandedPanel`. Its min, preferred and max height are all pinned to `implicitHeight`, which comes from the real content height (`mainColumn.implicitHeight`), not a fixed number.

**Singletons** (registered in `contents/ui/qmldir`, imported with `import "."`). These hold all state and data access. The views only bind to them.
- `Theme`: every design token (colors, type scale, shapes, motion curves, island sizes). The user picks 4 colors plus a text color. The intermediate greys come from `mezcla()`, which blends them. The header comment lists the visual rules (strict monochrome, red only for critical states, no gradients or shadows). Text uses the system font (`Qt.application.font`) unless overridden in settings. Only the Material Symbols icon font is bundled, and it loads with `FontLoader` from `contents/fonts/`, never by system name.
- `Cfg`: user settings plus the i18n dictionary. **Singletons can't see `Plasmoid.configuration`**, so `main.qml` copies each key into `Cfg` with a `Binding`.
- `Exec`: fire-and-forget shell commands (`Exec.run(cmd)`).
- Data services: `SysInfo` (/proc, hwmon, nvidia-smi every 3 s, only while the control center is open: `open`, bound to `expanded` in main.qml), `Net` (nmcli + bluetoothctl every 8 s, also only while `open`), `Audio` (wpctl every 1 s, also only while `open`; pactl device lists), `Weather` (wttr.in via XHR), `Notifs` (reads Plasma's notification history via `org.kde.notificationmanager`; it is not the notification server), `Recorder` (spectacle), `Media` (the one MPRIS model: `active` is Plasma's multiplexer pick, except that with several playing at once `pick()` ranks Spotify, then a browser, then the rest; `cardPlayer` what the media card shows), `Lyrics` (synced lyrics for `Media.active` from lrclib.net via XHR; extrapolates the playhead from the last MPRIS position and sets one single-shot timer per line change; the pure parts live in `lrc.js`, testable outside Plasma), `Icons` (Material Symbols ligature names).

**Data-service pattern:** each service has its own typed `P5Support.DataSource { engine: "executable" }`. It runs `connectSource(cmd)` on a `Timer`, and in `onNewData` it calls `disconnectSource(cmd)` and then picks the parser by comparing `cmd` against its `readonly property string xxxCmd`. Expensive lists (nearby wifi, BT devices, audio devices) are fetched only while a panel is open. The panel does `Service.watchers++` on creation and `--` in `Component.onDestruction`. The polling services check `watchers > 0`.

**Overlays:** `ExpandedPanel.overlay` is a string (`"wifi"`, `"bt"`, `"rec"`, `"audio"`, `"notif"`, `"cal"`, `"power"`). A `Loader` maps it to one of `RecordView`, `ConnPanel` (handles both wifi and bt via `mode`), `AudioPanel`, `NotifPanel`, `CalendarPanel` and `PowerView`. (The app launcher, `AppLauncher` with `apps.py`, was removed: its bottom-row slot became the lyrics toggle.) Each emits `closed()`. Child cards ask for overlays through signals (`requestPanel`, `requestNotifs`, …) that call `openOverlay(name)`. To add an overlay, add its `Component` and its branch in `sourceComponent`.

**System actions go through DBus, not systemctl:** `org.kde.Shutdown` (logout, reboot, shutdown), `org.freedesktop.PowerManagement` (suspend, hibernate, `CanSuspend`/`CanHibernate`), `org.freedesktop.ScreenSaver` (lock), and KWin `VirtualDesktopManager.current` (switch desktop, because `VirtualDesktopInfo` is read-only). Media uses `org.kde.plasma.private.mpris`. That module has only a relative `Seek(offset µs)`; it has no `SetPosition`. Brightness uses `org.kde.plasma.private.brightnesscontrolplugin` (`ScreenBrightnessControl`, the backend of Plasma's own brightness applet) inside `SliderCard.qml`. Its `displays` model has the roles `displayName`, `label`, `brightness`, `maxBrightness` and `isInternal`. The main row is the island's own screen. It's found through the `Screen` attached property: `eDP`/`LVDS`/`DSI` means internal, and an external monitor matches when `Screen.model` equals the display's `label`. It updates live, so nothing is polled. The sound dropdown in `SliderCard.qml` uses plasma-pa (`org.kde.plasma.private.volume`): `SinkModel`/`SourceModel` (roles include `Default`, `Description`, `PulseObject`) and the `PreferredDevice` singleton. To switch device, set `PulseObject.default = true`. Default flags arrive shortly after the models are created, so bind to them. The main volume row still uses `Audio` (wpctl).

**Python helper** (`contents/code/`). QML finds it with `Qt.resolvedUrl("../code/x.py")` with `file://` stripped:
- `coffee.py`: holds 3 idle inhibitions (ScreenSaver, PowerManagement, PowerDevil PolicyAgent) for as long as the process lives. KDE drops an inhibition when the DBus connection that requested it closes. On = launch it in the background, off = `pkill -f "^python3 <full path>"` (`QuickActions.coffeeMatch`). Never a bare `pkill -f coffee.py`: the DataSource's `sh -c` has that name in its own command line, so pkill kills the shell before it starts the helper.

`Island.qml` is an unused experiment (an in-place growing island). It still hardcodes the upstream applet id `org.omar.nothingisland`, not `linuxisland`.

## Adding a setting

Touch four files: `contents/config/main.xml` (entry plus default), the config page (`ConfigGeneral.qml`, `ConfigColores.qml` or `ConfigTipografias.qml`, as a `property <type> cfg_<key>`), `main.qml` (a `Binding` into `Cfg`), and `Cfg.qml` (the property). Config pages register in `contents/config/config.qml`. Defaults are not repeated in the pages: declare an empty `cfg_<key>Default`, which Plasma fills from `main.xml`. Reset buttons must also set the control's value by hand, because picking a value breaks the control's binding. A page must compute its language from its own live `cfg_lang`, not from `Cfg.esp`, which only updates after Accept.

## Hard rules (each one crashed plasmashell or caused a real bug)

The applet runs **inside plasmashell**, so a crash takes down the whole desktop.

1. **Never `property var` for an object created in place.** The JS GC can free it while C++ still uses it (SIGSEGV in `QV4::MarkStack::drain`). Type it: `readonly property P5Support.DataSource source: P5Support.DataSource {…}`.
2. **Don't store callbacks that cross into C++ and back.** For example, don't keep a dict of functions called from `onNewData`. `Exec.run` is fire-and-forget. Anything that needs output owns its DataSource and dispatches by command string.
3. **No `MultiEffect` or `layer.enabled` blur anywhere.** It segfaults plasmashell after 10–25 s. For soft shapes, use a radial gradient painted by `Canvas` (see the media card's liquid background). Use `Kirigami.ShadowedImage` for rounded images, because `clip` doesn't clip to the radius.
4. **Don't poll often.** Keep the existing intervals, and gate long lists behind `watchers`.
5. **`DataSource` already runs commands in a shell.** Don't wrap them in `sh -c "…"`. The outer shell eats `$var` and `$(…)`, and the command fails silently.
6. **Hover color animations:** if the resting color is opaque, the hover color must be opaque too (`surfaceAlt` → `surfaceHigh` → `surfaceTop`). If the resting color is transparent, use `Qt.alpha(Theme.fg, 0)`, not `"transparent"`. Mixing the two produces a grey flash mid-animation.
7. Don't put an `anchors.fill` child inside a `Row`, because it collapses the Row. Wrap the Row in an `Item` instead. Invisible items still take part in anchoring.
8. The icon font (Material Symbols ligatures) must not be user-configurable. Every number text uses `font.family: Theme.fontDots` plus `font.features: Theme.numFeatures` (tabular figures), so digits don't change width. Ticking clocks also reserve width with a `TextMetrics` on an all-zeros template.

Spectacle specifics (`Recorder.qml`): the mode flag is the short letter (`--record=s`). To stop, call the same record command again with the **same `--output`**, guarded by `pgrep -x spectacle`. SIGINT, SIGTERM or DBus `quit` leave a corrupt mp4 or no file at all.

## Conventions

- **Write all documentation in English**: README, CLAUDE.md, any docs, commit messages and new code comments. The repo is shared with other users. The upstream comments and identifiers are in Spanish. Leave existing Spanish comments as they are unless asked to translate them, and don't rename identifiers.
- All user-visible strings go through `Cfg.t("CLAVE")`. Add a `["es", "en"]` pair to `Cfg.textos`; Plasma's i18n is deliberately not used, so the language switches live. Use `Cfg.esp` for one-off conditionals.
- Use `Theme` tokens for every color, size, duration and easing. Don't hardcode colors.
