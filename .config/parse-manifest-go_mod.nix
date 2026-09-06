{
  pkgs ? import <nixpkgs> {},
  tool ? import ./tool.nix {inherit pkgs;},
}: let
  paths = [
    (pkgs.writeShellApplication {
      name = "go";
      meta = {
        description = "the version of go to use in the current working directory";
      };
      runtimeInputs = [
        tool
        pkgs.coreutils
        pkgs.go
        pkgs.jq
      ];
      text = ''
          # THIS script is included in $PATH. we have to remove it, so that it doesn't invoke itself
          SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
          PATH="''${PATH//$SCRIPT_DIR:/}"

          if ! VERSION=$(go mod edit -json 2>/dev/null | jq -r .Go); then
              VERSION="1.27.1"
          fi

          tool "go" "$VERSION" "$@"
      '';
    })
    (pkgs.writeShellApplication {
      name = "project-lint";
      meta = {
        description = "lint the go module in the current working directory";
      };
      runtimeInputs = [
        tool
        pkgs.coreutils
      ];
      text = ''
          VERSION=$(tool "go" "1.27.1" mod edit -json | jq -r .Go)

          IFS=. read -r MAJOR MINOR <<< "$VERSION"

          if (( MAJOR == 1 )) && (( MINOR >= 26 )); then
              VERSION="2.13.2" # go ^1.26 --> golangci-lint 2.13.2
          fi

          tool "golangci-lint" "$VERSION" run --fix "$@"
      '';
    })
    (pkgs.writeShellApplication {
      name = "project-lint-semver";
      meta = {
        description = "lint the semantic version of the go module in the current working directory";
      };
      runtimeInputs = [
        tool
        pkgs.coreutils
      ];
      text = ''

      '';
    })
    (pkgs.writeShellApplication {
      name = "project-build";
      meta = {
        description = "build the go module in the current working directory";
      };
      runtimeInputs = [
        tool
        pkgs.coreutils
      ];
      text = ''
        VERSION=$(tool "go" "1.27.1" mod edit -json | jq -r .Go)

        tool "go" "$VERSION" build "$@"
      '';
    })
    (pkgs.writeShellApplication {
      name = "project-test";
      meta = {
        description = "test the go module in the current working directory";
      };
      runtimeInputs = [
        tool
        pkgs.coreutils
      ];
      text = ''
          VERSION=$(tool "go" "1.27.1" mod edit -json | jq -r .Go)

          tool "go" "$VERSION" test "$@"
      '';
    })
  ];
in
  paths
