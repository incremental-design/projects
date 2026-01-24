{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellApplication {
  name = "stubProject";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.git
  ];
  text = ''
    PROJECT_DIR="$1"
    FLAKE_DIR="$2"

    if [ -z "$PROJECT_DIR" ]; then
        echo "PROJECT_DIR not passed in as first argument" >&2
        exit 1
    fi

    if [ -z "$FLAKE_DIR" ]; then
        echo "FLAKE_DIR not passed in as second argument" >&2
        exit 1
    fi

    PROJECT=''${PROJECT_DIR##*/}             # Extract basename using parameter expansion
    PROJECT=''${PROJECT//[^a-zA-Z0-9-]/_}    # Replace invalid chars with underscore

    # make a flake.nix
    cat <<-EOT > "$PROJECT_DIR/flake.nix"
    # see parse-manifest-flake_nix.nix to find out how
    # project-lint, project-lint-semver, project-build, and
    # project-test are run against this flake
    {
      description = "build and test for $PROJECT";

      inputs = {
        flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*";

        nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*";
      };

      outputs = {
        flake-schemas,
        nixpkgs,
        self,
        ...
      }: let
        supportedSystems = [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ];
        forEachSupportedSystem = f:
          nixpkgs.lib.genAttrs supportedSystems (system:
            f {
              pkgs = import nixpkgs {inherit system;};
            });
      in {

        # https://determinate.systems/blog/flake-schemas/#defining-your-own-schemas
        schemas = flake-schemas.schemas // {
            nixVersion = {
            version = 1;
            doc = "The nix version required to run this flake";
            type = "string";
            };
        };

        # nixVersion specifies the nix version needed to run this flake
        nixVersion = "2.33.1";

        packages = forEachSupportedSystem ({pkgs}: {
          default = pkgs.stdenv.mkDerivation {
            name = "$PROJECT";
            src = "$FLAKE_DIR"; # Include entire repo as source

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

            buildPhase = '''

              # make dirs included in package FHS
              # see https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html
              #
              mkdir -p "\$out"/{bin,lib,share,include}

              # copy executables to bin/ so they can be nix run
              # copy libraries to lib/
              # copy docs, data to share/
              # copy headers to include/
            ''';
          };
        });

        checks = forEachSupportedSystem ({pkgs}: {
          exampleTest =
            pkgs.runCommand "exampleTest" {
              nativeBuildInputs = [self.packages.\''${pkgs.system}.default];
            } '''
              # name of bin to run default package
              echo "test passed" > "\$out"
            ''';
        });
      };
    }
    EOT

    # stage flake.nix so Nix can see it
    git -C "$PROJECT_DIR" add flake.nix

    # generate flake.lock for reproducibility
    (cd "$PROJECT_DIR" && nix flake update)

    # stage all project files
    git -C "$PROJECT_DIR" add .
  '';
}
