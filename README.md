# shell

A [quickshell](https://quickshell.org) system shell for hyprland, drawn after
the notch and Spotlight on a mac. One notch at the top of every monitor that
comes out when you reach for it and unfolds when you click it, and a
Spotlight pane that floats over the middle of the screen from a keybind.

## The notch

Revealed it is a 32px tab hanging from the top edge of the screen, drawn the
way the notch on a macbook is: the palette's ground pushed most of the way to
black, no frame, its bottom corners only softened, and its sides flaring out
into the top edge where they meet it rather than standing on it at a right
angle. It carries the workspace dots and the clock, and while something is
playing it widens by four bars moving at its trailing end, the way a live
activity widens the island. Most of the time it is not there at all: the
screen belongs to the windows on it, nothing is reserved, and all the shell
occupies is a few pixels along the top edge. Reach the top of the screen and
the tab slides back out; leave and it puts itself away again. A notification
drops out from under the top edge on its own, whether the tab is out or not;
one that goes back up unread is kept in the notifications panel, and one
that was clicked or put away is not. So does the volume: set it from a media
key and a pill drops out under the notch on the focused monitor with the
speaker glyph, a bar and the figure, moves with every further press, and
goes back up a moment and a half after the last one. It is not there while
the notch is open, where the slider already is.

While something is recording the microphone, reading the camera or sharing
the screen, the pill carries a dot at its trailing end, the way a mac puts
one beside its notch. A notch that is put away could not show it to anyone
who had not already reached for it, so while anything is in use a tally
stays behind on the top edge: the least of the notch that still reads as
it, a slot just big enough to hold the dot, hanging where the notch hangs.
It takes no clicks, and notifications drop in under it rather than over it.
Open, the page says what is in use and by whom, a line each, under the
clock. It is all read off pipewire. The microphone is any stream recording
a source, apart from a meter — which says so in its own properties, as the
sound panel's own meter does — and a stream taking what a speaker is
playing. The camera is a device something is linked to, and a shared screen
is the stream the portal offers for as long as the share lasts. What never
passes through pipewire is not seen: a camera read straight from its device
file, or the screen recorded through the compositor rather than the portal.

Clicking the tab grows the same slab into a 440px sheet — over the windows,
so opening the notch never reflows what is behind it — and its corners round
out as it grows, from the hardware notch's into the island's. It is laid out
as a page rather than as a stack of boxes: the clock is its title, set large at
the top left, and the sections follow down the page with nothing between
them but air. Only the things that can be pressed have a ground of their
own, and a list is a column of names with a hairline between them.

| | |
| --- | --- |
| head | the clock grown into the title with the date under it; at the right the dots where they were, and a bell with a count of what is waiting, which leads to the notifications |
| in use | only while something is: the microphone, the camera, the screen, each a lit disc with its name and the applications using it underneath |
| now playing | one section per mpris player: cover, title, transport, and a scrubber the width of the page |
| sound | the name of the section, where the sound is going, and a bar to set how loud; the head of the section leads to the panel |
| tiles | two rows of two modules, each on a ground of its own the way the blocks of a control centre are: bluetooth, network, stay awake and system, each a disc, a name and one line on how it is doing; a chevron at the right says the tile leads to a panel, a switch says it is a setting |
| session | four discs at the foot: lock, sleep, restart and shut down |

A disc lit in the accent means the thing behind it is in use — a device on
the line, a link carrying an address. Idle is the plain disc, and the line
under the name says which. The accent is spent on nothing else: the fills —
a slider, a scrubber, the play button — are the ink itself, so that a bar at
half reads as a solid thing rather than a coloured one, and the one colour
on the surface only ever says *on* or *here*: a lit disc, the workspace you
are on, the count of notifications waiting, the ring around whatever the
keyboard has reached — and the dot that says the microphone, the camera or
the screen is in use, which is the same *on*.

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

## Spotlight

The one thing the shell opens from a keybind rather than from the notch:
`shell ipc call spotlight toggle` brings it out on the focused monitor, or
puts it away again if it is already out there. It is drawn after the one on
a mac: a pane of its own floating a little above the middle of the screen,
where the eye already is, with a large field at its head — the magnifier and
the caret, and nothing else — and the results under a hairline below it.

Blank, it offers the few things that get used most, under *Recents*, and if
nothing has been used yet it is the field alone. Typing narrows everything
that can be started down to what fits, and files it the way Spotlight does:
the best fit on its own as the *Top Hit*, larger, with what it is under its
name; then the rest of the *Applications*; then the *Windows* already open;
then the rest of the *Shell* — the notch's own pages, Sound, Bluetooth, Network, System and Notifications,
and the two ways out of the session that are safe to press once, lock and
sleep. Restart and shut down want their second press and stay on the
notch's home page where they get it. `shell ipc call spotlight search
<text>` brings it out with the text already typed.

A query is matched against the name first — the start of it, then the start
of a word in it, then anywhere in it — and only then against what the entry
says about itself, so `spot` puts Spotify ahead of anything that merely
mentions it, and `1pas` finds 1Password. Every word of a query has to land
somewhere. Ties go to what gets used: every pick is counted, weighted toward
lately — a launch a fortnight ago is worth half of one today — and written
to `$XDG_STATE_HOME/shell/launches.json`.

The row Return will open is filled in the accent, with the return mark at
its right; the arrows, or `C-n`/`C-p` and `C-j`/`C-k`, step it without
leaving the field, and a click opens a row directly. Opening an application
puts the pane away and launches it; opening a page turns the notch on the
same monitor to it; escape clears the field, and on an empty field puts the
pane away, as does a click anywhere else. A console application — one whose
entry asks for a terminal — is run in `terminal`, as `<terminal> -e
<command>`, when one is configured.

A sum is answered as it is typed, the way the calculator in Spotlight on a
mac answers it: `12*7`, `2^10`, `sqrt(2)`, `2pi`, `(1+0.08)^5 - 1`. The
answer is the top hit, set large with *Calculator* under it, and the search
carries on underneath as if it were not there; Return copies the answer to
the clipboard and puts the pane away. The query is read by a small parser of
the shell's own, never run: the four operations, `%` for the remainder, `^`
for a power, brackets, and a handful of names — `pi`, `tau`, `e`, `sqrt`,
`abs`, `ln`, `log`, `exp`, `sin`, `cos`, `tan` and the like. A number on its
own is not a sum, so `42` and `2048` are left to the search, and so is
anything with a word in it that is not one of those names, like `1password`.

The windows already open are found the way the applications are — by title
first, then by the application they belong to — and opening one brings it
forward, on whatever workspace and monitor it is on. They are not counted
the way a launch is, so they never show up under *Recents*.

*Clipboard*, among the shell's own rows, turns the pane over to what has
been copied: the history cliphist keeps, newest first, with a picture named
for what it is (*PNG image, 1920×1080 · 240 KiB*). Typing narrows it down,
Return puts the entry back on the clipboard whole and puts the pane away,
and escape on an empty field comes back out to the search. Without
cliphist, or before anything has been copied, it says so. The home-manager
module turns on home-manager's `services.cliphist` so the history is being
written down; set `custom.shell.clipboard.enable = false` to leave cliphist
to the rest of the config.

The pane is frosted glass on a mac. Here its ground is near opaque by
default, so it reads over anything; give the compositor a blur rule for its
layer and lower `glassOpacity` to let the frosted desktop through:

```lua
hl.layer_rule({ name = "spotlight-blur", match = { namespace = "^shell-spotlight$" }, blur = true, ignore_alpha = 0.5 })
```

```nix
custom.shell.settings.glassOpacity = 0.75;
```

`ignore_alpha` keeps the blur to the pane itself and off the fainter shadow
around it.

Every application is started in a systemd scope of its own under `app.slice`
(via `systemd-run --user --scope`) rather than as a child of the shell, so it
keeps running when the shell's service is restarted or stopped.

## Asking for a password

The shell is the session's polkit agent, so when something wants to do what
it needs a password for — restart a service, install a package, mount a
disk — the shell is what asks, in a pane drawn after the password prompt on
a mac. It comes out of Spotlight's glass on the focused monitor, a little
above the middle, narrow and centred down one column, and while it is out
it has the keyboard: Spotlight closes and every notch folds as it arrives.
At its head is the application's own icon with a padlock on its shoulder,
or the padlock alone when it brought none; under it, in bold, what polkit
says is being asked, and what it wants for it — "Enter your password to
allow this." Then two fields, one above the other. The first says who is
being asked, where a mac has the user name, and when polkit would take any
of several — another user, anyone in a group — it opens into the list of
them, the one in use checked, and picking another starts over for them.
The second asks whatever PAM asks and shows dots unless it is told the
answer may be seen; under it comes a line for whatever PAM has to say — a
fingerprint reader waiting, an account locked — when it has anything to
say. At the foot are Cancel and OK, as wide as each other, OK in the
accent. Return answers and escape gives up. A wrong answer shakes the pane,
says so, and leaves the field empty for another go.

What is typed goes from the field to polkit and nowhere else: it is never
bound to, stored or logged, and the field is emptied the moment it is sent.
Requests that arrive while one is being answered wait their turn, and come
up one after the other in the same pane.

Only one agent can answer for a session. One that runs another —
hyprpolkitagent, polkit-gnome — turns the shell's off:

```nix
custom.shell.settings.polkitAgent = false;
```

As with Spotlight, a blur rule on its layer and a lower `glassOpacity` let
the frosted desktop through:

```lua
hl.layer_rule({ name = "polkit-blur", match = { namespace = "^shell-polkit$" }, blur = true, ignore_alpha = 0.5 })
```

## From the keyboard

The shell answers `qs ipc`, so any of it can be put on a hyprland bind:

```sh
qs -p ~/dev/shell/src ipc call notch toggle         # open or close, on the focused monitor
qs -p ~/dev/shell/src ipc call notch open audio     # straight to a panel: notifications, audio, bluetooth, network, resources
qs -p ~/dev/shell/src ipc call notch peek           # bring the pill out for a moment
qs -p ~/dev/shell/src ipc call notch close          # fold every monitor's notch
qs -p ~/dev/shell/src ipc call spotlight toggle     # spotlight, on the focused monitor
qs -p ~/dev/shell/src ipc call spotlight search x   # ...with x already typed into it
qs -p ~/dev/shell/src ipc call spotlight clipboard  # ...on the clipboard history
```

For the packaged build, `-p` is the store path the service runs from; the
same calls work against it. `launcher toggle` is kept as another name for
`spotlight toggle`, for binds written when the launcher was a page of the
notch.

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

### Checking it

QML is only read when the shell starts, so a misspelt property, an import
that is not there or a binding that throws would otherwise only turn up as a
line in the log of a running shell. `nix flake check` catches them ahead of
time:

- **lint** runs qmllint over every file, against quickshell's own type
  info, with the `qs.<dir>` imports resolved the way quickshell resolves
  them, a qmldir per directory. Anything at warning level or above fails
  it. The only findings let through are a handful that come from gaps in
  quickshell's own type info rather than from the shell, and
  `nix/checks.nix` names each of them.
- **format** holds the QML to `qmlformat` and the nix files to `nixfmt`;
  `qmlformat -i <file>` and `nix fmt` from `nix develop` put a file right.
- **smoke** starts the packaged shell under a headless sway with two
  outputs and opens every page of the notch and Spotlight from the ipc. It
  fails if the shell does not load, exits, or logs a warning of its own.

The smoke test runs outside the sandbox too, in a session of its own — its
own compositor, runtime directory, home and session bus, and no system bus
— so it is safe to run from inside a live hyprland session:

```sh
nix run .#smoke            # the packaged build
nix run .#smoke -- ./src   # the working tree
```

`shell-smoke ./src` does the same from `nix develop`, and `SMOKE_KEEP=1`
keeps its logs.

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
    terminal = "ghostty";
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
  services/            cpu, memory, disk, network, audio, privacy, bluetooth, mpris, notifications, workspaces, polkit, sums, the clipboard history
  util/                formatting, sample history, pointer bookkeeping
  widgets/             the vocabulary the panels are built from
  notch/               the window, the collapsed pill, the tally, the toasts, and the panels it unfolds into
  spotlight/           the floating search pane, and its rows
  polkit/              the pane that asks for a password, and the field it is typed into
nix/                   the package, the home-manager module, and the checks
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
  `base08` and `base0D` are read from the palette. On a dark palette the
  ground is `base00` pushed most of the way to black, the way the notch is
  the black of the bezel round it, keeping the palette's tint; a light
  palette's ground is left as it is. `Theme.neutral` is twelve steps between
  that ground and `base05`, and every ground and every tier of ink on the
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
  The tiles on the home page are the exception the way a control centre's
  blocks are: modules, each on a ground of its own. The one line the surface
  draws is the hairline between two rows of a list or two sections of a
  page. The floating surfaces — the slab, Spotlight, the password pane, a
  toast, the volume reading — cast one soft shadow; nothing on them casts any. The slab has
  no frame, because it hangs from the edge of the screen rather than
  floating over it; the rest carry a hairline so they hold their edge
  against a window of their own colour. Three radii: small for anything on
  the sheet, medium for a field or a module, large for the surfaces
  themselves — and the slab's own, which goes from the hardware notch's to
  the island's as it unfolds.
- **Type.** One family in four sizes: small for metadata and figures, body
  for everything read, title for the name of a page, display for the clock;
  and Spotlight's field, which is the whole of its pane and is set larger.
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
  Every duration and every spring goes through `Theme.motion`, so with it
  set everything arrives instead of moving; the spinner still turns, because a spinner that
  has stopped means something else.
- **Input.** The window covers the whole screen and never changes size, so
  no unfold waits on the compositor for a new buffer. It is masked down to
  the slab, its notifications, and the strip along the top edge it listens on
  while it is put away, so every pixel the notch is not using belongs to the
  desktop.
- **Frames.** Nothing that cannot be seen moves. A spring on a page that is
  folded away, or on a pill that is off the top edge, goes straight to where
  it is headed, so a closed notch draws no frames for a cpu sample or a
  workspace change.
- **Layout.** The panel is laid out at the full expanded width from the start
  and revealed by the slab growing over it, rather than reflowing on every
  frame of the animation.
- **Margin.** Everything hangs off one left margin — the page's — so the
  clock, the artwork, the headings and the discs line up down the page,
  while the rows bleed out past it to their own edges by their own padding,
  and the modules stand on it.
- **Figures.** Anything that changes on a timer is drawn at a fixed size — a
  dial, a bar, or a right-aligned column of a set width — never as free text
  a layout takes its measurements from. A percentage written out is a
  different width at 7% than at 100%, and a row of them nudges its neighbours
  along every time it ticks.
- **Motion.** The notch moves the way hyprland moves the windows around it,
  and is set up the same way: `curves` in the config names beziers by their
  two control points and springs by their stiffness, dampening and mass, and
  `animations` gives each kind of movement one of them, by hyprland's name
  for the nearest thing it animates and with a speed in tenths of a second.
  The defaults are the hyprland config the notch was drawn against, so the
  same values can be handed to both — see below.
  - Anything that can be sent somewhere new while it is still on its way is
    on a spring, solved exactly for however long each frame took, the way
    hyprland's are: the slab coming out of the top edge and growing into
    the sheet, the volume reading, a knob, a dot, a fill, a dial, a press.
    Reached for and abandoned, opened and closed again, pressed and let go,
    it turns round with the speed it already had instead of stopping dead
    and setting off again. The rest — a toast or a row arriving, the others
    making room, a ground or an ink changing — is on hyprland's beziers.
  - The slab moves first and what it carries follows it, by how far it is
    open rather than on a clock of its own: the pill's contents are gone by
    the time it is a fifth of the way unfolded, the page is all there by two
    thirds, and wherever the slab turns round they are exactly as far in or
    out as it is. Opened or closed with no pointer on it — from a keybind,
    or by a click somewhere else — the whole panel slides out of, or back
    into, the top edge at full size in one movement, and only changes size
    while it is out of sight.
  - Unfolded in place from the pill, the page comes in a section at a time,
    each rising into place a beat after the one above it, so it is read top
    to bottom as it arrives; coming out of the top edge it rides down
    already there. Stepping into a panel and back is a change of workspace:
    the page being left slides a fifth of the way out and fades while the
    one stepped to slides in after it — from the right going in, from the
    left coming back.
  - A ground under the pointer comes up and goes the way a border takes the
    focus, a disc or a button sinks a little while it is held down, a cover
    develops out of its block once it has loaded, and the count on the bell
    pops out of its corner and is knocked each time something new arrives.
  - Everything that moves lands on whole pixels, so text riding on it holds
    still rather than shimmering.

  To have one set of curves drive both, give the shell the same ones the
  hyprland config is written from:

  ```nix
  custom.shell.settings = {
    curves.soft = { type = "spring"; stiffness = 200; dampening = 24; mass = 1; };
    animations.windows = { curve = "soft"; };
  };
  ```
