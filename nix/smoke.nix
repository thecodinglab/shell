{
  writeShellApplication,
  coreutils,
  dbus,
  findutils,
  gnugrep,
  gnused,
  iproute2,
  quickshell,
  sway,
  systemd,
  shell,
}:

# The smoke test as a program of its own, so `nix flake check` and a person
# at a terminal run the same thing: see smoke.sh.
writeShellApplication {
  name = "shell-smoke";

  runtimeInputs = [
    coreutils
    dbus
    findutils
    gnugrep
    gnused
    quickshell
    sway
    # what the package's wrapper puts on the path, for a run against the
    # working tree to have them too
    iproute2
    systemd
  ];

  runtimeEnv.SMOKE_SHELL = "${shell}/bin/shell";

  text = builtins.readFile ./smoke.sh;
}
