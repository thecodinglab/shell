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
            ];

            shellHook = ''
              echo "run the shell against the working tree with: quickshell --path ./src"
            '';
          };
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);
    };
}
