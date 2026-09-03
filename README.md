# shell

A [quickshell](https://quickshell.org) replacement for the waybar setup that
used to live in `~/dev/systems`. Same bar, same numbers, drawn by QML instead
of GTK so it can grow into something waybar could not do.

## Layout

A 42px top bar on every monitor, transparent except for three rounded pills
inset by 8px:

| | |
| --- | --- |
| left | workspaces of that monitor, focused one highlighted |
| center | `15:00  –  03. September 2026` |
| right | free space on `/`, volume, cpu, available memory, ip address |

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
  shell.qml            one bar per screen
  config/              settings, with defaults overridable from nix
  theme/               palette and metrics derived from the base16 colors
  services/            cpu, memory, disk and network sampling
  widgets/             the pill and the text module it holds
  bar/                 the bar and its modules
```

Directories are importable as `qs.<name>`, so `import qs.theme` gets you
`Theme`.

## Fidelity notes

The bar is a deliberate pixel-for-pixel port, so a few things look odder than
they otherwise would:

- `Theme.shade()` reimplements gtk's css `shade()` because the waybar
  stylesheet used it for the active and urgent workspace colors.
- Text carries a small `letterSpacing`. Pango sized fonts in fractional
  pixels, Qt rounds to whole ones, and without the nudge every string comes
  out ~2.5% narrower than it used to be.
- `Fmt` reproduces waybar's two number formats: one decimal with a binary
  prefix for disk, two decimals with trailing zeros stripped for memory.
- Cpu percentages are truncated rather than rounded, matching waybar's cast.
- Workspace buttons never get narrower than 32px, which is what gtk's button
  min-width did.
