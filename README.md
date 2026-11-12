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
- The small island fits its panel. It's as wide as its content and the panel
  reserves exactly that width. Before, the panel reserved 130 px for a pill
  drawn 150 px wide, so it spilled into the neighbouring widgets, and the
  pill was a fixed 27 px tall.
- The small island is one black shape instead of two pills: the album art
  on the left (round), the date (or the lyrics, see below) in the middle, and
  a waveform on the right. With no song it shrinks to today's date, with an
  animated width. The previous, play
  and next buttons are gone (the control center has them), and so is the
  capsule tinted with the album's colour, which turned white with light
  covers. The island is as tall as the panel: the panel insets every
  applet by its theme's margins (4 px above and below with Ant-Dark), and the
  island reaches past its slot by that much (`CompactPill.reach`, capped at
  the theme margin so a floating panel isn't overshot). The album art sits
  close to the left side; the waveform sits 6 px further in from the right
  (`CompactPill.edge`).
- The desktop dots are back, outside the notch on its left, on the panel
  itself. They're all in the text colour (white by default), because greys
  got lost on a light wallpaper, and their shape tells them apart: the
  current desktop is a long pill, a desktop with windows a filled dot, an
  empty one a ring. Clicking a dot switches to that desktop
  (`Workspaces.clickable`); each dot's hit area is 24 px tall and reaches
  halfway to its neighbours, so the small dots are easy to hit. Hovering a
  dot turns its border black (the island's `Theme.bg`) and lights a white
  glow behind it that fades out 6 px past its edge, a little brighter while
  pressed; the pointer becomes a hand. Two lighter tries came first: the
  control center's translucent hover layer around the dot was nearly
  invisible on the panel, and a thin black ring around that layer still
  got lost on a dark wallpaper. The glow is the one shadow-like effect
  outside the notch, and like the notch's tint it's a radial gradient on a
  `Shape`, not a blur (blur crashes plasmashell). The current
  desktop gets neither, since clicking it does nothing. The wheel
  over the dots steps one desktop per notch, up for the left one and down
  for the right one, stopping at the ends (`Workspaces.scrollable`). It
  counts 120 units of wheel travel per step, not one step per event, since
  a touchpad sends many small events per swipe. Both sides of the notch take the same width, the wider of
  the two plus a 12 px gap, so the notch and the popup under it stay in the
  middle of the screen.
- The clock moved out of the notch to its right, on the panel, in white
  (`Clock.qml`). It's always 24-hour with a leading zero (`HH:mm`), 13 px
  bold (`Theme.islandClock`; 17 and 15 looked too big), and as wide as "00:00" whatever the digits, so the
  notch never shifts as it ticks. The **Time** setting now only sets the
  control center's big clock. Inside the notch, today's date takes the
  clock's old place: "11 November 2026" when the notch holds nothing else,
  "11 Nov 2026" between the album art and the waveform when the lyrics are
  turned off. Both are 12 px bold in the clock's font with tabular digits,
  so the date and the clock read as one style. The month follows the
  widget's language.
- Each part of the panel island has its own small lift above the true
  centre, tuned by eye on screen (`Theme.dotsLift`, `artLift`,
  `middleLift`, `waveLift`, `clockLift`): 1 px for the desktop dots, the
  waveform and the clock, 2 px for the album art and the notch's middle
  (date, lyrics, notes). It started from a screenshot of the panel: the
  text and notes had more room above than below (♫ 16 px over 14 at the
  screen's scale, text 13 over 12 in a 34 px notch). The album art also
  sits 1 px right of its inset (`Theme.artNudge`).
- Only the notch opens the control center. The compact representation is a
  plain `Item` and `CompactPill` puts the hover area on the notch alone, so
  the dots and the empty space beside the notch don't open it (a click on
  the dots switches desktop).
- Moving the pointer onto the notch opens the control center at once. It
  started with a 300 ms wait, then 100 ms; both felt slow. Clicking the
  notch does nothing: it used to toggle the popup, which with hover
  opening it meant a click closed it. The notch's `MouseArea` accepts no
  buttons, so clicks fall through to the panel, and the pointer stays the
  plain arrow.
- Opening the control center on hover no longer takes the keyboard from
  the app being typed in. KWin activates every window it shows, so the
  popup still gets the keyboard for a moment, and gets it handed back: on
  entering the notch the active window is remembered (Plasma's
  `TaskManager.TasksModel`, its `WinIdList`), and if the popup becomes
  active within 500 ms (`Theme.keyboardReturnWindow`), that window is
  activated again. A later activation, a click into the popup to type the
  Wi-Fi password, keeps the keyboard there. `Qt.WindowDoesNotAcceptFocus`
  on the popup was tried first and doesn't work: Qt drops
  `requestActivate()`, but a test window with the flag still came up
  active, since KWin activates it on showing it. `hideOnWindowDeactivate`
  is off, or Plasma would close the popup the moment it lost focus; the
  hover timer closes it instead, so clicking outside no longer does.
- The control center closes on its own as soon as the pointer is off both
  the notch and the popup, however it was opened. It waits 50 ms
  (`Theme.hoverCloseDelay`), too short to notice: 400 and 200 ms felt slow,
  and 0 would close it on the way in, because moving from the notch into
  the popup the notch's leave arrives before the popup's enter. The popup's
  `HoverHandler` sits on `ExpandedPanel`'s root with a `margin` as wide as
  Plasma's frame, so the frame ring around the island counts as inside and
  the pointer coming down from the notch (which reaches the panel's edge)
  never crosses a strip that counts as outside. It has to be on the root:
  a hover-enabled `MouseArea` blocks hover to items under it, though not
  to its parents. It stays open while a slider
  dragged past the edge is still held (a `HoverHandler` keeps `hovered`
  until the press is released) and while the Wi-Fi password field has the
  keyboard, wherever the pointer is (`ExpandedPanel.engaged`).
- Opening the control center no longer draws a pale line along the
  panel's bottom edge under the island. That's Plasma's "this applet is
  open" mark (`expandedFeedback` in Plasma's `CompactApplet.qml`, drawn
  with the theme's `widgets/tabbar` `north-active-tab`; Ant-Dark makes it a
  3 px `#9bbfbf` line at 80 % opacity). The notch covered it in the middle,
  so it showed under the dots and the clock. Plasma has no setting for it:
  the compact representation walks up its parents to the item that has
  `expandedFeedback` and sets that item's `visible` to false, which drops
  Plasma's `visible: opacity > 0` binding. Other widgets keep their mark.
  If a Plasma update renames the property, nothing is found and the line
  just comes back.
- Hovering the island no longer shows Plasma's tooltip with the time and
  the weather. `toolTipMainText` and `toolTipSubText` are set to empty
  strings on purpose: left unset, Plasma shows the applet's name instead.
- The small island is shaped like a laptop's or an iPhone X's notch instead
  of a capsule (`NotchShape.qml`): flat along the screen's top edge, round
  bottom corners (`Theme.notchCorner`, 14 px), and a small concave flare at
  each top corner that curves its sides out into the screen edge
  (`Theme.notchEar`, 7 px each side). It's drawn with `Shape` and the
  `CurveRenderer`, like the control center's outline, so it's antialiased
  without a layer. On a panel at the bottom of the screen it hangs from the
  bottom edge instead. It only looks attached to the edge on a panel that
  isn't floating.
- The small island is black, like the control center (the same
  `Theme.surface`). With **Colour the island with the album art** on in the
  settings (off by default), while a song with album art plays or is
  paused, it takes the cover's colours, like the media card in the control
  center: three
  soft blobs in the cover's palette (`Kirigami.ImageColors`, the same three
  colours the card uses) under the same 45% dark veil, so the white text
  stays readable. With just the date it's plain black again; the change
  fades over `Theme.durLong`. Each layer is one more `ShapePath` over the
  notch's outline (a radial gradient per blob), so the colour follows the
  notch's curves without a clip or a mask, which would need a layer. The
  blobs copy the card's: 1.4 times the width across, stacked in the same
  order, each centred halfway along the path the card's blob travels. The
  first version used smaller blobs with the cover's first colour alone at
  the left end, and showed colours the card hides (a blue the card covers
  with tan and maroon). Unlike the card's blobs, these don't move, so the
  two match on average rather than frame by frame: an always-visible panel
  widget animating every frame would keep the panel repainting. Like the card, it
  bends the monochrome rule in `Theme.qml` on purpose. A very light cover
  comes out mid-grey.
- The small island's waveform follows the real audio. Five bars show the
  level of everything the speakers play: the newest level in the middle bar,
  older ones moving out to both sides, so a beat looks like a pulse leaving
  the centre. It reads Plasma's own live level meter (plasma-pa's
  `VolumeMonitor`, the one the audio applet draws in its sliders), only while
  something plays. The volume slider doesn't shrink the bars, and quietly
  mastered songs are scaled up. Loud music sits around half height and
  moves, instead of looking full all the time. While paused the bars
  rest low and dim. Before, four bars moved on a fixed animation whatever
  was playing. See "The real waveform" below.
