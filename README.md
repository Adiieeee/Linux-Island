# Linux Island

A Nothing OS-style dynamic island for KDE Plasma 6. It sits in the middle of
your panel and works as a control center: clock, weather, media, network,
Bluetooth, sound, system meters, notifications, screen recording and power
actions.

Linux Island is a personal fork of **Nothing Dynamic Island** by Omar
(applet id `org.omar.nothingisland`, MIT license). The original is itself a
port of a Quickshell island from Hyprland to a Plasma widget, with the same
Nothing OS style, animations and content. This fork uses its own applet id,
`linuxisland`, so it can be installed next to the original.

## What this fork changes

- The applet id is `linuxisland` and the widget name is **Linux Island**, so
  it installs alongside the original instead of replacing it.
- The Wi-Fi card no longer shows a signal percentage. It shows **CONNECTED**,
  like Ethernet. In the original, the percentage was only read while the Wi-Fi
  panel was open, so the card showed 0% or a stale value. Signal strength per
  network is still listed in the Wi-Fi panel.
- The small island in the panel no longer shows the volume icon and
  percentage, and the "Volume" option under "Show in the small island" is
  gone. Volume lives in the expanded island.
- The small island fits its panel. It's as wide as its content (desktop dots
  and clock), the panel reserves exactly that width plus the mini player, and
  both pills are as tall as the panel. Before, the panel reserved 130 px for a
  pill drawn 150 px wide, so it spilled into the neighbouring widgets, and the
  pill was a fixed 27 px tall.
