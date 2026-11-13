# Developer notes

Why things are done the way they are, and the bugs and crashes found so far.
The hard rules (each one crashed plasmashell or caused a real bug) are in
[CLAUDE.md](CLAUDE.md). The long design log these notes come from is in the
git history (`git show a3b9bd4:README.md`).

## Centring between panel spacers

In a full-width panel with an expanding spacer on each side, Plasma's spacer
(`org.kde.plasma.panelspacer`) sizes itself to centre what's between the
two, but its formula has three flaws:

- **It counts the panel layout's own `Repeater`**, a visible 0 px child last
  in order, as one more widget on the right. With an 18 px spacing that
  pushed the island 8 px right.
- **It ignores `Layout` margins** (Panel Colorizer puts its widget margins
  there).
- **It uses the containment's width, not the layout's**: 1–2 px.

To cancel the phantom spacing, give the widgets right of the right spacer a
total margin smaller than the spacing (Panel Colorizer: Global Overrides).
Only the total counts. Qt shrinks both spacers, the left one by about 60 %
of the extra, so a margin moves the island by about 0.6 of its width. Total
margin that centres it, per Panel Colorizer spacing:

| Spacing | 4 | 6 | 8 | 10 | 12 | 14 | 18 |
|---|---|---|---|---|---|---|---|
| Right-hand margin total | 2 | 3 | 5 | 6 | 8 | 9 | 12 |

Give every auto-loaded Panel Colorizer preset the same spacing, since the
margins are global. Panel Colorizer also paints a white capsule around
widgets; the island is on its `blacklistedWidgets` in both presets (loading
a preset overwrites the blacklist). To check positions (23 is the panel id):

```bash
busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s 'var p = panels().filter(function (x) { return x.id == 23; })[0]; print(p.widgets().map(function (w) { var g = w.geometry; return w.type + " x " + g.x + " w " + g.width + " centre " + (g.x + g.width / 2); }).join("\n"));'
```

## Why a popup and not an island that grows in place