- The small island shows synced lyrics. While a line is being sung, the
  island widens to a fixed width (`Theme.lyricsWidth`, 280 px for the
  middle, the same for every line, so it doesn't resize on each one) and the
  line takes the middle, in an 11 px font (`Theme.labelMedium`). At
  13 and 12 px too few words fitted, and most lines slid, which was tiring
  to read. A line too long for that width waits a moment, then slides once to
  show its end within the time it's sung. Each new line fades in from below
  while the old one fades out upwards. During the intro, the outro and
  instrumental breaks of 4 seconds or more the island shrinks around one
  eighth note (♪). A song without lyrics (instrumental, not on LRCLIB, or
  with no title to look up) shows two eighth notes joined by one beam (♫),
  like the Windhawk island this follows. Both are drawn as vectors
  (`NoteGlyph.qml`). A video in the browser (YouTube) shows the date
  ("11 Nov 2026") instead of a note: a video without lyrics isn't a song
  without lyrics. Plasma's MPRIS module doesn't give QML the page's
  address, so `Media.isBrowser()` goes by the app (Zen, Firefox, Chrome and
  other browsers by their desktop entry or name). Its lyrics are still
  looked up, so a music video with lyrics shows them. Pausing changes nothing in the middle: the line, ♪ or
  ♫ stays, and a sliding line holds where it is; the waveform resting dim
  shows the pause. Lyrics come from LRCLIB (lrclib.net). See "Lyrics in the
  panel island" below.
- The control center's bottom row has a lyrics button (the `lyrics` icon)
  where the app launcher's button was. It turns the small island's lyrics on
  and off, the same switch as **Show synced lyrics** in the settings, and
  it's filled white (the inverted pair, like coffee mode) while on. The app
  launcher wasn't used, so it's gone too (`AppLauncher.qml` and the
  `apps.py` helper that listed the installed apps for it).
- When a song starts playing, the small island shows its title (12 px bold)
  over its artist (10 px, grey) for 4.5 seconds at the lyrics' width, then the lyrics or
  the date. Every song gets this once, with or without lyrics: a track
  change, the first song after plasmashell starts, another player taking
  over, or a song that was paused when found, once it plays. Pausing
  doesn't cut it short. With the lyrics off there's no peek. Long titles slide like long lyric
  lines.
- With more than one player (Spotify and a browser tab with YouTube, say),
  the panel island always shows the one that's playing. It used to stick to
  whichever player happened to be first: Plasma's MPRIS model lists a
  "multiplexer" row (its own pick: the player that's playing, else the last
  active one) next to one row per player, and when the player rows arrived
  before the multiplexer row, the model's `currentIndex` stayed on a player,
  so the island showed a paused YouTube while Spotify played. A single
  `Media` singleton now owns the MPRIS model and reads the multiplexer row's
  player directly (`Media.active`); the island and the media card use it.
- After previous or next, both turn grey and can't be pressed until the
  player reports the new track, so a second press doesn't land while a
  browser is still loading the next video. Measured: YouTube through the
  Plasma Integration extension reported the new title after ~470 ms and
  the loaded video (its length) after ~870 ms; Spotify after 10-20 ms.
  The wait is at least 0.4 s (a double click doesn't skip twice) and at
  most 1.5 s, for a player that ignores the command. They are also grey
  while the player says it can't go there (`canGoPrevious` /
  `canGoNext` false): YouTube only offers previous and next inside a
  playlist, so on a single video a press did nothing. That was the "next
  stopped working" in the tests: after the first next, YouTube landed on a
  video outside the playlist and reported both as unavailable. With neither
  available (YouTube outside a playlist) both buttons are hidden; with one
  of them both stay and the missing one is grey, so a playlist's first
  video still shows previous.
- The media card has shuffle and repeat buttons beside previous and next,
  for players that have them (Spotify; browsers usually don't, and then
  they're hidden). On is white with a dot under the icon, off is the card's
  dim grey. Repeat cycles off → repeat all → repeat one (`repeat_one`), like
  Spotify's own button. They set the player's MPRIS `Shuffle` and
  `LoopStatus`, which Spotify accepts (tested: it reports the new value
  back).
- The media card's progress bar can be dragged, not only clicked. While
  it's held, the bar and the elapsed time follow the pointer, and the seek
  happens on release; dragging past either end clamps there, so the start
  of a track is easy to reach. The target is measured against where the
  player is now (the last reported position plus the time since, since
  the position is only asked for once a second), because MPRIS here only
  seeks relative to the current position.
- The media card's progress bar doesn't pretend when the player gives no
  time. Zen's own MPRIS player with YouTube reports position 0 and no
  length on some videos, and on the others stops reporting both after any
  seek (measured: at 56 s, a 3 s seek, then position 0 and no length from
  then on while the video kept playing). Clicking the bar then made it
  jump to the start. Without a length the bar is now plain grey, can't be
  clicked, and the times are hidden. For a seekable bar with browser video,
  install the **Plasma Integration** extension in the browser (the
  `plasma-browser-integration` package is the host side): it reports the
  video element's real time and length. In a Firefox-based browser, also
  set `media.hardwaremediakeys.enabled` to `false` in `about:config`, so
  the browser's own player doesn't show up next to the extension's.
- Clicking the media card's album art or title opens the player and closes
  the control center: it asks the player to show itself (MPRIS `Raise`).
  Spotify comes to the front; Firefox-based browsers such as Zen also
  switch to the tab that's playing. On Wayland a browser isn't allowed to
  bring its own window forward (KWin's focus stealing prevention), so Zen
  switched the tab but stayed behind other windows. A quarter of a second
  after `Raise`, the card activates the player's window itself through
  Plasma's task manager (`TaskManager.TasksModel.requestActivate`, which
  plasmashell may use): the window of the player's process, or failing
  that of its app, preferring one that's demanding attention, else the
  one used last. A player that can't be raised (`canRaise` false) ignores
  the click.
- When several players play at once, the island follows Spotify first,
  then a browser (YouTube), then anything else. Plasma's own pick keeps
  the one that started first, so YouTube stayed in the island while
  Spotify played too. With one player playing, or none, Plasma's pick
  stands (the playing one, else the last active). `Media.pick()` holds the
  rule as a plain function, tested with fake players.
- The media card in the control center has arrows at its left and right
  edges to switch between players, shown only when there's more than one.
  Only players with something loaded count: a track, playing or paused. A
  browser or Spotify left open with nothing in it (or stopped) still has an
  MPRIS player, and counting it put arrows next to a lone YouTube video that
  led to an empty "Nothing playing". The list is rebuilt whenever a
  player's track or state changes, not only when players come and go.
  The card's content moves in to make room. Without a pick it follows the
  playing player; stepping back onto that player follows it again, and a
  picked player that closes goes back to following. The panel island keeps
  showing the playing one either way.
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
  150%, inputs to 100%. Virtual devices such as Easy Effects only show when
  they're the default, and devices whose port is unplugged are hidden. The
  dropdown (and the brightness one) floats over the cards below instead of
  pushing them down, and opens with a height reveal and a fade, the same
  speed and curve as the island's other expansions (`durMedium`,
  `emphasized`). A long list scrolls instead of running past the island's
  bottom. A click anywhere else on the island closes it. See "Don't resize
  the island for an animation" below for why it floats.
- New **BRIGHTNESS** slider in the same card, for the screen the island is on.
  If the brightness of that screen can't be controlled, it falls back to the
  built-in panel. With more than one screen, click **BRIGHTNESS** to show the
  others below a dividing line: the built-in panel as **LAPTOP**, external
  monitors by model name.
  Drag or scroll to adjust. The slider never goes below 1%, because 0 switches
  some backlights off completely.
- The CPU, RAM and GPU meters and the volume are only read while the
  control center is open. Before, `nvidia-smi` and the CPU/RAM read ran
  every 3 seconds and `wpctl` every second with the island closed (together
  ~1.6% of a core, measured), and `nvidia-smi` kept the NVIDIA GPU awake.
  Opening starts them at once; the CPU figure gets its second reading
  0.6 s later instead of 3 s, since it's the difference of two readings.
  One reading still runs at start, so whether there's a GPU row is known
  before the island first opens (a row appearing after it opened would
  resize it).
- The Bluetooth card names the connected device (e.g. "soundcore R50i NC"). It used to say
  **ON** until the Bluetooth panel had been opened once, because the device
  list is only fetched while that panel is open. The regular tick now also
  runs `bluetoothctl devices Connected`, in the same command as before.
  That tick (Wi-Fi and Bluetooth state, every 8 s) only runs while the
  control center is open, like the meters, and its first reading runs as
  soon as it opens, so the cards are right from the start. It only reads
  the state: the drivers, NetworkManager and bluez work the same.
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
  the "Saved to …" line, and so does the **CALENDAR** hint under the date
  (full white on hover). The media card is left as it was: its artist line,
  times and placeholder icon use their own `Theme.mediaDim` token, which keeps
  the original `#9A9A9A`.
- The RAM meter shows how much is used next to the percentage, e.g.
  "68%  10.4", in the column where CPU and GPU show their temperature, so
  the three bars stay the same length. The number is in GiB (1024³ bytes),
  because `/proc/meminfo` counts in KiB. The unit isn't printed, to keep the
  row short. Temperatures and the RAM number are right-aligned. The setting that
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
- The notification panel (the bell) keeps every notification. It used to
  list Plasma's own history, and Plasma removes a notification from that
  history as soon as the app that sent it closes it. Chat apps do that all
  the time (ZapZap and LINE in Chromium close theirs once the message is
  read, or replace them with a newer one), so only things like Claude or a
  missed call ever showed. `Notifs.history` now copies each notification as
  it arrives (and the ones already there when plasmashell starts) and keeps
  it until you dismiss or clear it in the panel. A notification updated in
  place with new text (a chat's "2 new messages") moves to the top with
  that text; one that only expires or is read stays as it is. The source
  model also takes every urgency and the ones that arrived during Do Not
  Disturb. Up to 100 are kept, in memory, so a plasmashell restart starts
  from what Plasma still has. The list is grouped in folders, one per app
  (`Notifs.groups`): an app with several notifications shows one row with
  its newest, its time and a count, and opens with a click to list them
  all, so one busy chat doesn't fill the list; an app with one shows it
  directly. The cross on a folder clears that app. Each notification shows
  its title (a chat's sender, 13 px), two lines of its text (12 px in the
  full text colour; it was 10 px grey and hard to read), its own picture
  when it sends one (a chat's sender or group photo, from the
  notification's icon; else the app's icon), smaller inside a folder; at
  first only the folder's row had a picture, so a chat's photo seemed to
  vanish after the first message. Then its time, and for a
  browser's notification the site or extension behind it ("LINE"). The
  list scrolls with the wheel or a drag once it's taller than 300 px, with
  the same thin scroll bar as the Wi-Fi list; before, it had no scrolling
  and ran past the island's bottom. A body with formatting (bold, links)
  comes from Plasma as an XHTML fragment that starts with
  `<?xml version="1.0"?>`; shown as is, ZapZap's messages read as that
  code. The copy keeps plain text instead: tags dropped, line breaks kept,
  `&amp;` and friends turned back into characters. A body without that
  wrapper is already plain and stays as it is. The **CLEAR** button is as bright as **MUTE**
  next to it; with nothing to clear it used to drop to 40% opacity and
  looked switched off. It still does nothing then.
- The strip that showed a new notification at the bottom of the control
  center for 5 seconds is gone. Plasma's own popups already show every
  notification, and the strip, which grew the island by 62 px while it
  showed, stacked badly. The bell in the bottom row still opens the
  notification history, with its mute and clear buttons.
- Texts that were still in Spanish with the widget in English are
  translated: the notification panel's count ("3 IN THE TRAY", hardcoded as
  "EN LA BANDEJA" in both languages), coffee mode's entry in Plasma's power
  applet (it registered as "Isla" / "Modo café", now "Linux Island" /
  "Coffee mode"), and the Spanish option in the language picker, which an
  English settings page now calls "Spanish".
- The **COFFEE MODE** label is dim grey while off, like the other labels in
  the main view. It was the only one in full white.
- Coffee mode works: while it's on, the screen doesn't dim, turn off or
  lock on its own, and the computer doesn't suspend on its own. Before, the
  toggle turned on but the helper never started, so nothing was inhibited
  (see "Coffee mode didn't inhibit anything" below). PowerDevil applies a
  new inhibition about 5 seconds after it's requested.
- The lock button in the bottom row works. It called `qdbus`, which Plasma 6
  systems don't ship under that name (only `qdbus6`), so it silently did
  nothing. It now uses `busctl`. Clicking or scrolling the desktop dots
  had the same `qdbus` problem and now sets KWin's `current` desktop with
  `busctl set-property`.
- On the recording card in the main view, the round button starts recording
  right away (and stops it while recording). The rest of the card opens the
  recording view. Before, the whole card opened the view first, so starting
  took two clicks, and a click anywhere on the card stopped a running
  recording. On the card's right edge, three small icons stacked top to
  bottom show the current recording settings: screen (a monitor) or window
  (two stacked windows, `select_window`), system audio, microphone. A setting that's off
  is fainter and uses the crossed-out icon.
- Recordings include sound. The **System audio** and **Microphone** toggles
  didn't reach Spectacle, so recordings were silent. See "Recordings had no
  sound" below.
- The bottom of the island is no longer cut off after a restart where
  PowerDevil answered late (see "So the island's height must not depend on
  data that arrives late" below).
- The translucent, blurred frame Plasma draws around the open island is
  4 px wide instead of the theme's full margin (12 px with Ant-Dark), and
  the control center's corners run parallel to the frame's, so the frame is an
  even 4 px all the way round. The frame's corners were a tight "squircle"
  that made the control center look boxy, so the author's Ant-Dark theme was
  edited to round them (radius 24, control center radius 20). See "Plasma's
  popup always has a frame" below.
- The media card shows the cover's colours as soon as it opens. Its colour
  blobs used to start below the card and drift in over 10–20 seconds, so it
  looked dark and grey at first (see "The player's liquid background").
- When Spectacle stops recording on its own (it failed to start, or it was
  stopped from its tray icon), the island notices and goes back to idle
  instead of counting forever.
- The power panel has no **Lock** entry: the bottom row already has a lock
  button.

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
| Waveform in the small island | Plasma's audio applet (plasma-pa), with PipeWire or PulseAudio |
| Lyrics in the small island | internet access to `lrclib.net` |
| Brightness | Plasma's PowerDevil (built in). External monitors need DDC/CI support |
| GPU meter | `nvidia-smi` (hidden if missing) |
| Screen recording | `spectacle` |
| Coffee mode | `python3` with PyGObject (`gi`) |
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

**Between two panel spacers it isn't exactly centred.** In a shared,
full-width panel with an expanding spacer on each side of the island,
Plasma's spacer (`org.kde.plasma.panelspacer`) sizes itself to centre what
sits between the two: half the containment's width, minus the size hints
of the widgets on its side, minus half of those between the spacers. A
widget's hint is its `Layout.preferredWidth` (clamped to its minimum and
maximum) plus the layout's spacing. Logged from inside plasmashell on the
author's top panel, that formula has three flaws:

- **It counts the panel layout's own `Repeater`.** The Repeater that
  creates the applets is a visible, 0 px child of the layout, last in
  order, so it lands in the right-hand group and adds one spacing to it.
  The layout itself skips it, so nothing is drawn there. With Panel
  Colorizer's spacing at 18 px this alone pushed the island 8 px right
  (logged spacer sizes 581 and 427; without the phantom the right one
  would be 445).
- **It ignores `Layout` margins.** Panel Colorizer puts its widget margins
  on `Layout.leftMargin`/`rightMargin`. With 4 + 4 px on every widget, two
  on the left and three on the right, the right group was underestimated
  more and the island sat 7–12 px left.
- **It uses the containment's width (1600) rather than the layout's
  (1588).** Both spacers ask for a little more than there is, and the
  layout shrinks them in proportion to their size, so the larger one loses
  more. Worth 1–2 px.

The size of the error changes with everything the formula reads: the
island's width (lyrics), the tray's (the Caps Lock icon), the spacing.
The island itself is symmetric (dots and clock 12–13 px from the notch, the
notch in the middle of the widget); a widget that re-centred itself was
tried and dropped in favour of fixing the panel. To cancel the phantom
spacing, add margins to the widgets on the right of the right spacer (with
Panel Colorizer: Global Overrides with those margins, applied to those
widgets). Only their total counts, not which widget or side they go on.
Panel Colorizer paints a widget's background over its margins too, so
margins all on one side widen that widget's pill on that side and push its
icon off-centre; spread them where they even out the pills instead. Spacers
can't take them: Panel Colorizer skips spacers by default ("blacklist
spacers"), and with that off they'd get a pill of their own.

The margin has to be smaller than the spacing. The layout takes the extra
room out of both spacers, not just the right one, and the left one (the
larger) gives about 60 % of it, so a margin moves the island left by only
about 0.6 of its own width. On the author's panel (spacing 18) the phantom's
7.5 px needed a 12 px margin, which measured the island's centre at exactly
800 of 1600; 18 px put it about 4 px left. How much the spacers shrink
doesn't depend on the island's width, so the island stays centred within
a pixel as it widens for lyrics.

The share isn't a fixed 60 %: below their preferred sizes, Qt's layout
engine shrinks each item by `desired · (available/desired_total)^(desired/desired_total)`,
with `desired = preferred − minimum` (a spacer's minimum is 1 px). Replaying
that with the spacer formula gives the logged sizes to a pixel (553/405 at
spacing 18, margin 12), and this total margin for the author's panel at each
Panel Colorizer spacing:

| Spacing | 4 | 6 | 8 | 10 | 12 | 14 | 18 |
|---|---|---|---|---|---|---|---|
| Total margin on the right-hand widgets | 2 | 3 | 5 | 6 | 8 | 9 | 12 |
| Island's centre with no margin (of 800) | 801 | 802 | 803 | 804 | 805 | 806 | 808 |

Panel Colorizer keeps the spacing per preset. With preset autoloading
(one preset while a window touches the panel, another otherwise), give
both the same spacing: the margins are global, so they can only match one.

To check, print each panel widget's geometry (23 is the panel's id):

```bash
busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s 'var p = panels().filter(function (x) { return x.id == 23; })[0]; print(p.widgets().map(function (w) { var g = w.geometry; return w.type + " x " + g.x + " w " + g.width + " centre " + (g.x + g.width / 2); }).join("\n"));'
```

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
meters with the red flame, screen recording, coffee mode, and the inner
panels for Wi-Fi, Bluetooth, sound, notifications and recording.

All design tokens live in `Theme.qml`.

## Widget settings

Right-click the island → **Configure Linux Island…**. Options:

- **Language**: automatic (the system's), Spanish or English. It only changes
  the island's texts, not the desktop.
- **Time**: 24-hour, or 12-hour with AM/PM, for the control center's big
  clock. The panel island's clock is always 24-hour.
- **Meters**: RAM used in GiB ("7.8") next to the percentage (on by default).
  Turn it off to show the percentage alone.
- **Show in the small island**: weather, battery. Neither does anything at the
  moment: the island was rebuilt around the media and these are kept for a
  later plan. (The network checkbox is gone, and so are the desktops and
  clock checkboxes.)
- **Player**: show or hide the album art, waveform and lyrics in the notch
  while something is playing or paused. Off, the notch shows the date.
- **Colour the island with the album art** (off by default): the notch in
  the cover's colours, like the media card. Off, it's black like the
  control center, and the cover isn't loaded a second time for its colours.
- **Show synced lyrics** (on by default): the lyric lines in the small
  island. The lyrics button in the control center's bottom row flips the
  same setting. Off, nothing is sent to lrclib.net, and the middle shows the
  date ("11 Nov 2026") between the art and the waveform, with no title and
  artist when a song starts.
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

### An unexplained startup crash (2026-11-12)

The first start after `f439391` (the popup's `HoverHandler` `margin`) and
`b83c7e5` (no clicks on the notch) crashed twice in a row: the start at
17:00:13 and KCrash's automatic restart 2 s later, after which KCrash gave
up and plasmashell stayed down. The next manual `kstart plasmashell` with
the same code ran fine, as did every start before it that day. Both cores
died about 2 s into startup, right after Panel Colorizer loaded, with no
QML warning from this widget in the journal, and with two different
signatures:

- SIGSEGV in `QV4::Heap::Object::markObjects` under
  `QV4::MarkStack::drain`, during a JS allocation (the garbage collector
  met a freed object, like the five crashes above);
- SIGSEGV in `QQmlPrivate::AOTCompiledContext::getObjectLookup` from an
  AOT-compiled binding in `liborg_kde_plasmacomponents3.so`, under a deep
  `QQmlContextData::refreshExpressionsRecursive` (every binding in the
  engine being re-evaluated).

Nothing in those two commits matches the known causes above, so it's
logged as unexplained. If it happens again, compare: `coredumpctl list
plasmashell`, then `coredumpctl info <pid>` for the stack, and the journal
around it.

## Power panel

The button with the power icon, in the bottom row of the island, opens a
panel with: log out, sleep, hibernate, restart and shut down. Sleep and
hibernate only show up if the machine supports them (checked with
`CanSuspend` and `CanHibernate` on `org.freedesktop.PowerManagement`).

The four heavy options (log out, hibernate, restart and shut down) **ask for
confirmation in the same row**: the row expands downwards and you have to tap
"YES". One stray click on a small island shouldn't be able to take the
machine down.

Nothing uses `systemctl`. Everything goes through Plasma over DBus:
`org.kde.Shutdown` for log out, restart and shut down,
and `org.freedesktop.PowerManagement` for sleep and hibernate. That's what KDE's own power menu
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
- **Don't resize the island for an animation: every resize of Plasma's
  popup window costs a frame.** Measured in plasmashell itself with a
  temporary harness (open the popup, open and close the sound dropdown on a
  timer, log every `frameSwapped`). Idle, frames come every 7 ms (144 Hz).
  Resizing the window on every animation frame made 20 to 22 of ~65 frames
  late (~14 ms, the window only got ~24 sizes in 280 ms): choppy. Resizing
  once (grow at the start of an opening, shrink at the end of a closing) left
  one late frame at exactly those moments, plus the island's bottom edge
  jumping 184 px: a visible hitch. So the dropdowns float over the cards and
  the island's height doesn't change at all: 0 late frames, max 8 to 12 ms,
  also when a dropdown is closed halfway through opening.
  Lessons from the versions in between, still true for any height change
  (the brightness row):
  - **Every change of `implicitHeight` reaches Plasma at once, even one that's
    undone in the same instant.** Two `Binding`s waking up one after the
    other made the height go 710 → 524 → 710 in one go, and Plasma resized
    the window for each value. Sampling every 16 ms never caught it; logging
    every `implicitHeightChanged` did.
  - A `Column` updates its `implicitHeight` a frame late, in the polish pass,
    so it can't be mixed with a value that moved in this frame.
  - **Plasma reacts to `Layout.minimumHeight`, `preferredHeight` and
    `maximumHeight` one by one** (`AppletPopup::updateMinSize`,
    `updateSize`, `updateMaxSize` on the popup window). As three bindings
    to `implicitHeight` they updated min first, so growing went through
    min 710 / max 524, and the resize to 710 arrived while the maximum was
    still 524. `main.qml` now sets the three by hand: growing sets max, then
    preferred, then min; shrinking the other way round, so min ≤ max at
    every step.
  - Testing outside Plasma (`QT_QPA_PLATFORM=offscreen` with the `qml` tool)
    shows layout bugs but not the cost of a real popup resize. The numbers
    above come from plasmashell. `console.warn` from either lands in the
    journal (`journalctl --user`), not on stderr.
- **A white capsule or a gap around the island may come from Panel
  Colorizer, not from the island.** The author's top panel runs Panel
  Colorizer (`luisbocanegra.panel.colorizer`), whose presets gave every panel
  widget a `#eae8e0` background with a 20 px radius and 2/4 px margins
  (`globalSettings.widgets.normal`). That drew a white ring around the island
  and shrank its slot. The island is on Panel Colorizer's blacklist now
  (`blacklistedWidgets`), in both auto-loaded presets
  (`~/.config/panel-colorizer/presets/top-clear` and `blur-top`, originals
  kept as `settings.json.orig`), because loading a preset overwrites the
  widget's blacklist with the preset's. Once
  blacklisted, the slot falls back to the panel theme's own 4 px margins,
  which `CompactPill.reach` covers.
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
  `~/.config/plasma-org.kde.plasma.desktop-appletsrc`, saved when the popup
  hides. That value wins over a new `implicitHeight` when the popup is
  created, and Plasma only enforces our min/max height again when those
  change while the popup is shown. So `ExpandedPanel` nudges its height by
  1 px for 50 ms every time the popup window becomes visible, which makes
  Plasma apply the real height. If an old size still wins (the black strip
  or a cut-off bottom), **stop plasmashell, delete those two keys and start
  it again**.
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
- **Plasma's popup always has a frame, even with `NoBackground`.** The
  applet's `backgroundHints` only affects the applet in the panel. The popup
  (`AppletPopup`, a `PlasmaWindow`) draws the Plasma theme's dialog
  background around the content, translucent and blurred, as wide as the
  theme's margins. With Ant-Dark that's 12 px a side (`hint-*-margin` in
  `dialogs/background.svg`), which looked like a thick glass border around
  the island. `ExpandedPanel` reads the popup window's `topPadding`,
  `leftPadding`, … by name (`root.Window.window[...]`, undefined outside a
  Plasma popup) and lets the `island` rectangle reach into the frame with
  negative margins, leaving `Theme.popupRing` (4 px) of it visible. The item
  itself shrinks by the same amount (`implicitWidth`, `drawnHeight`), so the
  island keeps its size and the content stays where it was.
  The frame's corners decide how round the popup can look: the island can't
  be rounder than the frame without the ring getting thicker at the corners
  (it was, with a circular 26 px radius). Ant-Dark's corner was a cubic
  across a 24 px tile with its control points 4 px from the corner, a tight
  "squircle" that read as radius ~15 and made the control center boxy. So
  the author's copy of the theme
  (`~/.local/share/plasma/desktoptheme/Ant-Dark/dialogs/background.svg`,
  original kept next to it as `background.svg.orig`) was edited: the four
  corners, their `mask-*` and `shadow-*` counterparts are now quarter circles
  of radius 24 (control points 13.255 px from the ends). This rounds every
  Plasma popup, not just the island's. After editing a theme SVG, stop
  plasmashell and delete `~/.cache/ksvg-elements` and
  `~/.cache/plasma_theme_<theme>.kcache`, or the old corners stay cached.
  The island (and the dark layer behind open overlays, which was a plain
  square and darkened the frame's corners) is drawn by `IslandShape`, a
  `Shape` whose corners follow the frame's, inset by the ring: a quarter
  circle of radius 20 (`Theme.islandCorner`, `Theme.islandCornerPull`).
  With another Plasma theme, measure its `dialogs/background.svg` corner and
  change those two tokens. `CurveRenderer` antialiases the curves without
  `layer.enabled`.
- **A child with `anchors.fill` inside a `Row` breaks the Row**: all its
  content disappears. It happened when the scroll-wheel `MouseArea` was put
  inside `Workspaces`, which was a `Row`, and the desktop dots vanished. Now
  the root is an `Item` with the `Row` inside and the `MouseArea` next to it.
- **To round an image, use `Kirigami.ShadowedImage`, not
  `Rectangle { radius; clip: true }`.** `clip` clips to the rectangle, not to
  the rounded shape, so the album art covered the corners and looked square,
  in both the player card and the old mini player (the panel island does the same). `ShadowedImage` really rounds
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
  row. That column (`lado`) is an always-visible `Item`, and its content is
  right-aligned, so temperatures and the RAM number end at the same edge. Otherwise the RAM row widens on its own when it shows "10.4" and
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

3. Even so, the helper never ran from the widget. Turning it on ran
   `pkill -f coffee.py; python3 …/coffee.py &`, and the executable
   DataSource runs that through `sh -c`, so the shell's own command line
   contains "coffee.py" too. `pkill -f` matched that shell and killed it
   (exit 143, SIGTERM) before it reached `python3`. The toggle showed on and
   nothing was inhibited. `pkill` now matches `^python3 <full path to
   coffee.py>` (`QuickActions.coffeeMatch`): only the helper's command line
   starts with `python3`, and the full path also leaves the upstream
   island's helper alone. The same trap waits for any `pkill -f <name>` run
   in a command line that also contains `<name>`.

To check it, read PowerDevil's `ActiveInhibitions` property while coffee
mode is on (allow about 5 s: PowerDevil delays new inhibitions):

```bash
busctl --user get-property org.kde.Solid.PowerManagement \
  /org/kde/Solid/PowerManagement/PolicyAgent \
  org.kde.Solid.PowerManagement.PolicyAgent ActiveInhibitions
```

It lists `"idle"` (screen), `"sleep"` and `"sleep:idle"` for "Linux Island"
while on, and none of them after turning it off. The older
`ListInhibitions` method is deprecated and doesn't show them.

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
- **The blobs start on their path.** They used to start at `0,0`, which put
  each blob's centre far below the card (the blob is 1.4 times the card's
  width), and the first swing back up takes 9 to 21 seconds. So every time
  the popup was created, the card stayed dark and grey for its first
  10–20 seconds while the small island already showed the cover's colours.
- **When the song changes, the colour jumps instead of crossfading.** There
  used to be a 900 ms `Behavior on color`. With `Canvas` that would mean
  repainting three gradients every frame for a second, which is extra work
  inside plasmashell. The cover changes instantly anyway, so it isn't
  noticeable.

## Lyrics in the panel island

`Lyrics.qml` (a singleton) finds synced lyrics for the player the panel
island shows (`Media.active`) and works out which line is on.
`contents/ui/lrc.js` holds the parts that are plain functions (parsing,
which line plays when, when the pill should be wide), so they can be tested
outside Plasma.

- **Where they come from.** [LRCLIB](https://lrclib.net), a free lyrics
  database with no key. A song is looked up when its title and artist
  change, 600 ms after the metadata settles (players send the title, artist
  and length in pieces). First `/api/get` with title, artist, album and
  duration; if that has nothing, `/api/search` by title and artist; then a
  looser search with version notes stripped from the title
  (" - Remastered 2011", `(feat. …)`, `(Official Video)`, `[…]`), which also
  catches video titles like "Artist - Song". A result counts only with
  synced (timestamped) lyrics and a duration within 3 s of the track's.
  Plain lyrics without timestamps, and songs LRCLIB marks as instrumental,
  count as no lyrics.
- **What is sent.** The song's title, artist, album and length, to
  lrclib.net, and nothing else. **Show synced lyrics** off in the settings
  sends nothing.
- **XHR, not curl.** The request is built with `encodeURIComponent` and
  sent with `XMLHttpRequest`, like the weather. A title never goes through a
  shell, so a song called `$(rm -rf ~)` is only a song.
- **Busy is not "no lyrics".** Only HTTP 200 and 404 are answers. LRCLIB
  often answers 503 or 429 when it's busy; the Windhawk island this feature
  is modelled on cached those as "no lyrics" and lost songs LRCLIB has. Here
  a busy server or a network error retries after 2, 5, 10 and then every
  20 seconds. The first two retries go out even while paused, later ones
  wait for playback to resume, and they stop when the song changes. The last
  30 answers are kept in memory.
- **Timing without polling.** MPRIS only gives the position when asked
  (`updatePosition()`) or after a seek. The playhead is the last known
  position plus the time since, times the playback rate. One single-shot
  timer is set for the next moment anything changes (a line starts, or is
  0.3 s away), so nothing runs between lines. While lyrics show, the
  position is asked again every 5 seconds to stay in step with the player.
- **Turning the lyrics back on looks the song up at once**, not after the
  600 ms wait for metadata (that wait is for a new song whose title, artist
  and length arrive in pieces). The last 30 answers are kept while the
  lyrics are off, so a song looked up before shows its line straight away.
  Through the wait the island used to flash ♫ ("no lyrics"). A song that
  started while the lyrics were off still has to be asked for (about a
  second, longer when LRCLIB is busy), and in an instrumental part the
  island shows ♪ until the next line.
- **A paused player's position doesn't change**, so asking for it gives no
  `positionChanged`. On a new song the playhead starts from the player's last
  known position, not 0, or a player found paused halfway through a song
  would stay at 0.
- **Fixed width.** Every line gets the same middle width
  (`Theme.lyricsWidth`), so the island resizes when lyrics start and stop,
  not on each line. While the width animates, the middle is clipped to the
  space between the art and the waveform, so the line is revealed from the
  centre instead of running over them.
- **Long lines slide once** (`MarqueeText.qml`): a hold of
  `Theme.marqueeHold` (0.7 s), a slide to the end that fits in the line's
  time on screen, then it stays there. Looping would make the line hard to
  follow while it's sung.
- **The notes are drawn, not typed** (`NoteGlyph.qml`). Material Symbols
  only has `music_note`, and how ♪ and ♫ look as text depends on the system
  font; the Windhawk island draws its ♫ for the same reason (Segoe UI gives
  it a double beam, which reads as sixteenths). Each note is one SVG path in
  a `Shape`: tilted elliptical heads (two half arcs each), stems, and a flag
  or a beam, filled with the winding rule so the overlapping parts make one
  shape. `Theme.noteSize` (9 px, about the height of the lyric text; 14 px
  was far too big) sets the height and `Theme.noteWidth` (20 px) the
  middle's width while a note shows.
- **Pausing needs no code of its own.** The playhead stops, so
  `Lyrics.wide` and the line on show stay as they are. `MarqueeText.paused`
  holds a sliding line where it is (set by hand on the running animation:
  a bound `paused` on a stopped animation makes Qt warn).
- **Lines.** A line shows 0.3 s before it's sung (`LEAD`). Empty lines and
  lines with only ♪ are gaps. A gap shorter than 4 s between two sung lines
  keeps the last line up; longer ones, the intro and the outro show ♪. Not every file closes an instrumental break
  with an empty line, so a line counts as over 10 s after it starts (6 s for
  the last one).

## The real waveform

`LiveWave.qml` draws the small island's waveform from the actual audio.

- **The level comes from plasma-pa's `VolumeMonitor`.** It's the live level
  meter Plasma's audio applet shows in its sliders, with the same pattern:
  `target: live ? PreferredDevice.sink : null`. With a target it records a
  peak-detect stream from the default output's monitor (about 15–25 peaks
  a second); with `null` it closes the stream, so nothing runs while paused.
  Everything the speakers play counts, not just the player, so a
  notification sound moves the bars too. Picking out only the player's
  stream was skipped: browser audio comes out of a different process than
  the one that owns the MPRIS player.
- **Why not cava or a Python helper.** `DataSource` only hands back a
  command's output once it exits, so it can't read a stream. Spawning a
  process 25 times a second to read a file would break the "don't poll
  often" rule. `VolumeMonitor` is native, event-driven and already part of
  Plasma.
- **The height is loudness plus motion.** A bar's height has two parts.
  How loud: the short average (about half a second) against the loudest
  recent moment, so a quietly mastered song isn't small and a soft passage
  after a loud one is. Motion: how far the newest peak is above or below
  that average, ±3 dB being a full swing. Loud music sits around half height
  and moves; only a moment well above its average gets near the top.
  Two earlier scales didn't work. A fixed dB scale: songs are mastered at
  very different levels (two Spotify tracks measured here peaked at −21
  and −10 dB), so the quiet one stayed small and the loud one sat pinned at
  the top. A scale relative to the running peak (the loudest recent moment
  full, 24 dB below it empty): it looked full all the time on pop, because
  a loud master's peaks barely move. On one Taylor Swift song, 80% of the
  peaks fell between −9 and −5.7 dB, and the bars were above 85% height 97%
  of the time. The running peak jumps up at once and falls 2–3 dB a
  second, but never counts as lower than −30 dB, so a soft passage after a
  loud one isn't blown up.
- **The volume slider doesn't change the bars.** PipeWire leaves monitor
  ports at full level (`monitorVolumes` stays 1.0 whatever the volume is).
- **The envelope is short.** A rise shows at once and a fall keeps half per
  sample. The reference Windhawk island uses attack 0.7 / release 0.85, but
  per sample at 100 Hz; the monitor here sends about 15–25 peaks a second,
  and at that rate the same numbers held every peak for a quarter of a
  second and the bars hovered near the top. Each bar animates
  its height over `Theme.durTick` (70 ms) to smooth the steps between
  samples.
- **To test it outside Plasma**, load `LiveWave` in a small QML file with
  `/usr/lib/qt6/bin/qml` and `QT_QPA_PLATFORM=offscreen`, and log `history`.
  Qt's log goes to the journal unless `QT_FORCE_STDERR_LOGGING=1` is set.

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
