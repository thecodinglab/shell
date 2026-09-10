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

Clicking the tab grows the same slab into a 440px sheet — over the windows,
so opening the notch never reflows what is behind it. It is laid out as a
page rather than as a stack of boxes: the clock is its title, set large at
the top left, and the sections follow down the page with nothing between
them but air. Only the things that can be pressed have a ground of their
own, and a list is a column of names with a hairline between them.

| | |
| --- | --- |
| head | the clock grown into the title with the date under it; at the right the dots where they were, and a bell with a count of what is waiting, which leads to the notifications |
| now playing | one section per mpris player: cover, title, transport, and a scrubber the width of the page |
| sound | the name of the section, where the sound is going, and a bar to set how loud; the head of the section leads to the panel |
| tiles | two rows of two with a hairline between them: bluetooth, network, stay awake and system, each a disc, a name and one line on how it is doing; a chevron at the right says the tile leads to a panel, a switch says it is a setting |
| session | four discs at the foot: lock, sleep, restart and shut down |

A disc lit in the accent means the thing behind it is in use — a device on
the line, a link carrying an address. Idle is the plain disc, and the line
under the name says which. The accent is spent on nothing else: the fills —
a slider, a scrubber, the play button — are the ink itself, so that a bar at
half reads as a solid thing rather than a coloured one, and the one colour
on the surface only ever says *on* or *here*: a lit disc, the workspace you
are on, the count of notifications waiting, and the ring around whatever
the keyboard has reached.

The volume bar is the notch's own control: tall enough to be the target, no
knob, and the speaker glyph riding inside the fill. Drag or scroll the bar to
set it; click the glyph to mute. When the fill passes under the glyph the
glyph swaps its ink, so a bar at nothing and a bar that is muted both still
have their mark.

The system tile's disc is a ring rather than a glyph — how busy the
processor is, drawn the way the dials inside are — and the line under it
carries the processor and memory figures.

The stay awake tile is an idle inhibitor: lit, the notch holds a wayland
inhibitor on its window and hypridle neither locks the screen nor turns it
off; plain, the idle daemon is left to its timeouts.

The session marks at the foot of the page put the machine down: four discs
in a row, each with its name under it, all through logind, so a press does
whatever the session is set up to do — lock is `loginctl lock-session`,
which hypridle answers with hyprlock, and sleep is `systemctl suspend`, which
it locks ahead of. Restart and shut down are pressed twice: the first press
turns the disc red and swaps its name for "Press again", a second one within
a few seconds is the answer, and pressing anything else, or waiting, lets it
go. The notch folds before any of them runs.

Three of the tiles are doors, and so are the bell and the head of the sound
section; each leads to exactly one panel:

- **Notifications** — what has come in and not been dealt with, newest at
  the top, the way a laptop's notification centre keeps it. A toast that
  ran out of time lands here; one that was clicked or put away by hand does
  not, and neither does one the sender marked transient. Each row is the
  toast it was, with who sent it and how long ago. Clicking it does what
  the toast would have done — the notification's own action while it is
  still up, and failing that the application it came from — and leaves the
  row where it is; the cross at its right is what takes it away, and the
  header clears the lot. Whatever is left goes on its own after
  `notificationRetention` seconds, a day by default, and the list is capped
  at `notificationLimit`. The list is written to
  `$XDG_STATE_HOME/shell/notifications.json` as it changes, so it survives
  the shell being restarted; a notification an application updates in place
  updates its row rather than adding one, and one the application takes
  back is taken out.
- **Sound** — output and input, each a section: its bar at the top with the
  figure beside it, and the devices it could be going through underneath,
  with a check beside the one it is. One click on a device makes it the
  default. Between them, a bar for every application that is playing, named
  and set the same way, so a video can be turned down without turning the
  machine down with it; the section is not there at all while nothing is
  playing. An application that keeps a volume of its own and puts its stream
  back to it on every track, as Spotify does, is set through mpris as well,
  so the bar sticks; `mprisVolumeApps` says which. Under the input bar a
  thin meter shows what the microphone is picking up right now, fed from
  pipewire's peak monitor.