`Island.qml` (unused) grows its own surface, as on Hyprland. It works
outside Plasma but not in a panel: the panel reserves its full height and
pushes windows down (`windowsgobelow` doesn't exist in Plasma 6), centres the
widget vertically, and paints its background even with `backgroundHints = 4`.
Width alone does work (`lengthMode = "fit"`, a string, not `1`).

## The popup

- **It always has a frame**, even with `NoBackground`: Plasma's dialog
  background, as wide as the theme's margins (12 px with Ant-Dark).
  `ExpandedPanel` reads the window's `topPadding`, `leftPadding`… by name
  and reaches into the frame, leaving `Theme.popupRing` (4 px). The island
  can't be rounder than the frame's corners, so the author's Ant-Dark
  `dialogs/background.svg` was edited to radius 24 corners (original kept as
  `.orig`). After editing a theme SVG, stop plasmashell and delete
  `~/.cache/ksvg-elements` and `~/.cache/plasma_theme_<theme>.kcache`. With
  another theme, change `Theme.islandCorner` / `islandCornerPull`.
- **Plasma remembers its size** (`popupHeight`/`popupWidth`) and that wins
  over a new `implicitHeight`. `ExpandedPanel` nudges its height by 1 px for
  50 ms each time the popup shows, so Plasma applies the real height.
- **The height must not depend on data that arrives late.** The brightness
  row exists only once PowerDevil answers; a stored height from before cut
  the bottom off. `SliderCard` shows a disabled stand-in row until then.
- **Don't resize it for an animation.** Each resize of Plasma's popup costs a
  frame (measured in plasmashell: resizing per animation frame made a third
  of the frames late). The dropdowns float over the cards instead. When the
  height does change: every `implicitHeight` change reaches Plasma, even one
  undone in the same instant; a `Column` updates its height a frame late;
  and Plasma applies min, preferred and max one by one, so `main.qml` sets
  them in an order that keeps min ≤ max.
- **Plasma's "applet is open" line** under the panel is hidden by setting
  `expandedFeedback` invisible up the parent chain. If a Plasma update
  renames it, the line just comes back.

## Hover to open and close

- It closes 50 ms after the pointer leaves both the notch and the popup; 0
  would close it on the way in, since the notch's leave comes before the
  popup's enter. The popup's `HoverHandler` is on the root with the frame's
  padding as `margin`: a hover-enabled `MouseArea` blocks hover for items
  under it, not for its parents.
- KWin activates every window it shows, and `Qt.WindowDoesNotAcceptFocus`
  doesn't stop it. So `main.qml` remembers the active window when the
  pointer enters the notch and activates it again if the popup becomes
  active within 500 ms; a later click into the popup keeps the keyboard.
  `hideOnWindowDeactivate` is off for this.
- Every opening starts fresh: once the popup is hidden, `ExpandedPanel`
  closes the overlay and `SliderCard.reset()` the SOUND/BRIGHTNESS
  dropdowns. Their own state outlives the hide, so they came back open.
  `reset()` turns their animations off until the next click on a label, or
  a reopen within 280 ms caught them still closing.

## Media

- **Which player.** Plasma's MPRIS model has a multiplexer row next to one
  row per player; when the player rows came first, `currentIndex` stuck to
  one of them. `Media` reads the multiplexer's player directly, and with
  several playing `Media.pick()` ranks Spotify, then a browser, then the
  rest. Only players with a track count for the card's arrows.
- **Seeking.** Plasma's MPRIS has only a relative `Seek(µs)`, so the target
  is measured against the extrapolated position.
- **Browsers.** Zen's own MPRIS player gives no length on some videos, and
  none at all after a seek, so without a length the bar is disabled. Firefox
  sends no `mpris:artUrl`, so no thumbnail; without art the app's icon shows.
  The Plasma Integration extension fixes both.
- **Google Drive** sends no song info: the title is the viewer frame's
  ("Pelihat" in Indonesian, "Viewer"), the tab's title is the folder, and
  the album is the origin. `Media.title()` shows "Drive Audio Player"
  instead, and `Lyrics` skips the lookup. The file name exists only in
  Drive's page.
- **Previous / next** are disabled until the player reports the new track
  (0.4–1.5 s; YouTube via Plasma Integration takes ~0.9 s), and greyed out
  when `canGoPrevious`/`canGoNext` is false (YouTube outside a playlist).
- **Raise.** On Wayland a browser can't bring its own window forward, so
  after MPRIS `Raise` the card activates the player's window through
  `TaskManager.TasksModel.requestActivate`.

## The media card's colours

- Blobs are radial gradients painted by `Canvas` at 220 px and stretched with
  `smooth: true`; blur (`MultiEffect`, `layer.enabled`) crashes plasmashell,
  and stacked circles showed rings. Opacity curve `1 - e^(-1.15·(1-t²))`.
  Blobs are 1.4× the card's width, move by their centre and start on their
  path.
- Colours come from `ImageColors.palette` (real colours by area), not
  `highlight` or `average`. `ImageColors` needs the loaded `Image`, not a
  URL, and a cover already in Qt's cache never changes `status`, so
  `artImg.onSourceChanged` calls `paleta.update()` through `Qt.callLater`.
  The notch's tint has the same fix.
- Animations keep running in a hidden window (~144 updates a second), so
  the blobs use `paused` while the popup is hidden. Not `running: false`,
  which restarts them, and `paused` is ignored on a stopped animation.

## Lyrics

- From LRCLIB by XHR (never through a shell): `/api/get`, then
  `/api/search`, then a search with version notes stripped from the title.
  A result counts only with synced lines and a duration within 3 s.
- Only HTTP 200 and 404 are answers. 503/429 and network errors retry after
  2, 5, 10, then every 20 s. The last 30 answers are cached.
- No polling: the playhead is extrapolated from the last MPRIS position and
  one single-shot timer is set for the next change, with a re-sync every
  5 s. A paused player sends no `positionChanged`, so a new song starts from
  the last known position, not 0.
- A line shows 0.3 s early, gaps of 4 s or more show ♪, a line counts as
  over 10 s after it starts (6 s for the last). Long lines slide once
  (`MarqueeText`). The notes are vector paths (`NoteGlyph`) because ♪ and ♫
  look different in every font.

## Waveform

- The level comes from plasma-pa's `VolumeMonitor` on the default sink, the
  meter Plasma's audio applet uses; its target is `null` while not playing,
  which closes the stream. `DataSource` only returns output once a command
  exits, so cava or a helper would mean spawning processes many times a
  second.
- Height is loudness (short average against the recent peak, so quiet
  masters aren't small) plus motion (±3 dB around that average). A fixed dB
  scale and a scale relative to the peak both failed: songs are mastered
  10 dB apart, and loud pop sat near the top 97 % of the time.
- PipeWire leaves monitor ports at full level, so the volume slider doesn't
  shrink the bars.

## Alerts in the notch

- `Alerts` holds one alert; `CompactPill` shows it in the middle (mode
  `"alert"`, before every other mode) and `AlertView` draws it. Every
  source is a live signal from Plasma's own models; nothing polls.
- KDE's OSD can't be hidden from a widget: plasmashell draws it whenever a
  component calls `org.kde.osdService`. Volume: plasma-pa has its own
  switches (Sound → Configure Volume Controls…). Brightness: PowerDevil
  has none, see below.
- `armed` turns on `Theme.alertArmDelay` after start: the models report
  their first values then, which aren't changes. `paused` (the control
  center is open) drops alerts: its sliders show the levels already.
- A new default output reports its own volume as it comes in, which
  replaced the alert naming it. The volume stays quiet for
  `Theme.alertQuietMs` after `PreferredDevice.sink` changes.
- The microphone alerts on mute only: WebRTC's automatic gain control (a
  call in Chrome) moves the input's level all the time.
