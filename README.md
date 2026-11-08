# Misland

A MacBook-style notch shell for [Hyprland](https://hyprland.org), built on
[Quickshell](https://quickshell.org).

The notch shows only the time and date. Everything else stays hidden until
you ask for it: click the notch, touch a top corner of the screen, or press a
key.

## Features

**Notch**
- Collapsed: `14:35 · Sun, Nov 8`, pure black with concave "ears" where it
  meets the screen edge, like the MacBook cut-out.
- Click to expand into a panel; click outside or press Esc to collapse.
  Every size change uses a spring animation.
- The panel holds:
  - month calendar
  - media player (MPRIS: cover, progress with seeking, controls, switching
    between players)
  - Wi-Fi and Bluetooth tiles with drop-down menus (pick a network, enter a
    password, connect or pair devices)
  - volume and brightness sliders
  - battery, CPU and memory meters
  - lock, suspend, log out, reboot and power off (the last three ask for a
    second click)
  - notification history

**Live activities.** The collapsed notch widens for a moment, on one line,
when something happens:
- volume or brightness changes
- the charger is plugged in or out
- a Bluetooth device connects or disconnects
- the track changes (`♪ Title · Artist`)

**Notifications.** Misland is the notification daemon. Popups slide out of
the top-right corner in a black corner panel, stack inside it, and leave
after a timeout (hovering pauses it). Actions and inline links work. The
history lives in the notch.

**Do not disturb.** A button in the panel header (or `misland dnd`) hides
popups; critical ones still show and everything lands in the history. It
turns on by itself while the screen is being shared.

**Privacy indicators.** The collapsed notch shows an orange microphone, a
green camera or a blue screen-share icon while something records, and a red
crossed-out bell while popups are silenced.

**Corners.** Touch the top edge near a corner:
- top-left: workspaces slide out to the right, each with the icons of its
  windows; click to switch, scroll to step through
  (they also pop out for a moment whenever you switch workspaces)
- top-right: the system tray slides out to the left; left, right and middle
  click and scrolling are passed to the apps

**Launcher.** On a key binding, the notch opens into an app search. Type,
use the arrows, press Enter.

**Clipboard.** On a key binding, the notch opens into the clipboard history
(cliphist), with image thumbnails. Type to filter, Enter copies the entry
back, Delete removes it.

**Colour picker.** Pick a colour anywhere on screen (hyprpicker); it is
copied, and the notch shows a swatch with the value.

Both are also buttons in the panel header.

## Requirements

- Hyprland, with either a Lua (0.55+) or a hyprlang config
- Quickshell 0.3 or newer
- PipeWire, NetworkManager and BlueZ for the audio, Wi-Fi and Bluetooth parts
- `brightnessctl` for the brightness slider
- `cliphist` and `wl-clipboard` for the clipboard history, `hyprpicker` for
  the colour picker
- Fonts: Inter and Material Symbols Rounded

UPower is not needed: the battery is read from sysfs.

## Installation

### Nix flake with home-manager

The Nix package bundles `brightnessctl`, `cliphist`, `wl-clipboard` and
`hyprpicker`.

```nix
# flake.nix
inputs.misland.url = "github:cublae/misland";
```

```nix
# home-manager configuration
imports = [ inputs.misland.homeManagerModules.default ];

programs.misland = {
  enable = true;
  systemd.target = "hyprland-session.target";
  settings = {
    screen = "DP-1";               # empty = first screen
  };
};
```

The module installs the package and the fonts, writes
`~/.config/misland/config.json` and starts a systemd user service.

To start Misland from the Hyprland config instead, set
`systemd.enable = false` and add `misland` to your autostart (see below).
Starting it again while it runs does nothing, so it is safe on config
reloads.

Turn off any other notification daemon first (mako, dunst, swaync, fnott).
Only one process can own `org.freedesktop.Notifications`. The module warns
if one of them is enabled.

### Without Nix

Install the requirements, clone the repository and run:

```sh
qs -p /path/to/misland/shell
```

Start it from your Hyprland config. Settings go in
`~/.config/misland/config.json`; see the options below.

## Hyprland

Lua config:

```lua
hl.exec_cmd("misland")   -- autostart, unless the systemd service is on

hl.bind("SUPER + N",     hl.dsp.exec_cmd("misland toggle"))
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("misland launcher"))
hl.bind("SUPER + V",     hl.dsp.exec_cmd("misland clipboard"))
hl.bind("SUPER + C",     hl.dsp.exec_cmd("misland color"))

-- Misland animates its own surfaces.
hl.layer_rule({
    name    = "misland-no-anim",
    match   = { namespace = "^misland-" },
    no_anim = true,
})
```

hyprlang config:

```ini
exec-once = misland

bind = SUPER, N, exec, misland toggle
bind = SUPER, SPACE, exec, misland launcher
bind = SUPER, V, exec, misland clipboard
bind = SUPER, C, exec, misland color
```

Misland detects which syntax the running Hyprland uses when it switches
workspaces or logs out.

## Commands

```
misland                               run the shell
misland toggle | open | close         the notch panel
misland launcher [toggle|open|close]  the app launcher
misland clipboard [toggle|open|close] the clipboard history
misland color                         pick a colour from the screen
misland dnd [toggle|on|off]            do not disturb
```

Without the wrapper, use Quickshell IPC:

```sh
qs ipc -p /path/to/misland/shell call notch toggle
qs ipc -p /path/to/misland/shell call launcher toggle
qs ipc -p /path/to/misland/shell call clipboard toggle
qs ipc -p /path/to/misland/shell call color pick
qs ipc -p /path/to/misland/shell call dnd toggle
```

## Options

All options live under `programs.misland.settings` and map one-to-one to
`config.json`. The shell watches that file, so changes apply without a
restart.

| Option | Default | Description |
|---|---|---|
| `screen` | `""` | Output for the notch, e.g. `"DP-1"`. Empty means the first screen. |
| `scale` | `1.0` | Extra size multiplier. Sizes already follow the screen's logical height (1080 px = 1.0). |
| `reserveSpace` | `true` | Reserve the collapsed notch height so tiled windows sit below it. |
| `clock.timeFormat` | `"HH:mm"` | Qt time format, e.g. `"h:mm AP"` or `"HH:mm:ss"`. |
| `clock.dateFormat` | `"ddd, MMM d"` | Qt date format next to the time. Empty hides the date. |
| `clock.separator` | `"·"` | Text between time and date. |
| `calendar.firstDayOfWeek` | `1` | 1 = Monday … 7 = Sunday. |
| `brightness.device` | `""` | Entry in `/sys/class/backlight`. Empty picks the first one. |
| `power.lock` | `["loginctl", "lock-session"]` | Command for the lock button. |
| `power.suspend` | `["systemctl", "suspend"]` | Command for the suspend button. |
| `power.logout` | `[]` | Command for log out. Empty exits Hyprland over IPC. |
| `power.reboot` | `["systemctl", "reboot"]` | Command for the reboot button. |
| `power.poweroff` | `["systemctl", "poweroff"]` | Command for the power-off button. |
| `notifications.timeout` | `5` | Seconds a popup stays when the app sets no timeout. Critical ones stay until closed. |
| `notifications.maxHistory` | `50` | Notifications kept in the history. |
| `notifications.autoDndOnScreenShare` | `true` | Hide popups while the screen is being shared. |
| `activities.volume` | `true` | Live activity on volume changes. |
| `activities.brightness` | `true` | Live activity on brightness changes. |
| `activities.power` | `true` | Live activity when the charger is plugged in or out. |
| `activities.bluetooth` | `true` | Live activity when a Bluetooth device connects or disconnects. |
| `activities.track` | `true` | Live activity on track changes. |
| `edges.workspaces` | `true` | Workspaces in the top-left corner. |
| `edges.tray` | `true` | System tray in the top-right corner. |
| `edges.triggerSize` | `2` | Thickness in pixels of the hover strip along the top edge. |
| `edges.triggerLength` | `0.35` | Length of each hover strip, as a fraction of the screen width from the corner. |
| `edges.persistentWorkspaces` | `5` | Workspaces 1..N are always listed, even when empty. |
| `edges.showOnSwitch` | `true` | Pop the workspaces out for a moment on every workspace switch. |
| `edges.showOnSwitchMs` | `1200` | How long they stay out after a switch, in milliseconds. |
| `launcher.maxResults` | `7` | Rows shown in the launcher. |
| `launcher.terminal` | `["kitty", "-e"]` | Prefix for desktop entries with `Terminal=true`. |
| `clipboard.watch` | `true` | Record clipboard history (`wl-paste --watch cliphist store`). Turn off if something else already feeds cliphist. |
| `clipboard.maxItems` | `100` | Entries listed in the clipboard view. |
| `colorPicker.format` | `"hex"` | Format the colour picker copies: `hex`, `rgb`, `hsl`, `hsv` or `cmyk`. |
| `animation.spring` | `3.6` | Spring stiffness. |
| `animation.damping` | `0.55` | Spring damping, 0..1; lower values bounce more. |

home-manager also has:

| Option | Default | Description |
|---|---|---|
| `programs.misland.package` | this flake's package | The Misland package. |
| `programs.misland.systemd.enable` | `true` | Run Misland as a systemd user service. Turn off to start it from the Hyprland config. |
| `programs.misland.systemd.target` | `"graphical-session.target"` | Target that starts and stops it. |

## Project layout

```
flake.nix              package, home-manager module, dev shell
nix/package.nix        installs shell/ and the `misland` wrapper
nix/hm-module.nix      programs.misland options
shell/
  shell.qml            entry point: picks the screen, creates windows, IPC
  config/              Config (reads config.json), Theme
  components/          Icon, Label, Card, IconButton, Tile, PillSlider, ListRow
  services/            Time, Audio, Brightness, Battery, Media, SysStats, Apps,
                       Hypr, BtIcons, Clipboard, ColorPicker, Privacy,
                       Notifications (daemon), Activity
  modules/             Calendar, MediaCard, QuickSettings, WifiMenu,
                       BluetoothMenu, Stats, PowerButtons, NotificationList
  notifications/       corner popup panel, NotificationCard
  edges/               CornerPanel, CornerShape, Workspaces, Tray
  notch/               Notch window and shape; collapsed, expanded,
                       live-activity, launcher and clipboard views
```

## Development

```sh
nix develop
qs -p shell          # runs from the source tree and reloads on save
```

The dev shell provides Quickshell, the helper tools and the fonts without
installing them system-wide. `$MISLAND_CONFIG` points the shell at a
different config file.

## Known limitations

- Brightness controls the laptop backlight only. External monitors over
  DDC/CI are not supported yet.
- The notch, popups and corner panels appear on one screen, the one set by
  `screen`.
- After many live reloads during development, Quickshell sometimes does not
  exit when asked. The systemd service stops it after three seconds; when
  running by hand, `pkill -9 quickshell` helps.

## License

MIT, see [LICENSE](LICENSE).
