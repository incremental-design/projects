{
  pkgs ? import <nixpkgs> {},
  tool ? import ./tool.nix {inherit pkgs;},
}: let
  paths = [
    (pkgs.writeShellApplication
      {
        name = "nix";
        meta = {
          description = "the version of nix to use in the current working directory";
        };
        runtimeInputs = [
          tool
          pkgs.coreutils
        ];
        text = ''
          # THIS script is included in $PATH. we have to remove it, so that it doesn't invoke itself
          SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
          PATH="''${PATH//$SCRIPT_DIR:/}"

            if ! type nix >/dev/null ; then

                echo "nix is not installed. Please install it from https://determinate.systems/nix/" >&2
                exit 1
            fi

            NIX_VERSION=$(nix --version)

            if ! VERSION=$(nix eval "$PWD#nixVersion"); then
                echo "nix flake does not have a nix_version in its outputs, using ''${NIX_VERSION}" >&2
                nix "$@"
            else
                tool "nix" "$VERSION" "$@"
            fi
        '';
      })
    (pkgs.writeShellApplication
      {
        name = "project-lint";
        meta = {
          description = "lint all .nix files in current working directory, with alejandra";
        };
        runtimeInputs = with pkgs; [alejandra git];
        text = ''
          CHANGED=0
          ALL=0

          ARGS=()

          for arg in "$@"; do
              if [[ "$arg" == "--changed" ]]; then
                  CHANGED=1
              elif [[ "$arg" == "--all" ]]; then
                  ALL=1
              else
                  ARGS+=("$arg")
              fi
          done

          if (( ALL == 1 && CHANGED == 1 )); then
              echo "cannot submit both --all and --changed" >&2
              exit 1
          elif (( CHANGED == 1 )); then
              readarray -t changed < <(git log HEAD^..HEAD --name-only --pretty=format: -- '*.nix')
              LEN_CHANGED="''${#changed[@]}"

              if (( LEN_CHANGED == 0 )); then
                  echo "no .nix files changed in ''${PWD}, nothing to lint." >&2
                  exit 0
              fi
              alejandra "''${changed[@]}" "''${ARGS[@]}" || exit 1
          else
            alejandra "''${PWD}" "''${ARGS[@]}" || exit 1
          fi
        '';
      })
    (pkgs.writeShellApplication
      {
        name = "project-build";
        meta = {
          description = "build all packages in the nix flake";
        };
        runtimeInputs = [pkgs.jq];
        text = ''
          function package_names(){
            nix eval .#packages --apply "p: let
            platform = ''${1};
            packages = if builtins.hasAttr platform p then p.\''${platform} else p;
            packageNames = builtins.attrNames packages;
            in
            builtins.toJSON packageNames" 2>/dev/null || echo "\"[]\""
          }

          CURR_SYSTEM=$(nix eval --impure --expr "builtins.currentSystem")

          while read -r packageName; do
            if ! nix build ".#''${packageName}" --no-link --print-out-paths; then
                echo "failed to build ''${PWD}/flake.nix package ''${CURR_SYSTEM}.''${packageName}" >&2
                exit 1
            fi
          done < <(package_names "$CURR_SYSTEM" | jq 'fromjson | .[]')
        '';
      })
    (pkgs.writeShellApplication
      {
        name = "project-test";
        meta = {
          description = "run all tests in the nix flake";
        };
        text = ''
          nix flake check
        '';
      })
  ];
in
  paths