- **Brightness.** PowerDevil's keys always call the OSD (no setting), so
  the README gives the keys to `AdjustBrightnessStepWithContext(step, 1,
  "linuxisland")`: flag 1 skips `osdService.screenBrightnessChanged`
  (checked with `dbus-monitor`; flag 0 calls it), step 0/1/2/3 = up, down,
  small up, small down. `BrightnessChanged` carries that context, so only
  those keys alert, not idle dimming or the sliders. Read with
  `SignalWatcher` (`org.kde.plasma.workspace.dbus`): it calls
  `dbus<Signal>(…)` on itself, strings wrapped as `{value}`.
- **Clipboard.** Klipper's `HistoryModel` (`org.kde.plasma.private.clipboard`)
  is shared inside plasmashell with the clipboard applet; `currentText`
  changes with each new copy, and row 0 gives the text (`DisplayRole`) or
  a picture's URL (`DecorationRole`). Item types: 2 text, 4 image, 8 URL.
  It's only made inside plasmashell (`Qt.application.name`): in the `qml`
  tool it starts a second Klipper, which crashed offscreen (X11 call in
  `SystemClipboard`) and could write to the same history database.
- **Over fullscreen.** The floating notch (`gameNotch`, layer-shell
  Overlay) also shows while `Alerts.showing` when "Keep the notch over
  games" is off (`alertOnly`). Then it has `Qt.WindowTransparentForInput`,
  so the game keeps every click, `openFromNotch()` ignores it, and the
  pill fades out (`alertFade` keeps the window up for the fade).
- Offscreen tests draw `Kirigami.ShadowedImage` as a white box; a plain
  `Image` draws fine there. In plasmashell both work.

## Recording (Spectacle)

- The mode is the short letter (`--record=s`, `w`). To stop, request the same
  recording again with the same `--output`, guarded by `pgrep -x spectacle`;
  SIGINT, SIGTERM or DBus `quit` leave a corrupt mp4 or no file.
- Sound has no command-line flag: `Recorder.start()` writes
  `videoRecordSystemAudio` / `videoRecordMicrophone` to `spectaclerc` with
  `kwriteconfig6` first. A Spectacle window already open ignores them.
- Spectacle is launched through `Recorder`'s own `DataSource`, ending with
  `pgrep -x spectacle`, so the island notices when it exits on its own (it
  sometimes fails to start, for no visible reason).
- The folder picker is `kdialog`, a separate process; a Qt dialog from the
  popup loses its parent window.

## Coffee mode

- A logind inhibitor (`systemd-inhibit`) doesn't stop PowerDevil dimming the
  screen, and KDE drops an inhibition when the DBus connection that asked for
  it closes, so `coffee.py` holds three of them for as long as it runs.
- `pkill -f coffee.py` killed the `sh -c` running it, whose command line
  contains the same name; match `^python3 <full path>` instead.
- To check (allow ~5 s, PowerDevil delays new inhibitions):

  ```bash
  busctl --user get-property org.kde.Solid.PowerManagement \
    /org/kde/Solid/PowerManagement/PolicyAgent \
    org.kde.Solid.PowerManagement.PolicyAgent ActiveInhibitions
  ```

## Other gotchas

- `qdbus` isn't on `PATH` in Plasma 6 (only `qdbus6`), and `Exec.run`
  swallows the error: use `busctl --user`. `VirtualDesktopInfo` is
  read-only; switch desktop with `busctl --user set-property org.kde.KWin
  /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager current s
  "<uuid>"`.
- plasma-pa's `SinkModel` does say which device is the default, a moment
  after it's created; bind to it rather than reading it once.
- Plasma removes a notification from its history when the app closes it
  (chat apps do, once read), so `Notifs` keeps its own copy (up to 100, in
  memory). Formatted bodies arrive as XHTML starting with `<?xml`; the copy
  strips them to plain text.
- wttr.in sends weather codes outside the standard 48 (149, "Smoky haze");
  those get an icon from the description. Night comes from wttr.in's
  sunrise and sunset against the local clock.
- The meters, volume and network state are read only while the control
  center is open: always polling cost ~1.6 % of a core and kept the NVIDIA
  GPU awake.
- An invisible item still takes part in anchoring: `Meters` decides its
  column widths once in the parent (`anchoValor`, `anchoLado`).
- Proportional digits make clocks change width: tabular figures plus a
  `TextMetrics` on an all-zeros template.
- Testing offscreen (`qml` with `QT_QPA_PLATFORM=offscreen`) shows layout
  bugs, not the cost of a real popup resize. `console.warn` goes to the
  journal.

## Unexplained startup crash (2026-11-12)

The first start after `f439391` and `b83c7e5` crashed twice in a row about
2 s in, right after Panel Colorizer loaded, then ran fine on the next manual
start. One core was a SIGSEGV in `QV4::MarkStack::drain` (GC), the other in
an AOT-compiled binding in `liborg_kde_plasmacomponents3.so`. Nothing in
those commits matches a known cause. If it happens again: `coredumpctl list
plasmashell`, `coredumpctl info <pid>`, and the journal around it.
