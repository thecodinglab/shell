{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.shell;

  # Follow stylix when it is in the picture, so the notch keeps matching the
  # rest of the session without having to restate the palette here.
  hasStylix = config ? stylix && config.stylix.enable;
  colors = config.lib.stylix.colors.withHashtag;

  stylixSettings = lib.optionalAttrs hasStylix {
    inherit (colors)
      base00
      base05
      base08
      base0D
      ;

    sansFamily = config.stylix.fonts.sansSerif.name;
    monoFamily = config.stylix.fonts.monospace.name;
    fontSize = config.stylix.fonts.sizes.desktop;
  };
in
{
  options.custom.shell = {
    enable = lib.mkEnableOption "the quickshell notch";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "shell.packages.\${system}.default";
      description = "The shell package to run.";
    };

    systemd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run the shell as a user service tied to the graphical session.";
    };

    # Spotlight's clipboard history is cliphist's: the shell only reads it,
    # so something has to be writing it down.
    clipboard.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Record the clipboard history Spotlight shows, by turning on
        home-manager's `services.cliphist`.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      example = lib.literalExpression ''
        {
          diskPath = "/";
          networkInterface = "enp13s0";
        }
      '';
      description = ''
        Overrides for the defaults in `src/config/Config.qml`, serialized to
        `config.json`. Colors and fonts default to the stylix ones when stylix
        is enabled.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    let
      package = cfg.package.override { settings = stylixSettings // cfg.settings; };
    in
    {
      home.packages = [ package ];

      systemd.user.services.shell = lib.mkIf cfg.systemd.enable {
        Unit = {
          Description = "Custom quickshell notch";
          PartOf = [ config.wayland.systemd.target ];
          After = [ config.wayland.systemd.target ];
        };

        Service = {
          ExecStart = lib.getExe package;
          Restart = "on-failure";
        };

        Install.WantedBy = [ config.wayland.systemd.target ];
      };

      # a default, so a config that sets up cliphist its own way wins
      services.cliphist.enable = lib.mkIf cfg.clipboard.enable (lib.mkDefault true);
    }
  );
}