- Text uses your system font (Plasma's general font) instead of the bundled
  Space Grotesk and the NDOT 47 dot-matrix font, which are no longer shipped.
  Numbers use tabular figures so they don't jiggle as they change.
- Sound moved from a small third card next to Wi-Fi and Bluetooth to a
  full-width slider card below them (`SliderCard.qml`), so it's easier to
  adjust. The whole row height can be dragged, the mouse wheel steps 5%, a
  knob shows the level, and a tick marks 100%. Past 100% the bar continues in
  red up to the real 150% ceiling. Click the icon to mute, right-click for
  the output/input panel. Wi-Fi and Bluetooth now share the row at half
  width each. Changing the volume while muted now also unmutes. Before, the
  slider snapped back to muted.
- Click **SOUND** to open a dropdown, like KDE's own audio applet. Every output
  (laptop speakers, earbuds once they're connected, monitor speakers) and every
  input has its own level slider. Click a device's name to make it the default
  (a check marks the current one), click its icon to mute it. Outputs go up to
  150%, inputs to 100%. Lines above and below set the dropdown apart from the
  rows around it. Virtual devices such as Easy Effects only show when they're
  the default, and devices whose port is unplugged are hidden. The dropdown
  opens and closes with an animated height and a fade (the `Dropdown`
  component in `SliderCard.qml`), and so does the brightness one. The island's
  height follows the animation, so Plasma resizes the popup window on every
  frame of it.
- New **BRIGHTNESS** slider in the same card, for the screen the island is on.
  If the brightness of that screen can't be controlled, it falls back to the
  built-in panel. With more than one screen, click **BRIGHTNESS** to show the
  others below a dividing line: the built-in panel as **LAPTOP**, external
  monitors by model name.
  Drag or scroll to adjust. The slider never goes below 1%, because 0 switches
  some backlights off completely.
- In the Bluetooth and Wi-Fi panels, a connected device or network is easy to
  spot: its icon sits in a filled disc in the "on" colour (the inverted card
  colour), and its **Connected** line is in the full text colour. Saved and
  nearby entries keep a plain dim icon. Before, the only difference was a
  slightly brighter icon and a medium-weight name.
- Grey text is brighter, so secondary labels are readable. With the default
  colours the two text greys went from `#9A9A9A`/`#4E4E4E` to
  `#B3B3B3`/`#808080`. Section headings (**CONNECTED**, **NEARBY DEVICES**,
  …), "Searching…", empty-list messages, the app search placeholder, the
  expand arrows, the notification count and muted volume icons used to be
  drawn in the border grey (`#2A2A2A`) and were close to invisible. They now
  use the faint text grey. In the Wi-Fi and Bluetooth panels that was still
  too dark, so all their secondary text (title, section headings, row icons,
  expand arrows, "Searching…", the "off" message and the password
  placeholder) uses the brighter `fgDim`, like the secondary text in the main
  view. The recording view does the same for its unchecked toggle icons and
  the "Saved to …" line. The media card is left as it was: its artist line,
  times and placeholder icon use their own `Theme.mediaDim` token, which keeps
  the original `#9A9A9A`.
- The RAM meter shows how much is used next to the percentage, e.g.
  "68%  10.4", in the column where CPU and GPU show their temperature, so
  the three bars stay the same length. The number is in GiB (1024³ bytes),
  because `/proc/meminfo` counts in KiB. The unit isn't printed, to keep the
  row short. The setting that
  used to swap the percentage for used/total ("7.8/31") now turns this extra
  number on or off, and is on by default.
- Screen recordings go to `~/Videos/Screen Record` by default (created on
  the first recording, or when you open the folder), instead of straight into
  `~/Videos`. The **FOLDER** row in the recording view shows the current
  folder. **Change** opens a folder dialog, and **Default** (shown only for a
  custom folder) goes back to `~/Videos/Screen Record`. The choice is saved
  in the `recFolder` config key (empty = default) and survives restarts.
  Before, there were four fixed choices (`~/Videos`, `~/Pictures`,
  `~/Desktop`, `~/`), and the pick went back to `~/Videos` every time
  plasmashell started. The "Saved to …" line under the buttons is gone,
  because the folder row says the same.
- The recording view has a **MODE** row: **Full screen** (as before) or
  **Window**. In window mode, after you start, the cursor turns into a
  crosshair: click the window to record, or press Esc to cancel. Only that
  window's picture is recorded. Sound is still the whole system's (Spectacle
  can't record one app's audio). The mode is saved in the `recMode` config
  key (`s` or `w`) and also applies to the round button on the main card.
- The **COFFEE MODE** label is dim grey while off, like the other labels in
  the main view. It was the only one in full white.
- The lock button in the bottom row works. It called `qdbus`, which Plasma 6
  systems don't ship under that name (only `qdbus6`), so it silently did
  nothing. It now uses `busctl`, like the lock entry in the power panel. Clicking or scrolling the desktop dots
  had the same `qdbus` problem and now sets KWin's `current` desktop with
  `busctl set-property`.
- On the recording card in the main view, the round button starts recording
  right away (and stops it while recording). The rest of the card opens the
  recording view. Before, the whole card opened the view first, so starting
  took two clicks, and a click anywhere on the card stopped a running
  recording. Under the timer, three small icons show the current recording
  settings: screen or window, system audio, microphone. A setting that's off
  is fainter and uses the crossed-out icon.
- Recordings include sound. The **System audio** and **Microphone** toggles
  didn't reach Spectacle, so recordings were silent. See "Recordings had no
  sound" below.
- The bottom of the island is no longer cut off after a restart where
  PowerDevil answered late (see "So the island's height must not depend on
  data that arrives late" below).
- When Spectacle stops recording on its own (it failed to start, or it was
  stopped from its tray icon), the island notices and goes back to idle
  instead of counting forever.

## Install

```bash
git clone https://github.com/Adiieeee/linuxisland.git \
    ~/.local/share/plasma/plasmoids/linuxisland
kquitapp6 plasmashell && kstart plasmashell
```

Then right-click the desktop or a panel → **Add Widgets…** → search for
**Linux Island**.

To update, run `git pull` in that folder and restart plasmashell again.

### Requirements

The widget calls a few command-line tools. Without one of them, the matching
section stays empty, but the rest of the island keeps working:

| Section | Uses |
| --- | --- |
| Network, Wi-Fi | `nmcli` (NetworkManager) |
| Bluetooth | `bluetoothctl` |
| Sound | `wpctl`, `pactl` (PipeWire), plus Plasma's audio applet (plasma-pa) for the device dropdown |
| Brightness | Plasma's PowerDevil (built in). External monitors need DDC/CI support |
| GPU meter | `nvidia-smi` (hidden if missing) |
| Screen recording | `spectacle` |
| Coffee mode | `python3` with PyGObject (`gi`) |
| App launcher | `python3` |
| Weather | internet access to `wttr.in` |

## In its own panel (recommended)

Inside a shared panel, the island gets squeezed between the other widgets.
It looks better in a panel of its own.

The original author used a Plasma layout template
(`org.omar.island.panel`) that creates a normal Plasma panel with three
settings that make it invisible. **That template is not included in this
repo.** These are the settings it applies:

| Setting | Purpose |
| --- | --- |
| `backgroundHints = 4` | Turns off the background, so Plasma's grey frame doesn't show. |
| `lengthMode = "fit"` | The panel is exactly as wide as the island, nothing more. |
| `alignment = "center"` | Keeps it centered at the top. |

**Careful with `lengthMode`**: it takes a string (`"fit"`), not a number.
With `1` the property doesn't apply and the panel stays stretched across the
whole screen.

After moving the island into its own panel, remove it from the panel it was
in before, or you'll end up with two.

## Growing in place: tried, didn't work

`Island.qml` is the attempt: a single surface that animates its own width and
height, like on Hyprland, and asks plasmashell to enlarge the panel when it
opens. **It works outside Plasma** (tested with `qml-qt6`, and it looks
exactly like the Hyprland island), but inside a panel it fights three things
in Plasma itself:

1. **The panel reserves its height.** When it grows from 44 to 460, every
   window gets pushed down. The only modes that avoid reserving space are
   `autohide` and `dodgewindows`, and both hide the island, which is worse.
   `windowsgobelow` doesn't exist in Plasma 6: the value is accepted and
   silently becomes `none`.
2. **The panel centers the widget vertically.** With the panel at 460 the
   pill floats in the middle, not at the top, so the island doesn't grow
   downwards: it grows in both directions.
3. **The panel draws its background anyway.** With `backgroundHints = 4` it
   still paints `panel-background.svg`, which is opaque black. When it grows,
   a 460 px black block appears instead of a floating island.

Width **does** work on its own: with `lengthMode = "fit"` the panel
stretches and shrinks behind the island with no extra work.

That's why the island uses Plasma's popup. `Island.qml` stays in the repo,
unused, to pick up again if Plasma ever allows fixing the widget's alignment
and skipping the panel background. It still hardcodes the original applet id
`org.omar.nothingisland`.

## What changed from the Hyprland version

| Thing | How it ended up |
| --- | --- |
| Shape | Pill in the panel plus a popup on click. Plasma doesn't allow a free floating window like layer-shell does. |
| System tray | Removed. The tray belongs to `plasmashell` and can't be reimplemented inside a widget. |
| Workspaces | KWin virtual desktops instead of Hyprland workspaces. |
| Notifications | Reads Plasma's notification history; the widget is not the notification server. "Mute" turns on Plasma's Do Not Disturb. |
| Coffee mode | Handled by `contents/code/coffee.py`, see below. |
| Lock | `org.freedesktop.ScreenSaver` instead of `hyprlock`. |
| Recording | `spectacle --record=s` instead of `wf-recorder`, which only works on wlroots. Monitor and FPS can't be chosen from here. |
| Album art | Plasma already provides the resolved URL, so the `Cover` service is gone. |
| Sound | `wpctl` + `pactl` every second. Plasma's native module lists devices but doesn't expose to QML which one is active. |
| Dock and Settings | Removed on request. |

## What stayed the same

Clock, weather, network, Bluetooth, volume with a real 150% ceiling and a red
boost bar, battery, media player with album art and waveform, CPU / RAM / GPU
meters with the red flame, screen recording, coffee mode, the notification
strip, and the inner panels for Wi-Fi, Bluetooth, sound, notifications and
recording.

All design tokens live in `Theme.qml`.

## Widget settings

Right-click the island → **Configure Linux Island…**. Options:

- **Language**: automatic (the system's), Spanish or English. It only changes
  the island's texts, not the desktop.
- **Time**: 24-hour, or 12-hour with AM/PM.
- **Meters**: RAM used in GiB ("7.8") next to the percentage (on by default).
  Turn it off to show the percentage alone.
- **Show in the small island**: desktops, weather, clock, network, battery.
- **Player**: show or hide the mini player while something is playing.
- **Weather city**: leave it empty to detect it from your IP.

The values live in `contents/config/main.xml`. Adding a new one means
touching four files: that one, `ConfigGeneral.qml` (the control), `main.qml`
(the `Binding` that copies it) and `Cfg.qml` (where the rest of the code
reads it). QML singletons can't see `Plasmoid.configuration`, hence the
detour.

### Colours and fonts

Two more settings pages, `ConfigColores.qml` and `ConfigTipografias.qml`. You
pick four colours (background, cards, "on" i.e. the inverted card, and
alert), the two fonts, and the text colour. Each page has its own reset
button, which disables itself when everything is already at the defaults.

Plasma stores the values in `plasma-org.kde.plasma.desktop-appletsrc`, so
they survive restarts without the widget doing anything.

Three design details:

- **It asks for four colours, not twelve.** `Theme.qml` derives the
  intermediate steps (`surfaceAlt`, `surfaceHigh`, `surfaceTop`, `fgDim`,
  `fgFaint`, `outline`) by mixing the chosen colours with the text colour or
  the background in fixed proportions. With the default values they gave
  exactly the upstream greys, checked token by token, until the two text
  greys were brightened (see "What this fork changes"). If the user picks a
  light background the ramp adjusts on its own, because it's an
  interpolation and doesn't assume a dark background.
- **`outline` is for lines, not text.** It's only 16.5% of the way from the
  background to the text colour (`#2A2A2A` on black), which is fine for a
  border or a divider but unreadable as text. The dimmest text grey is
  `fgFaint`.
- **The inverted card's text colour is chosen by brightness**, not fixed to
  black. If someone makes that card dark, the text switches to white
  automatically.
- **Defaults are not repeated in the code.** The page declares empty
  `cfg_<key>Default` properties and Plasma fills them from `main.xml`. KDE's
  slideshow wallpaper does the same in
  `/usr/share/plasma/wallpapers/org.kde.slideshow/contents/ui/config.qml`.

**Careful with reset**: when you pick a colour or a font, the `ColorButton`
and the `ComboBox` write their own value, and that breaks the binding that
tied them to the configuration. That's why `restablecer()` (reset) sets each
control's value by hand on top of writing the key. Otherwise the reset
changed the stored value but the control kept showing the old one.

The icon font **can't** be changed, on purpose: the icons are Material
Symbols ligatures, and with any other font they show up as their names in
plain text.

**Changing the language didn't translate these two pages right away.**
`Cfg.esp` is the language already applied. The `Binding` in `main.qml`
overwrites it, and that only runs after you press OK. It is not the language
currently being chosen in the General page's combo box. `ConfigGeneral.qml`
already handled this with its own live `page.esp`, but Colours and Fonts were
still reading the one from `Cfg`, so changing the language and switching tabs
without accepting left them in the old language. The fix is the same: each
page declares its own `cfg_lang`, which Plasma connects to the same live
`KConfigPropertyMap` the General page uses (confirmed by the
`// type: KConfigPropertyMap` comment in
`/usr/share/plasma/shells/org.kde.plasma.desktop/contents/configuration/AppletConfiguration.qml`),
and computes `esp` from that value instead of importing the singleton.

## Fonts

Text uses Plasma's general font (System Settings → Fonts), so the island
matches the rest of the desktop. `Theme.qml` reads it from
`Qt.application.font`. The interface font and the numbers font can both be
overridden in the widget settings. By default, numbers use the interface
font.

Only the icon font ships inside the widget: `contents/fonts/MaterialSymbolsRounded.ttf`.
`Theme.qml` loads it with `FontLoader` and uses the name it returns, instead
of asking the system for it by name. This came from the original widget's
first bug report on the KDE Store. Requested by name on a machine where it
wasn't installed, the icons showed up as text (`skip_previous`,
`local_fire_department`).

The original also bundled Space Grotesk for text and NDOT 47 (a Nothing-style
dot-matrix font) for numbers. This fork removed both.

## Be careful when touching this (it crashed plasmashell)

The widget runs **inside** plasmashell: a bug here takes down the whole
desktop. These rules came out of a run of five crashes in a row (SIGSEGV in
the QML garbage collector, `QV4::MarkStack::drain`):

1. **Never use `property var` to hold an object created in place.** With
   `var`, the object belongs to the JS garbage collector, which can free it
   while C++ is still using it. Type it:
   `readonly property P5Support.DataSource source: P5Support.DataSource {…}`.
2. **Don't store callbacks that cross into C++ and back.** The original
   `Exec` kept functions in a dictionary and called them from `onNewData`.
   Now `Exec.run` is fire-and-forget. Anything that needs to read the output
   builds its own `DataSource` and dispatches by command string.
3. **No `MultiEffect` on a layer, here either.** `ExpandedPanel` used to blur
   its content with `layer.enabled` + blur when a panel opened (Wi-Fi,
   Bluetooth, calendar…). That's the same recipe that crashes the process,
   just in the file next door. It's gone. Now the content dims and shrinks
   slightly, and a black veil covers the whole island. This also removed a
   visible box 14 px from the edge: the layer and the veil only covered the
   inner area, so the frame around it stayed undimmed.

And an important one: **don't poll often**. At one point it launched five
processes per second from inside plasmashell. Now volume is checked every
1 s (one command), system stats every 3 s, network every 8 s, and the long
lists (nearby networks, audio and Bluetooth devices) only while their panel
is open, tracked with `watchers`.

## Power panel

The button with the power icon, in the bottom row of the island, opens a
panel with: lock, log out, sleep, hibernate, restart and shut down. Sleep and
hibernate only show up if the machine supports them (checked with
`CanSuspend` and `CanHibernate` on `org.freedesktop.PowerManagement`).

The four heavy options (log out, hibernate, restart and shut down) **ask for
confirmation in the same row**: the row expands downwards and you have to tap
"YES". One stray click on a small island shouldn't be able to take the
machine down.

Nothing uses `systemctl`. Everything goes through Plasma over DBus:
`org.kde.Shutdown` for log out, restart and shut down,
`org.freedesktop.PowerManagement` for sleep and hibernate, and
`org.freedesktop.ScreenSaver` for lock. That's what KDE's own power menu
does, so programs get a chance to save and the session closes in order
instead of everything being killed at once.

## The hover flash on buttons

The round buttons (lock, bell, power) and the panel rows lit up all at once
on hover and **then** faded down to a dim grey. It wasn't the animation: it
was mixing colour types.

The resting colour was an opaque grey (`#161616`) and the hover colour a
translucent white (`rgba(255,255,255,0.10)`). Animating from one to the
other, the halfway point is `rgba(128,128,128,0.55)`, a light grey, and that's
the flash.

Two rules to avoid it:

- If the resting colour is **opaque**, the hover colour must be opaque too:
  `surfaceAlt` → `surfaceHigh` → `surfaceTop`.
- If the resting colour is **transparent**, use `Qt.alpha(Theme.fg, 0)`
  instead of `"transparent"`. That way both ends are the same white and only
  the opacity moves.

## Other gotchas

- **`Plasma5Support.DataSource` already runs the command in a shell.**
  Wrapping it yourself in `sh -c "…"` runs it through TWO shells: the outer
  one eats `$h`, `$n` and `$(…)` before the inner one sees them, and the
  command fails silently (the CPU meter always showed 0% and 0°). Pass the
  bare script, without `sh -c` or extra quotes.
- **`VirtualDesktopInfo` is read-only.** It has no method to switch
  desktops. Switching goes through DBus, writing KWin's `current` property
  directly: `busctl --user set-property org.kde.KWin /VirtualDesktopManager
  org.kde.KWin.VirtualDesktopManager current s "<uuid>"`. The ids returned by
  `VirtualDesktopInfo.desktopIds` are those same UUIDs.
- **Don't call `qdbus` from the applet.** Plasma 6 systems ship it as
  `qdbus6` (or `/usr/lib/qt6/bin/qdbus`). Plain `qdbus` isn't on `PATH`, and
  `Exec.run` swallows the "command not found". Use `busctl --user`.
- **`ExpandedPanel`'s height can't be a fixed number like on Hyprland.**
  There the island grows with a hand-made spring. Here Plasma draws the popup
  at whatever size it's asked for. With a fixed `Theme.expandedHeight` (meant
  for the version with an app tray, which doesn't exist in this port) there
  was a leftover black strip at the bottom. Now the height comes from
  `mainColumn.implicitHeight`, the real content height, and `main.qml` pins
  `Layout.maximumHeight` to the minimum so Plasma doesn't stretch it.
- **Plasma remembers the popup size** in `popupHeight` / `popupWidth`, under
  `[Containments][N][Applets][M][Configuration]` in
  `~/.config/plasma-org.kde.plasma.desktop-appletsrc`. That value wins over a
  new `implicitHeight`. If you change the island's height, **stop
  plasmashell, delete those two keys and start it again**, or the old size
  keeps winning (and the black strip comes back even though the code is
  right).
- **So the island's height must not depend on data that arrives late.** The
  BRIGHTNESS row only exists once PowerDevil answers
  (`ScreenBrightnessControl.isBrightnessAvailable`). Once Plasma stored the
  height from before it showed up (`popupHeight=491` instead of ~526, exactly
  one 30 px row plus 4 px spacing), the bottom row of the island stayed cut
  off. `SliderCard` now shows a disabled stand-in BRIGHTNESS row while the
  island is on a built-in panel and no real row exists yet, so the height is
  the same from the first frame. If the backlight can't be controlled at
  all, the stand-in stays. External-only setups don't get it, since they may
  have no brightness row.
- **A child with `anchors.fill` inside a `Row` breaks the Row**: all its
  content disappears. It happened when the scroll-wheel `MouseArea` was put
  inside `Workspaces`, which was a `Row`, and the desktop dots vanished. Now
  the root is an `Item` with the `Row` inside and the `MouseArea` next to it.
- **To round an image, use `Kirigami.ShadowedImage`, not
  `Rectangle { radius; clip: true }`.** `clip` clips to the rectangle, not to
  the rounded shape, so the album art covered the corners and looked square,
  in both the player card and the mini player. `ShadowedImage` really rounds
  it, is the primitive Plasma itself uses, and has nothing to do with the
  `MultiEffect` that crashes the process.
- **An invisible item still takes up space for anchoring.** In `Meters`, the
  number was anchored to `tempRow.left` with a margin of 8 only when there
  was a temperature, and 0 otherwise. The RAM row has no temperature, but
  `tempRow` is still anchored to the right with its width, so the RAM number
  sat 8 px off and its bar was 8 px longer than the other two. The margin is
  now always the same. For the same reason, the widths of the percentage
  column and of the right-hand column (temperature, or RAM used) are
  decided once in the parent `Column` (`anchoValor`, `anchoLado`), not per
  row. Otherwise the RAM row widens on its own when it shows "10.4" and
  the bars end up different lengths again.
- **Plasma's audio models do say which device is the default, just not right
  away.** `Audio.qml` still polls `wpctl` because the original author found
  that plasma-pa's `SinkModel` didn't expose the active device. It does: right
  after creation every row reports `Default: false`, and the real values (and
  `PreferredDevice.sink` / `.source`) arrive a moment later, once the server
  info is in. Bind to them instead of reading them once in
  `Component.onCompleted`. The sound dropdown uses these models.
- **Numbers must not change width as they tick.** Most fonts have
  proportional digits. In Inter, `1` is 17 px wide at the clock's size and
  `0` is 27 px. In the original's NDOT 47 this made the clock change width
  every second, and the calendar button right next to it moved around. Every
  number text sets `font.features: Theme.numFeatures` (tabular figures,
  `tnum`), which makes all digits equally wide. Both clock texts also reserve
  their width with a `TextMetrics` whose template is the same text with every
  digit set to zero. That covers user-picked fonts without `tnum`.

## Things that were broken and aren't anymore

Several things had been ported wrong. All of them were found by checking which
API Plasma really exposes, not which API Quickshell had.

### The player couldn't seek

`MediaCard` called `SetPosition(trackId, …)`. **Plasma's MPRIS has neither
of those**: the player only exposes `Seek(offset)`, which moves by an amount
*relative* to the current position, in microseconds. Now it computes the
difference between the clicked point and the current position and sends
that.

### Coffee mode didn't inhibit anything

Two chained problems:

1. `systemd-inhibit --what=idle` registers a **logind** inhibitor, and
   PowerDevil ignores it when turning off the screen: it uses its own idle
   timer. It stopped the machine from suspending, but not the screen from
   turning off.
2. Switching to a `qdbus` call wasn't enough either: **KDE ties each
   inhibition to the DBus connection of whoever requested it, and releases
   it as soon as that process exits**. A `qdbus` call lasts milliseconds, so
   the inhibition lasted less than the command. The cookie came back fine and
   still nothing happened.

Now `contents/code/coffee.py` handles it. It requests three inhibitions
(`ScreenSaver`, `PowerManagement` and PowerDevil's `PolicyAgent`) and stays
alive with the connection open. On = launch it, off = kill it. When the
widget starts, it kills any leftover instance so the toggle and reality
match.

### Recording didn't start

`spectacle --record=screen`. The mode takes the **short letter**: `s` for
screen, `r` for region, `w` for window. With the full word Spectacle doesn't
recognise it and exits without recording.

### The recorded video came out corrupt

It was stopped with `pkill -INT -x spectacle`, copied from the Hyprland
version, where `wf-recorder` does finalize the file on SIGINT. Spectacle does
nothing with that signal: it dies on the spot and the mp4 ends up **without
the index that goes at the end** (the "moov atom"), the table that says where
each frame starts. The file had the data (half a megabyte of video) but no
player could open it. `ffprobe` said it plainly: `moov atom not found`.

Spectacle has no DBus method to stop recording (checked with
`busctl introspect`: only `RecordScreen`, `RecordRegion`, `RecordWindow`).
It doesn't handle SIGTERM either, and `quit` over DBus throws the recording
away. The right way, the same one the red dot in the tray and repeating the
keyboard shortcut use, is **to ask it to record again**: the second request
stops the current recording and finalizes the file properly.

Two details that were hard to find:

- **You have to repeat the same `--output`.** Without the path it also
  stops, but discards the recording: no file shows up, neither in the chosen
  folder nor in Spectacle's. That's why `stop()` uses `root.lastFile`.
- **It's guarded by a `pgrep -x spectacle`.** If the recording was already
  stopped some other way, the second request would start a new recording
  instead of doing nothing.

Tested end to end with the island's exact commands: 17 s recorded, and
`ffprobe` reads the duration and codec (h264 1920x1080) without complaint.

Separately: **starting a recording occasionally fails on its own**.
Spectacle exits immediately, with no file and nothing in the journal. That's
Spectacle, not the island (the command is identical both times). Pressing
again starts it.

### The FPS row wrote into nothing

It was left over from the Hyprland version, where `wf-recorder` does accept
an FPS value. Spectacle doesn't, so the property had been removed from the
service but the row still tried to write it. It's hidden now.

### Recordings had no sound

The **System audio** and **Microphone** toggles in the recording view only
set `Recorder.systemAudio` / `Recorder.microphone`; nothing passed them to
Spectacle. A recording made while music played had a single h264 stream and
no audio stream at all (`ffprobe`). Spectacle 6.8 can record both, but has
**no command-line flag** for it: it reads `videoRecordSystemAudio` and
`videoRecordMicrophone` from `[GuiConfig]` in `~/.config/spectaclerc`
(both off by default, see `/usr/share/config.kcfg/spectacle.kcfg`).

`Recorder.start()` now writes the two toggles there with `kwriteconfig6`
right before launching Spectacle. Side effects worth knowing:

- The island's toggles overwrite Spectacle's own "Record system audio" and
  "Record microphone" settings every time a recording starts.
- A Spectacle instance that is already running (its window open) keeps the
  config it loaded and ignores the new values.
- MP4 can carry audio. Only GIF and WebP can't, and the island always records
  to `.mp4`.

### Picking the recordings folder

The **Change** button runs `kdialog --getexistingdirectory` through
`Recorder`'s own `DataSource`, not a `FolderDialog` from QtQuick.Dialogs. The
island's popup hides as soon as it loses focus, and a Qt dialog opened from
it would lose its parent window inside plasmashell. `kdialog` is a separate
process, so that can't happen. On exit 0 its stdout is the path. Exit 1
means cancelled. `Recorder` is a singleton and can't write
`Plasmoid.configuration`, so it emits `folderChosen(path)` and `main.qml`
saves it. Paths go through `Recorder.quote()` now that they can contain
anything.

### Window mode

`spectacle --record=w` asks KWin to pick a window interactively (the
crosshair is KWin's `queryWindowInfo`). Esc makes Spectacle exit with
"Window recording canceled" and no file. The exit detection below brings
the island back to idle. `stop()` repeats the mode the recording started
with (`lastMode`), together with the same `--output`.

### The island kept "recording" after Spectacle had stopped

`start()` fired Spectacle with `Exec.run` and set `recording = true`. If
Spectacle quit on its own (the random start failure above, a stop from its
tray icon, and with window mode a cancelled window pick), the island kept
counting with nothing being recorded.

Spectacle stays alive for as long as it records, so `Recorder` now launches
it through its own `DataSource`, which answers when the process exits. The
command ends with `pgrep -x spectacle`. If a Spectacle window was already
open, the request goes to that window and the new process exits right
away. The `pgrep` then finds the open one and the island keeps showing
"recording". Otherwise the exit means the recording is over, and the island
goes back to idle. A stop from the island itself doesn't need this:
`stop()` already sets the state, and the late answer is ignored. So is the
answer for an older recording, matched by its command string (hard rule 2).

## The player's liquid background

Three blobs in the album art's colours move behind the player. Things that
took effort:

- **No `MultiEffect` on a layer.** It was the obvious way to blur
  (`layer.enabled` + blur), and it **crashes the process** after 10–25
  seconds with a segmentation fault. Reproducible, two out of two. Inside
  plasmashell that takes the whole desktop down, so don't even try it. The
  first replacement drew each blob as 14 concentric circles with very low
  opacity, which gives the same soft look without any shader. With few layers
  and high opacity you see the rings one by one; with many and low opacity
  they blend.
- **`Kirigami.ImageColors` doesn't download URLs.** Given the URL, it
  returns grey. Point it at the `Image` that already loaded the album art
  (`source: artImg`), and then it extracts the colours.
- **The colours come from `palette`, not `highlight` or `average`.** Those
  two are *computed* colours: `highlight` looks for the most vivid one and
  sometimes invents a colour that isn't on the cover, and `average` is the
  mix of all of them, a mud that isn't there either. That's why the
  background sometimes showed colours that weren't from the cover.
  `paleta.palette` is the real count of the image's colours, sorted by how
  much area each one covers. The first three are used.
- **Stacked concentric circles = visible lines.** The blob became 34
  circles, one inside the other, each slightly more opaque. Each circle has
  its own edge, and with any colourful cover you could see them: concentric
  lines across the background. Now each blob is **a radial gradient painted
  with `Canvas`**, which has no steps. Still no shader involved, which is the
  rule in here.
- **The gradient is painted at 220 px and stretched to its real size**
  (about 780). Painting the full 780 costs thirteen times more, and scaling a
  small one up lets the GPU's smoothing erase any leftover banding. It needs
  `smooth: true`, otherwise Qt scales it up crudely.
- **The opacity curve has to be wide.** It's `1 - e^(-1.15·(1-t²))`, which
  is exactly what the 34 circles added up to: it fills almost the whole blob
  and only fades to nothing at the edge. A faster falloff (`(1-t)^2.4`) was
  tried: the colour stays stuck in the centre and the card looks almost
  black.
- **The blobs are 1.4 times the card's width and move by their centre**,
  not their corner. Moving the corner keeps the dense centre always out of
  frame, so only the faded edge is visible.
- **When the song changes, the colour jumps instead of crossfading.** There
  used to be a 900 ms `Behavior on color`. With `Canvas` that would mean
  repainting three gradients every frame for a second, which is extra work
  inside plasmashell. The cover changes instantly anyway, so it isn't
  noticeable.

## Why videos don't show a thumbnail

Firefox doesn't publish `mpris:artUrl`, so there's no image to show. This was
confirmed by reading the browser's DBus output: it only sends the title.
Spotify does send it. To make the browser publish it too, install the
**Plasma Integration** browser extension (the `plasma-browser-integration`
package alone isn't enough; the extension is needed in the browser).

Without album art, the island shows the icon of the app that's playing
instead of a generic music note.

## Credits and license

- Original widget: **Nothing Dynamic Island** by Omar, MIT license.
- Fork: **Linux Island** by Adiieeee, MIT license. See [`LICENSE`](LICENSE).
- Bundled icon font: Material Symbols Rounded by Google, Apache License 2.0.
