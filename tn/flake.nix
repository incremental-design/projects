{
  description = "build and test for tn";

  inputs = {
    parent-flake.url = "path:../";
  };

  outputs = {
    self,
    parent-flake,
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forEachSupportedSystem = f:
      parent-flake.inputs.nixpkgs.lib.genAttrs supportedSystems (
        system:
          f {
            pkgs = import parent-flake.inputs.nixpkgs {inherit system;};
          }
      );
  in {
    packages = forEachSupportedSystem ({pkgs}: {
      default = pkgs.stdenv.mkDerivation {
        name = "tn";
        src = "../"; # Include entire repo as source

        nativeBuildInputs = with pkgs; [
          coreutils
          # INCLUDE THE TOOLS YOU NEED TO BUILD YOUR PACKAGE HERE
        ];

        phases = [
          # "unpackPhase"
          # "patchPhase"
          # "configurePhase"
          "buildPhase"
          # "checkPhase"
          # "installPhase"
          # "fixupPhase"
          # "installCheckPhase"
        ];

        buildPhase = ''

          # make dirs included in package FHS
          # see https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html
          #
          mkdir -p "$out"/{bin,lib,share,include}

          # copy executables to bin/ so they can be nix run
          # copy libraries to lib/
          # copy docs, data to share/
          # copy headers to include/
        '';
      };
    });

    checks = forEachSupportedSystem ({pkgs}: {
      exampleTest =
        pkgs.runCommand "exampleTest" {
          nativeBuildInputs = [self.packages.${pkgs.system}.default];
        } ''
          # name of bin to run default package
          echo "test passed" > "$out"
        '';
    });

    devShells = forEachSupportedSystem ({pkgs}: {
      default = parent-flake.devShells.${pkgs.system}.nix;
    });
  };
}
