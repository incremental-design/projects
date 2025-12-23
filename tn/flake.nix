# 0.1.0
# DO NOT REMOVE THE PRECEDING LINE.
# To bump the semantic version and trigger
# an auto-release when this project is merged
# to main, increment the semantic version above
#
# WHEN AND HOW TO EDIT THIS FLAKE
#
# use this flake when you need to build a project that contains code
# from multiple languages, has custom build steps, or special test
# suites.
#
# This flake inherits the project-lint-semver, project-build and
# project-test commands from the nix dev shell. It includes a custom
# project-lint command, that you can configure to lint the different
# files in the project.
#
# Edit the packages.default to define what the project-build
# command builds.
#
# Edit the checks to define the tests that the project-test
# command runs.
#
# Edit the devShells -> default -> devShellConfig ->  project-lint
# to define a custom lint script.
#
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
      default = let
        devShellNix = pkgs.lib.head (pkgs.lib.filter (config: config.name == "nix") parent-flake.validDevShellConfigs.${pkgs.system});
        devShellConfig = {
          packages =
            (pkgs.lib.filter (pname: pname != "project-lint") devShellNix.packages)
            ++ [
              (pkgs.writeShellApplication {
                name = "project-lint";
                meta = {
                  description = "lint project files"; # list the file types the project-lint command should lint
                  runtimeInputs = with pkgs; [
                    # include packages needed to lint project files
                    alejandra
                  ];
                };
                text = ''
                  # add lint commands for non-nix files that you want to lint

                  # lint all nix files in this directory
                  alejandra -c *.nix
                '';
              })
            ];
          shellHook = devShellNix.shellHook;
        };
      in
        parent-flake.makeDevShell.${pkgs.system} devShellConfig pkgs;
    });
  };
}
