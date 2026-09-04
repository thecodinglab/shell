# shell

A [quickshell](https://quickshell.org) system shell for hyprland. One notch at
the top of every monitor that comes out when you reach for it and unfolds when
you click it.

## The notch

Revealed it is a 32px tab hanging from the top edge of the screen, square on
top and rounded at the bottom like the notch on a macbook, carrying the
workspace dots, the clock, and the cover of whatever is playing. Most of the
time it is not there at all: the screen belongs to the windows on it, nothing
is reserved, and all the shell occupies is a few pixels along the top edge.
Reach the top of the screen and the tab slides back out; leave and it puts
itself away again. A notification drops out from under the top edge on its
own, whether the tab is out or not; one that goes back up unread is kept in
the notifications panel, and one that was clicked or put away is not. So
does the volume: set it from a
media key and a pill drops out under the notch on the focused monitor with
the speaker glyph, a bar and the figure, moves with every further press, and
goes back up a moment and a half after the last one. It is not there while
the notch is open, where the slider already is.

Clicking the tab grows the same slab into a 440px panel — over the windows,
so opening the notch never reflows what is behind it. It is laid out the way
a control centre is: a short column of modules on one flat slab, told apart
by the air between them rather than by rules or frames.

| | |
| --- | --- |
| header | the dots where they were, and the clock grown, with the date under it and a count of what is waiting beside it; the clock leads to the notifications |
| media | one module per mpris player: cover, title, transport, and a scrubber the width of the module |
| sound | where the sound is going, and a bar to set how loud; the head of the module leads to the panel |
| tiles | bluetooth and network, each a disc, a name and one line on how it is doing |
| system | cpu, memory and disk as three dials |

A disc lit in the accent means the thing behind it is in use — a device on
the line, a link carrying an address. Idle is the plain disc, and the line
under the name says which. The accent is spent on nothing else: the fills —
a slider, a scrubber, the play button — are the ink itself, so that a bar at
half reads as a solid thing rather than a coloured one, and the one colour on
the surface only ever says *on* or *here*.

The volume bar is the notch's own control: tall enough to be the target, no
knob, and the speaker glyph riding inside the fill. Drag or scroll the bar to
set it; click the glyph to mute. When the fill passes under the glyph the
glyph swaps its ink, so a bar at nothing and a bar that is muted both still
have their mark.

Every tile is a door, and so are the clock and the head of the sound module;
each leads to exactly one panel:

- **Notifications** — what has come in and not been dealt with, newest at
  the top, the way a laptop's notification centre keeps it. A toast that
  ran out of time lands here; one that was clicked or put away by hand does
  not, and neither does one the sender marked transient. Each row is the
  toast it was, with who sent it and how long ago, and leaves two ways: by
  the cross that turns up under the pointer, or by being clicked, which
  does what the toast would have done — the notification's own action while
  it is still up, and failing that the application it came from. The header
  clears the lot. Whatever is left goes on its own after
  `notificationRetention` seconds, a day by default, and the list is capped
  at `notificationLimit`. The list is written to
  `$XDG_STATE_HOME/shell/notifications.json` as it changes, so it survives
  the shell being restarted; a notification an application updates in place
  updates its row rather than adding one, and one the application takes
  back is taken out.
- **Sound** — output and input, each a module: its bar at the top with the
  figure beside it, and the devices it could be going through underneath,
  with a check beside the one it is. One click on a device makes it the
  default. Between them, a bar for every application that is playing, named
  and set the same way, so a video can be turned down without turning the
  machine down with it; the module is not there at all while nothing is
  playing. The input module also draws the last second of what the
  microphone picked up, fed from pipewire's peak monitor.
- **Bluetooth** — every device bluez knows about, as a list of rows with no
  ground until the pointer finds them. One click does the obvious next
  thing: pair what is new, connect what is known, hang up on what is already
  connected; a device still making up its mind spins instead and takes no
  clicks until it has finished. The line under each name says what is
  happening to it, or failing that what it is. The field at the top narrows
  the list down, and the list grows the notch until it is half the height of
  the screen and scrolls from there. The header toggles the adapter and
  shows when it is scanning.
- **Network** — one row per interface `ip` reports as up, ethernet, wifi and
  tunnels each with their own mark, and the address it carries. A machine on
  a wire and a vpn at once shows both; a link with a carrier but no address
  says so, and a machine on nothing says offline. Bridges and container
  veths are not ways out of the machine and are left out, by the name
  prefixes in `networkIgnore`.
- **System** — cpu, memory and disk twice over: a dial for where each one is
  now, and the histogram beside it for how it got there. The dials are the
  larger of the two sizes here, where each one is the subject of its own
  module rather than one of three abreast on the home strip.

The dots are the workspaces hyprland's rules bind to that monitor
(`workspace = 3, monitor:DP-4`), open or not, so every monitor shows only its
own and a click on any dot switches to it. A monitor without such rules shows
the first `workspaceCount` instead.

## From the keyboard

The shell answers `qs ipc`, so any of it can be put on a hyprland bind:

```sh
qs -p ~/dev/shell/src ipc call notch toggle       # open or close, on the focused monitor
qs -p ~/dev/shell/src ipc call notch open audio   # straight to a panel: notifications, audio, bluetooth, network, resources
qs -p ~/dev/shell/src ipc call notch peek         # bring the pill out for a moment
qs -p ~/dev/shell/src ipc call notch close        # fold every monitor's notch
```

For the packaged build, `-p` is the store path the service runs from; the
same calls work against it.

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
  notch/               the window, the collapsed pill, the toasts, and the panels it unfolds into
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
  everything on top of it resolves against it: the modules are one wash of
  the foreground, the discs and the empty tracks a second, stronger one, and
  text is the foreground mixed toward the background. Only `base00`,
  `base05`, `base08` and `base0D` are used. The fills are the ink itself, so
  the accent is kept for state alone — a disc that is on, the workspace you
  are on, a dial — and a link that is up is the normal case, which is not
  worth a colour.
- **Material.** One. A module sits on the slab on its wash and a row in a
  list sits on nothing until the pointer finds it; there are no rules, no
  frames, and no shadows inside the slab. Three grounds a few percentage
  points apart on top of each other is one grey with extra steps, and reads
  as texture rather than as structure.
- **Type.** One family. Names, figures and labels are all set in the sans, in
  six sizes with weight and ink carrying the rest of the hierarchy; the mono
  is there for the nerd font glyphs alone. Anything that ticks is set with
  tabular figures, which is what the shell used to reach for a monospace face
  to get — a proportional `1` is narrower than a `4`, so a clock reflows the
  row it is in every minute. `displayFamily` is the optical size the clock and
  the titles are cut at, and defaults to Inter's display cut when the session
  is set in Inter.
- **Input.** The window is as tall as the tallest thing it can ever show, and
  masked down to the slab, its notifications, and the strip along the top edge
  it listens on while it is put away, so every pixel the notch is not using
  belongs to the desktop.
- **Layout.** The panel is laid out at the full expanded width from the start
  and revealed by the slab growing over it, rather than reflowing on every
  frame of the animation.
- **Grid.** Everything hangs off one left margin — the one a module sets its
  contents in by — so the dots, the discs and the artwork line up down the
  panel while the modules themselves bleed out past it to the slab's own.
  Radii nest the same way: a corner inside another corner is the outer one
  less the gap between them, so the modules are concentric with the slab.
- **Figures.** Anything that changes on a timer is drawn at a fixed size — a
  dial, a bar, or a right-aligned column of a set width — never as free text
  a layout takes its measurements from. A percentage written out is a
  different width at 7% than at 100%, and a row of them nudges its neighbours
  along every time it ticks.
- **Motion.** The slab moves first and what it carries follows: the panel
  waits for the slab to be most of the way open before it fades in, and is
  gone before the slab starts to close. The slab itself grows on a curve that
  covers nearly all of the distance in the first third and settles from
  there, so it arrives as fast as it can without stopping dead. Opened or
  closed with no pointer on it — from a keybind, or by a click somewhere
  else — the whole panel slides out of, or back into, the top edge at full
  size in one movement, and only changes size while it is out of sight.
