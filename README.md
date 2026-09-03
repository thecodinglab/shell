# shell

A [quickshell](https://quickshell.org) system shell for hyprland. One notch at
the top of every monitor that comes out when you reach for it and unfolds when
you click it.

## The notch

Revealed it is a 30px tab hanging from the top edge of the screen, square on
top and rounded at the bottom like the notch on a macbook, carrying the
workspace dots and the clock. Most of the time it is not there at all: the
screen belongs to the windows on it, nothing is reserved, and all the shell
occupies is a few pixels along the top edge. Reach the top of the screen and
the tab slides back out; leave and it puts itself away again. A notification
brings it out too, so the toast has something to hang from.

Clicking the tab grows the same slab into a 560px panel — over the windows, so
opening the notch never reflows what is behind it:

| | |
| --- | --- |
| header | the dots and the clock, where they already were, plus the date |
| media | one card per mpris player, cover, transport and a seekable progress bar |
| audio | output and input volume, either one mutable from its glyph |
| network | one row per interface that is up, with the address it carries |
| tiles | bluetooth, and cpu / memory / disk as three dials |

Both tiles and both volume rows are doors. Behind them:

- **Bluetooth** — every device bluez knows about. One click does the obvious
  next thing: pair what is new, connect what is known, hang up on what is
  already connected; a device still making up its mind spins instead and takes
  no clicks until it has finished. The field at the top narrows the list down,
  and the list grows the notch until it is half the height of the screen and
  scrolls from there. The header toggles the adapter and shows when it is
  scanning.
- **Audio** — the default sink with a real slider, every other sink below it
  (click one to make it the default), and the microphone with a live level
  meter fed from pipewire's peak monitor.
- **Resources** — cpu, memory and disk twice over: a dial for where each one
  is now, and the histogram beside it for how it got there, with the network
  interface and address in the header.

The network rows are every interface `ip` reports as up — ethernet, wifi and
tunnels each with their own glyph — rather than the one interface waybar spoke
for, so a machine on a wire and a vpn at once shows both addresses; a link with
a carrier but no address says so instead, and a machine on nothing says
offline. Bridges and container veths are not ways out of the machine and are
left out, by the name prefixes in `networkIgnore`.

Notifications drop out of the bottom of the collapsed pill and leave on their
own, unless the pointer is on them.

The dots are the workspaces hyprland's rules bind to that monitor
(`workspace = 3, monitor:DP-4`), open or not, so every monitor shows only its
own and a click on any dot switches to it. A monitor without such rules shows
the first `workspaceCount` instead.

## Running it

Against the working tree, no rebuild needed:

```sh
nix develop
quickshell --path ./src
```

Or the packaged build:

```sh
nix run .
```

## Wiring it into a home-manager config

```nix
{
  inputs.shell.url = "path:/home/florian/dev/shell";

  # ...

  imports = [ inputs.shell.homeModules.default ];

  custom.shell.enable = true;
  custom.shell.settings = {
    diskPath = "/";
    networkInterface = "enp13s0";
  };
}
```

Colors and fonts come from stylix automatically when it is enabled. Everything
else is optional; `src/config/Config.qml` lists the settings and their
defaults, and the module writes the ones you set to a `config.json` the shell
reads at startup.

## Layout of the source

```
src/
  shell.qml            one notch per screen
  config/              settings, with defaults overridable from nix
  theme/               palette, metrics and glyphs derived from the base16 colors
  services/            cpu, memory, disk, network, audio, bluetooth, mpris, notifications, workspaces
  util/                formatting, sample history, pointer bookkeeping
  widgets/             the vocabulary the panels are built from
  notch/               the window, the collapsed pill, and the panels it unfolds into
```

Directories are importable as `qs.<name>`, so `import qs.theme` gets you
`Theme` and `Icons`.

## Design notes

- **Scale.** The notch was drawn at a 10pt base and every metric in
  `Theme.qml` goes through `Theme.px()`, so raising `fontSize` grows the whole
  surface instead of overflowing it. `scale` is a second multiplier on the same
  knob, for sizing the notch independently of the font the rest of the session
  is set in.
- **Colour.** Deliberately monochrome plus one accent. The slab is opaque and
  everything on top of it resolves against it, either as an alpha wash of the
  foreground (surfaces, tracks, dots) or the foreground mixed toward the
  background (text). Only `base00`, `base05`, `base08` and `base0D` are used.
- **Input.** The window is as tall as the tallest thing it can ever show, and
  masked down to the slab, its notifications, and the strip along the top edge
  it listens on while it is put away, so every pixel the notch is not using
  belongs to the desktop.
- **Layout.** The panel is laid out at the full expanded width from the start
  and revealed by the slab growing over it, rather than reflowing on every
  frame of the animation.
- **Figures.** Anything that changes on a timer is drawn at a fixed size — a
  dial, a bar, or a right-aligned column of a set width — never as free text
  a layout takes its measurements from. A percentage written out is a
  different width at 7% than at 100%, and a row of them nudges its neighbours
  along every time it ticks.
