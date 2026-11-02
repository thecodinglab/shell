# shell

A [quickshell](https://quickshell.org) system shell for hyprland, drawn after
the notch and Spotlight on a mac. One notch at the top of every monitor that
comes out when you reach for it and unfolds when you click it, and a
Spotlight that floats over the middle of the screen from a keybind.

## The notch

Revealed it is a 32px tab hanging from the top edge of the screen, drawn the
way the notch on a macbook is: part of the bezel rather than a window, so it
is near black whatever the palette is — the palette's darker end pushed most
of the way to black, keeping its tint — with no frame, its bottom corners
only softened, and its sides flaring out into the top edge where they meet
it, curving into it rather than standing on it at a right angle. It carries
the workspace dots and the clock, and while something is playing it widens
by four grey bars moving at its trailing end, the way a live activity widens
the island. Most of the time it is not there at all: the screen belongs to
the windows on it, nothing is reserved, and all the shell occupies is a few
pixels along the top edge. Reach the top of the screen and the tab slides
back out; leave and it puts itself away again. A notification drops out from
under the top edge on its own, whether the tab is out or not, as a pane of
glass rather than more of the bezel; one that goes back up unread is kept in
the notifications panel, and one that was clicked or put away is not. So
does the volume: set it from a media key and a capsule of glass drops out
under the notch on the focused monitor with the speaker glyph, a bar and the
figure, moves with every further press, and goes back up a moment and a half
after the last one. It is not there while the notch is open, where the
slider already is.

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
out as it grows, from the hardware notch's into the island's. It stays the
bezel as it grows, dark in a light session as well as a dark one, so the pill
and the sheet are one piece of hardware rather than a black tab turning into
a pale window. While it is open a faint line in the palette's tint runs down
its sides and along its bottom, never its top, the way a key line is drawn
round the island on a phone, so the sheet keeps its edge over a window as
dark as it is. It is laid out as a page rather than as a stack of boxes: the
clock is its title, set large at the top left, and the sections follow down
the page with nothing between them but air. Only the things that can be
pressed have a ground of their own, and a list is a column of names with a
hairline between them.

| | |
| --- | --- |
| head | the clock grown into the title with the date under it; at the right the dots where they were, and a bell with a count of what is waiting, which leads to the notifications |
| in use | only while something is: the microphone, the camera, the screen, each a lit disc with its name and the applications using it underneath |
| now playing | one section per mpris player: cover, title, transport, and a scrubber the width of the page |
| sound | the name of the section, where the sound is going, and a bar to set how loud; the head of the section leads to the panel |
| tiles | two rows of two modules, each a capsule on a ground of its own the way the blocks of a control centre are: bluetooth, network, stay awake and system, each a disc, a name and one line on how it is doing; a chevron at the right says the tile leads to a panel, and stay awake, which has none, is a switch the size of the tile |
| session | four discs at the foot: lock, sleep, restart and shut down, the last two asking "Restart?" or "Shut down?" before they do it |

A disc lit in the accent means the thing behind it is on — the bluetooth
radio up, a link carrying an address, the inhibitor held, the microphone
live. Idle is the plain disc, and the line under the name says which. The
accent is spent on nothing else: the fills — a slider, a scrubber, the play
button, the dials and graphs of the system page, the bars moving on the
pill — are the ink itself, so that a bar at half reads as a solid thing
rather than a coloured one, and the one colour on the surface only ever says
*on* or *here*: a lit disc, the workspace you are on, the count of
notifications waiting, the button Return presses, the ring around whatever
the keyboard has reached — and the dot that says the microphone, the camera
or the screen is in use, which is the same *on*. The red is the only other
colour, and says something is wrong or waiting on you: a workspace asking
for attention, a critical notification, a mark waiting for its second press,
a dial at nine tenths or more.

The volume bar is the notch's own control: tall enough to be the target, no
knob, and the speaker glyph riding inside the fill. Drag or scroll the bar to
set it; click the glyph to mute. When the fill passes under the glyph the
glyph swaps its ink, so a bar at nothing and a bar that is muted both still
have their mark. With nowhere for the sound to go, the head of the section
says "No output" and the bar is greyed out and stays put.

The system tile's disc is a ring rather than a glyph — how busy the
processor is, drawn in the ink the way the dials inside are, and red from
nine tenths up — and the line under it carries the processor and memory
figures, "CPU 12% · RAM 26%".

The stay awake tile is an idle inhibitor, and the whole tile is its switch:
pressed, its disc lights, the line under it says "On", and the notch holds a
wayland inhibitor on its window, so hypridle neither locks the screen nor
turns it off; pressed again, the idle daemon is left to its timeouts. A
screen reader hears it as something checked or not, rather than as a
button.

The session marks at the foot of the page put the machine down: four discs
in a row, each with its name under it, all through logind, so a press does
whatever the session is set up to do — lock is `loginctl lock-session`,
which hypridle answers with hyprlock, and sleep is `systemctl suspend`, which
it locks ahead of. Restart and shut down are pressed twice: the first press
turns the disc red and swaps its name for a question — "Restart?", "Shut
down?" — a second one within a few seconds is the answer, and pressing
anything else, or waiting, lets it go. The notch folds before any of them
runs.

Three of the tiles are doors, and so are the bell and the head of the sound
section; each leads to exactly one panel:

- **Notifications** — what has come in and not been dealt with, newest at
  the top, the way a laptop's notification centre keeps it. A toast that
  ran out of time lands here; one that was clicked, answered or put away by
  hand does not, and neither does one the sender marked transient. A
  critical one never runs out of time: it stays under the notch, tinted red,
  until it has been dealt with, and a burst of newer ones pushes the others
  off the screen before it. While the pointer is on a toast its clock stops
  and the sender's name gives way to a cross that puts it away, as a middle
  click does; and one whose sender gave it things to do carries them under
  what it says, up to three, a button each, beside the click on the toast
  itself, which does what the notification is for. Each row is the
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
  pipewire's peak monitor. With no output device at all, the output section
  says so rather than offering a bar with nothing behind it.
- **Bluetooth** — every device bluez knows about, as a list of rows with a
  hairline between them and no ground until the pointer finds them. One click does the obvious next
  thing: pair what is new, connect what is known, hang up on what is already
  connected; a device still making up its mind spins instead and takes no
  clicks until it has finished. The line under each name says what is
  happening to it, or failing that what it is. The field at the top narrows
  the list down, and the list grows the notch until it is half the height of
  the screen and scrolls from there. The header toggles the adapter, and
  spins with "Scanning" beside it while it looks for devices; a machine with
  no adapter has nothing to toggle, and the page says so.
- **Network** — one row per interface `ip` reports as up, titled by what it
  is — Ethernet, Wi-Fi, VPN — with the interface's own name under it, its
  mark beside it and the address it carries at the right. A machine on a
  wire and a vpn at once shows both; a link with a carrier but no address
  says so in red, and a machine on nothing says offline. Bridges and
  container veths are not ways out of the machine and are left out, by the
  name prefixes in `networkIgnore`.
- **System** — cpu, memory and disk: a dial for where each one is now, and
  for the first two the histogram beside it for how it got there over the
  past minute or few ("Past 80 s"), a row each with a hairline between them.
  The disk has no histogram; how full it is does not move on that scale.

The dots are the workspaces hyprland's rules bind to that monitor
(`workspace = 3, monitor:DP-4`), open or not, so every monitor shows only its
own and a click on any dot switches to it. A monitor without such rules shows
the first `workspaceCount` instead. The one you are on stretches into a bar
in the accent, one with windows on it is a filled dot, one that does not
exist yet is a ring, and one asking for attention is a shorter bar in red,
so it is told by its shape as well as its colour.

## Spotlight

The one thing the shell opens from a keybind rather than from the notch:
`shell ipc call spotlight toggle` brings it out on the focused monitor, or
puts it away again if it is already out there. It is drawn after the one on
a mac: two pieces of glass floating a little above the middle of the screen,
where the eye already is. At the head is a capsule that is the field and
nothing else — the magnifier and the caret, set large — and it never moves;
under it, a small gap away, hangs a sheet of results whenever there is
anything to list, growing and shrinking with what it lists.

Blank, it offers the few things that get used most, under *Recents*, and if
nothing has been used yet it is the field alone. Typing narrows everything
that can be started down to what fits, and files it the way Spotlight does:
the best fit on its own as the *Top Hit*, larger, with what it is under its
name — "Web Browser", or failing that "Application"; then the rest of the
*Applications*; then the *Windows* already open, each with its application
and workspace at the far end of its row; then the *Notch*, its own pages —
Sound, Bluetooth, Network, System and Notifications — which open there; then
the *Actions*: the clipboard history, and the two ways out of the session
that are safe to press once, lock and sleep. Restart and shut down want
their second press and stay on the notch's home page where they get it.
`shell ipc call spotlight search <text>` brings it out with the text already
typed.

A query is matched against the name first — the start of it, then the start
of a word in it, then anywhere in it — and only then against what the entry
says about itself, so `spot` puts Spotify ahead of anything that merely
mentions it, and `1pas` finds 1Password. Every word of a query has to land
somewhere. Ties go to what gets used: every pick is counted, weighted toward
lately — a launch a fortnight ago is worth half of one today — and written
to `$XDG_STATE_HOME/shell/launches.json`.

The row Return will open is filled in the accent, with everything on it —
its name, the line under it and the return mark at its right — in the one
ink that reads on the accent; the arrows, or `C-n`/`C-p` and `C-j`/`C-k`,
step it without leaving the field, and a click opens a row directly. Opening
an application puts Spotlight away and launches it; opening a page turns the
notch on the same monitor to it; escape clears the field, and on an empty
field puts Spotlight away, as does a click anywhere else. A console
application — one whose entry asks for a terminal — is run in `terminal`, as
`<terminal> -e <command>`, when one is configured.

A sum is answered as it is typed, the way the calculator in Spotlight on a
mac answers it: `12*7`, `2^10`, `sqrt(2)`, `2pi`, `(1+0.08)^5 - 1`. The
answer is the top hit, set large in figures that line up, with the sum it
answers under it — `12*7 =` — and the search carries on underneath as if it
were not there; Return copies the answer to the clipboard and puts Spotlight
away. The query is read by a small parser of the shell's own, never run: the
four operations, `%` for the remainder, `^` for a power, brackets, and a
handful of names — `pi`, `tau`, `e`, `sqrt`, `abs`, `ln`, `log`, `exp`,
`sin`, `cos`, `tan` and the like. A number on its own is not a sum, so `42`
and `2048` are left to the search, and so is anything with a word in it
that is not one of those names, like `1password`.

The windows already open are found the way the applications are — by title
first, then by the application they belong to — and opening one brings it
forward, on whatever workspace and monitor it is on. They are not counted
the way a launch is, so they never show up under *Recents*.

*Clipboard*, among the actions, turns Spotlight over to what has been
copied: the field carries a *Clipboard* token at its head, so what is being
searched is on screen, and the sheet holds the history cliphist keeps,
newest first, with a picture named for what it is (*PNG image, 1920×1080 ·
240 KiB*). Typing narrows it down, Return puts the entry back on the
clipboard whole and puts Spotlight away, and escape or backspace on an empty
field comes back out to the search. Delete, with the caret at the end of
what is typed, forgets the entry the step is on — a password copied by
mistake, say — and leaves the step on the one that comes up into its place.
While nothing is typed the first row clears the whole history. The step
starts below it, on the newest entry, and it asks before it goes through
with it: pressed once, it turns red and says "Clear clipboard history?", and
only a second press within a few seconds empties the history. Without
cliphist, or before anything has been copied, it says so. The home-manager
module turns on home-manager's `services.cliphist` so the history is being
written down; set `custom.shell.clipboard.enable = false` to leave cliphist
to the rest of the config.

Spotlight is frosted glass on a mac, and so is everything here that floats
over the windows rather than hanging from the edge: Spotlight's two pieces,
the toasts, the volume reading and the password pane. They follow the
palette, light in a light session, and their ground is near opaque —
`glassOpacity`, 0.94 by default — so they read over anything. It goes no
lower than 0.92, and a lower setting is raised to that: every caption on the
glass is measured at that strength laid over a white window, or a black one
under light glass, with nothing blurring it, and any thinner the desktop
would decide whether it can be read. What frosts the desktop behind it is
the compositor; give it a blur rule for the layer:

```lua
hl.layer_rule({ name = "spotlight-blur", match = { namespace = "^shell-spotlight$" }, blur = true, ignore_alpha = 0.5 })
```

The notch's layer can have one too, for the toasts and the volume reading.
The bezel is opaque, so the blur only shows under the glass, and the slab
itself stays crisp:

```lua
hl.layer_rule({ name = "notch-blur", match = { namespace = "^shell-notch$" }, blur = true, ignore_alpha = 0.5 })
```

`ignore_alpha` keeps the blur to the glass itself and off the fainter shadow
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
allow this." Who is being asked comes next, but only when it is not you,
since the sentence already says "your": one other person is named in a
plain line, and when polkit would take any of several — another user,
anyone in a group — it is a pop-up that opens into the list of them, the
one in use checked, and picking another starts over for them. Then the
answer, a capsule that asks whatever PAM asks and shows dots unless it is
told the answer may be seen; under it comes a line for whatever PAM has to
say — a fingerprint reader waiting, an account locked — when it has
anything to say. At the foot are Cancel and Allow, capsules as wide as each
other, Allow in the accent. Return answers and escape gives up. A wrong
answer shakes the pane, says "Incorrect password. Try again.", and leaves
the field empty for another go.

What is typed goes from the field to polkit and nowhere else: it is never
bound to, stored or logged, and the field is emptied the moment it is sent.
Requests that arrive while one is being answered wait their turn, and come
up one after the other in the same pane.

Only one agent can answer for a session. One that runs another —
hyprpolkitagent, polkit-gnome — turns the shell's off:

```nix
custom.shell.settings.polkitAgent = false;
```

As with Spotlight, a blur rule on its layer frosts the desktop behind it:

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

Spotlight keeps the keys in its field. The arrows step through the list and
Return opens what the step is on; escape clears the field, then leaves the
clipboard history, then puts Spotlight away, from the field or from the
clear button beside it; and backspace on an empty field leaves the
clipboard history too. In the history, Delete at the end of what is typed
forgets the entry the step is on.

The pointer stays the arrow over everything that can be pressed, as it does
over a control on a mac — the pointing hand is for a link, and nothing here
is one — and turns into the caret only over a field.

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
  `nix/checks.nix` names each of them. It also holds the tree to the few
  rules of the design system a pattern can catch: no property named `on`
  and a capital, which QML reads as a signal handler; no pointing hand; and
  no colour read off `Theme` itself rather than off one of its two
  materials.
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
  theme/               the two materials, metrics and glyphs derived from the base16 colors
  services/            cpu, memory, disk, network, audio, privacy, bluetooth, mpris, notifications, workspaces, polkit, sums, the clipboard history
  util/                formatting, sample history, pointer bookkeeping
  widgets/             the vocabulary the panels are built from
  notch/               the window, the collapsed pill, the tally, the toasts, and the panels it unfolds into
  spotlight/           the floating search field, the sheet of results under it, and its rows
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
- **Colour.** Two materials, each one neutral scale, and between them one
  accent and one red. Only `base00`, `base05`, `base08` and `base0D` are read
  from the palette. The *bezel* — the pill, the tally, the sheet and every
  panel on it — is the palette's darker end pushed 55% of the way to black,
  keeping its tint, with the lighter end as its ink, so it is the black of
  the screen's frame in a light session as much as in a dark one. The
  *pane*, the glass, follows the palette: dark, its ground is `base00`
  pushed 30% toward black, a little lighter than the bezel it drops out from
  under; light, it is `base00` itself, with `base05` pushed 35% toward black
  as the ink, since a light palette's own ink leaves no room for four tiers
  of text. Light and dark are told apart by the luminance of `base00`. Each
  material is a `Scheme`: twelve steps from its ground to its ink, spaced for
  which way round they are — a dark ground needs bigger steps low down,
  where the grounds live, and a light one needs the ink pushed further
  before it reads as text — and every role the surface draws with is one of
  those steps by name: the module, the wash a row shows under the pointer,
  the field, the disc, the hairline, the track, and four inks from
  `textFaint`, for what is disabled, through `textDim` and `textMuted` to
  `text`. The two have the same role names, so a widget asks for
  `scheme.text` and gets the ink of whichever material it stands on:
  `Theme.schemeOf(item)` answers the pane if anything the item sits in is
  tagged as glass, and the bezel otherwise. On glass the grounds are washes
  of the ink rather than opaque steps, so a lit row lets the glass show
  through the way the glass lets the desktop. Every ink that has to be read
  clears 4.5:1 against every ground it is allowed on, in both palettes and
  with the glass at its floor over pure white or pure black with no blur;
  `textDim` is never set on a disc or a button, where it would not. The
  accent is pushed toward the ink only as far as it takes to stand out — on
  the bezel far enough to read on a lit row, since a light palette's blue is
  drawn for a light ground — and is spent on state alone. As a word or a
  glyph it is `accentInk`, pushed further where it has to be read; whatever
  is drawn on an accent fill — the selected row in Spotlight, the count on
  the bell, the label of the default button, the glyph in a lit disc — is
  `inkOnAccent`, the ground cut out of it where that reads on the fill and
  on its hover, and white or black where it does not. The fills are the ink
  itself, and the red is the palette's pulled a little toward the ink, so it
  warns without shouting.
- **Material.** Two, and the line between them is the line between fixed
  and floating. The bezel is opaque and has no frame, because it hangs from
  the edge of the screen rather than floating over it. Open, it casts one
  soft shadow, and a key line a few steps up its scale runs down its sides
  and along its bottom, so it keeps its edge over a window as dark as it is;
  the line comes in with the unfold, so the pill stays plain hardware.
  Everything that floats over the windows — a toast, the volume reading,
  Spotlight, the password pane — is glass: the pane's ground laid at
  `glassOpacity` and never below the 0.92 its inks are measured at, a
  hairline of the ink drawn over its edge, the way the rim of a sheet of
  glass catches the light, and the same one soft shadow. Nothing on either
  casts any. On both, a page, not a stack of boxes: content sits directly on
  the sheet and is told apart by the air around it; nothing has a ground of
  its own until the pointer, or the keyboard, finds it, except a disc, a
  switch, a bar, a field and a button, which are raised because they are the
  things you set. The tiles on the home page are the exception the way a
  control centre's blocks are: modules, each on a ground of its own. The one
  line the surface draws is the hairline between two rows of a list or two
  sections of a page.
- **Type.** One family, on the steps a mac sets its own text in: small at
  11 for metadata and figures (its subheadline), body at 13 for everything
  read and every control with a word on it (its body), title at 15 for the
  name of a page and the clock on the pill (title 3), 22 for what is typed
  into Spotlight's field (title 1), and display at 28 for the clock at the
  head of the page, a little over its large title. Small sits far enough
  under body that size carries some of the hierarchy; weight and ink carry
  the rest — regular for what is read, medium for names and the words on
  buttons, demibold for headings, titles and the large clock, and bold only
  for what the password pane is asking. The mono is there for the nerd font
  glyphs alone, and no glyph stands on its own: each sits beside a name or
  on a button that says in words what it does, which is read out and put up
  as a tooltip once the pointer has rested on it. Anything that ticks is set
  with tabular figures, so a clock turning over does not reflow the row it
  is in. `displayFamily` is the optical size the clock and the titles are
  cut at, and defaults to Inter's display cut when the session is set in
  Inter.
- **Grid.** Four units. Every length in `Theme.qml` is a design unit put
  through `Theme.px()`, and every layout length is a multiple of four of
  them — the spacing tokens `space1` to `space8` — so the whole surface snaps
  to one grid and scales as one piece. Strokes and hairlines are not layout
  and are drawn at the size they need. Three radii — small for artwork, a
  row's ground and a tooltip, medium for what sits a page margin inside the
  sheet, large for Spotlight's sheet — and the corners of the surfaces are
  worked out from them rather than picked: the radius of what is inside plus
  the distance to it, so a corner within a corner runs parallel to it all
  the way round. The open sheet's is the medium radius a page margin out, a
  toast's is its icon's a padding out, a row in Spotlight's is the sheet's
  less the inset it sits at, and the password pane's is its capsules' a page
  margin out; the slab's goes from the hardware notch's to the island's as
  it unfolds. Anything you press or type into is a capsule or a circle — a
  tile, a button, a field, a switch, a disc. Nothing outside `Theme.qml`
  names a colour, a size or a duration.
- **Keyboard.** Everything that can be pressed can be tabbed to, and says
  what it is to a screen reader. The focus ring is drawn in the accent, just
  inside the edge of the control so a row in a scrolling list keeps all of
  it, and only while the keyboard is what is being used — see `Nav`. The
  pointer stays the arrow over every control; the pointing hand is for
  links, and there are none.
- **Reduced motion.** There is no `prefers-reduced-motion` on wayland for
  the shell to ask about, so `reducedMotion` in the config is the switch.
  Every duration and every spring goes through `Theme.motion`, so with it
  set everything arrives instead of moving; the spinner still turns, because a spinner that
  has stopped means something else.
- **Reduced transparency and increased contrast.** The two settings a mac
  keeps beside reduced motion, and switches in the config for the same
  reason. `reducedTransparency` makes the glass solid. `increaseContrast`
  does that too, and moves the quiet inks a step toward full strength and
  the hairlines, the tracks, the rims and the key line a few steps harder.
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
  - Spotlight's sheet of results grows and shrinks with what it lists on
    the spring a window moves on (`windowsMove`) rather than the one the
    notch unfolds on, which is quicker and all but critically damped: it
    changes with nearly every key, and is read rather than watched. It
    comes out already at its size, and the field above it never moves at
    all.
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
