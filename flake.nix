{
  description = "custom quickshell notch shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};

      # the smoke test, for the checks, the app and the dev shell alike —
      # see nix/smoke.sh
      smokeFor =
        system: (pkgsFor system).callPackage ./nix/smoke.nix { shell = self.packages.${system}.shell; };
    in
    {
      packages = forAllSystems (system: rec {
        shell = (pkgsFor system).callPackage ./nix/package.nix { };
        default = shell;
      });

      homeModules = rec {
        shell = import ./nix/hm-module.nix { inherit self; };
        default = shell;
      };

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.quickshell
              pkgs.kdePackages.qtdeclarative # qmlls, qmlformat
              (smokeFor system) # shell-smoke ./src
              # what the package's wrapper puts on the path that a desktop
              # does not have already, for spotlight's clipboard
              pkgs.cliphist
              pkgs.wl-clipboard
            ];

            shellHook = ''
              echo "run the shell against the working tree with: quickshell --path ./src"
            '';
          };
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);

      # ── checks ────────────────────────────────────────────────────────────
      #
      # `nix flake check` lints, format-checks and smoke-tests the shell — see
      # nix/checks.nix. The smoke test runs outside the sandbox too, against
      # the packaged build with `nix run .#smoke` or against the working tree
      # with `nix run .#smoke -- ./src`.
      checks = forAllSystems (
        system: (pkgsFor system).callPackages ./nix/checks.nix { shell-smoke = smokeFor system; }
      );

      apps = forAllSystems (system: {
        smoke = {
          type = "app";
          program = nixpkgs.lib.getExe (smokeFor system);
          meta.description = "Run the shell under a headless compositor and fail on its warnings";
        };
      });
    };
}
