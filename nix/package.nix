{
  lib,
  stdenvNoCC,
  formats,
  makeWrapper,
  quickshell,
  coreutils,
  iproute2,
  # Overrides for the defaults in src/config/Config.qml, written next to
  # shell.qml as config.json. The home-manager module fills this in from
  # stylix and the host's settings.
  settings ? { },
}:

let
  configFile = (formats.json { }).generate "shell-config.json" settings;
in
stdenvNoCC.mkDerivation {
  pname = "shell";
  version = "0.1.0";

  src = ../src;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/shell
    cp -r ./. $out/share/shell

    ${lib.optionalString (settings != { }) ''
      cp ${configFile} $out/share/shell/config.json
    ''}

    makeWrapper ${lib.getExe quickshell} $out/bin/shell \
      --add-flags "--path $out/share/shell" \
      --prefix PATH : ${
        lib.makeBinPath [
          coreutils # stat, for the disk module
          iproute2 # ip, for the network module
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "Custom quickshell bar";
    mainProgram = "shell";
    platforms = lib.platforms.linux;
  };
}
