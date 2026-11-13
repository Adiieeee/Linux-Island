# Linux Island

A dynamic island for KDE Plasma 6, inspired by
[impasto](https://github.com/andreumassanet/impasto) (Andreu Massanet's
Quickshell shell for Hyprland) and brought to KDE as a Plasma widget.

A black notch in the middle of the panel shows what's playing: the album
art, the lyric line being sung and a waveform that follows the real audio.
Move the pointer onto it and a control center opens below it.

## Features

**In the panel**

- Album art, synced lyrics from [LRCLIB](https://lrclib.net) and a live
  waveform while music plays. A new song shows its title and artist for a
  few seconds. With nothing playing, the notch shows today's date.
- Desktop dots on the left (click or scroll to switch desktop) and a
  24-hour clock on the right.
- Short alerts in the notch in place of KDE's pop-ups: the volume, the
  microphone and a new output device.
- Optional: tint the notch with the album art's colours.
- Optional, experimental: keep the notch above fullscreen games. Hovering it
  there opens a small game panel with the player, the meters and recording.

**In the control center**

- Clock, calendar and weather from [wttr.in](https://wttr.in).
- A media card in the cover's colours, with a seek bar, shuffle and repeat,
  and arrows to switch between players.
- Wi-Fi and Bluetooth, with panels to pick a network or a device.
- Volume and brightness sliders, with a per-device dropdown. Volume goes up
  to 150%.
- CPU, RAM and GPU meters.
- Screen recording through Spectacle: full screen or one window, with system
  audio and microphone.
- Notification history, grouped by app.
- Coffee mode (the screen stays on, the computer stays awake), a lyrics
  toggle, lock, and a power menu (sleep, log out, restart, shut down).

## Install

```bash
git clone https://github.com/Adiieeee/Linux-Island.git \
    ~/.local/share/plasma/plasmoids/linuxisland
kquitapp6 plasmashell && kstart plasmashell
```

Then right-click a panel → **Add Widgets…** → **Linux Island**. The folder
must be named `linuxisland`, the applet id. To update, run `git pull` in that
folder and restart plasmashell.

### Requirements

Without one of these, its section stays empty and the rest keeps working.

| Section | Uses |
| --- | --- |
| Wi-Fi | `nmcli` (NetworkManager) |
| Bluetooth | `bluetoothctl` |
| Sound, waveform | PipeWire (`wpctl`, `pactl`) and Plasma's audio applet (plasma-pa) |
| Brightness | PowerDevil (part of Plasma); DDC/CI for external monitors |
| GPU meter | `nvidia-smi` |
| Screen recording | `spectacle` |
| Coffee mode | `python3` with PyGObject |
| Lyrics, weather | internet access to `lrclib.net` and `wttr.in` |

## Tips

- **Panel.** Put the island in the middle of a top panel that isn't
  floating, so the notch meets the screen edge: in a panel of its own (no
  background, "fit" width, centred) or between two panel spacers. Plasma's
  spacers can leave it a few pixels off centre; see
  [NOTES.md](NOTES.md#centring-between-panel-spacers).
- **Browser video.** For thumbnails and a working seek bar, install the
  **Plasma Integration** browser extension (plus the
  `plasma-browser-integration` package). In Firefox-based browsers, also set
  `media.hardwaremediakeys.enabled` to `false` in `about:config`, so the
  video doesn't show up twice.
- **Alerts.** So KDE's own volume pop-up doesn't show as well: System
  Settings → Sound → **Configure Volume Controls…** → uncheck everything
  under **Show OSD popups for changes to:**.
- **Shortcut.** Right-click the island → **Configure Linux Island…** →
  **Keyboard Shortcuts**. The shortcut turns the notch over games on and off.

## Settings

Right-click the island → **Configure Linux Island…**

- **Island**: language (English or Spanish), 12- or 24-hour big clock, RAM
  used next to its percentage, the player in the notch, the album-art tint,
  the notch over games, synced lyrics, and the weather city (empty finds it
  from your IP).
- **Colours**: four colours plus the text colour. The greys in between are
  mixed from them.
- **Fonts**: the text and number fonts. Both follow the system font by
  default.

## Development

There's no build step: edit the QML in `contents/ui/` and restart
plasmashell. The widget runs inside plasmashell, so a crash takes the whole
desktop down. Read [CLAUDE.md](CLAUDE.md) (architecture and hard rules) and
[NOTES.md](NOTES.md) (why things are done the way they are) first.

## Credits and license

- Inspiration: [impasto](https://github.com/andreumassanet/impasto) by
  Andreu Massanet.
- Code base: **Nothing Dynamic Island** by Omar, MIT license.
- **Linux Island** by Adiieeee, MIT license. See [`LICENSE`](LICENSE).
- Icon font: Material Symbols Rounded by Google, Apache License 2.0.