- **Bluetooth** — every device bluez knows about, as a list of rows with a
  hairline between them and no ground until the pointer finds them. One click does the obvious next
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
  now, and the histogram beside it for how it got there, a row each with a
  hairline between them.

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

Once it is open, the notch is the keyboard's. Tab walks everything on the
page that can be pressed — the dots, the bell, the transport, the bars, the
tiles, the rows of a list — and draws a ring in the accent around wherever
it is; space or return presses it, the arrow keys move a bar and M mutes it,
and escape steps back out, one page at a time. The ring is only drawn while
the keyboard is what is being used: reach for the pointer and it goes.

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
- **Colour.** One neutral scale, one accent, one red. Only `base00`, `base05`,
  `base08` and `base0D` are read from the palette; `Theme.neutral` is twelve
  steps between the first two, and every ground and every tier of ink on the
  surface is one of those steps by name — the sheet, the wash a row shows
  under the pointer, the disc, the hairline, and the four inks from disabled
  to full. Light and dark are told apart by the ground's luminance and are
  spaced separately: a dark ground needs bigger steps low down, where the
  grounds live, and a light one needs the ink pushed further before it reads
  as text. Each tier of ink that has to be read clears WCAG AA against the
  sheet on the palettes it was checked against. The fills are the ink itself,
  and the red is the palette's pulled a little toward the ink, so it warns
  without shouting.
- **Material.** A page, not a stack of boxes. Content sits directly on the
  sheet and is told apart by the air around it; nothing has a ground of its
  own until the pointer, or the keyboard, finds it, except a disc, a switch,
  a bar and a button, which are raised because they are the things you set.
  The one line the surface draws is the hairline between two rows of a list
  or two sections of a page. The floating surfaces — the slab, a toast, the
  volume reading — cast one soft shadow; nothing on them casts any. Three
  radii: small for anything on the sheet, medium for a field, large for the
  surfaces themselves.
- **Type.** One family in four sizes: small for metadata and figures, body
  for everything read, title for the name of a page, display for the clock.
  Weight and ink carry the hierarchy before size does. The mono is there for
  the nerd font glyphs alone, and no glyph stands on its own: each sits
  beside a name or on a button that says in words what it does, which is
  read out and put up as a tooltip once the pointer has rested on it.
  Anything that ticks is set with tabular figures, so a clock turning over
  does not reflow the row it is in. `displayFamily` is the optical size the
  clock and the titles are cut at, and defaults to Inter's display cut when
  the session is set in Inter.
- **Grid.** Four units. Every length in `Theme.qml` is a design unit put
  through `Theme.px()`, and every layout length is a multiple of four of
  them — the spacing tokens `space1` to `space8` — so the whole surface snaps
  to one grid and scales as one piece. Strokes and hairlines are not layout
  and are drawn at the size they need. Nothing outside `Theme.qml` names a
  colour, a size or a duration.
- **Keyboard.** Everything that can be pressed can be tabbed to, and says
  what it is to a screen reader. The focus ring is drawn in the accent, just
  inside the edge of the control so a row in a scrolling list keeps all of
  it, and only while the keyboard is what is being used — see `Nav`.
- **Reduced motion.** There is no `prefers-reduced-motion` on wayland for
  the shell to ask about, so `reducedMotion` in the config is the switch.
  Every duration comes from `Theme.motion`, so with it set everything
  arrives instead of moving; the spinner still turns, because a spinner that
  has stopped means something else.
- **Input.** The window is as tall as the tallest thing it can ever show, and
  masked down to the slab, its notifications, and the strip along the top edge
  it listens on while it is put away, so every pixel the notch is not using
  belongs to the desktop.
- **Layout.** The panel is laid out at the full expanded width from the start
  and revealed by the slab growing over it, rather than reflowing on every
  frame of the animation.
- **Margin.** Everything hangs off one left margin — the page's — so the
  clock, the artwork, the headings and the discs line up down the page,
  while the tiles and the rows bleed out past it to their own edges by their
  own padding.
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
