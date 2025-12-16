{pkgs ? import <nixpkgs> {}}: let
  devShellConfig = {
    packages = [
      # make nix package manager available in the dev env
      pkgs.nix
      # receives a newline-separated list of files to lint
      (pkgs.writeShellApplication
        {
          name = "project-lint";
          meta = {
            description = "lint all .nix files";
          };
          runtimeInputs = with pkgs; [
            alejandra
            gnugrep
            findutils
          ];
          text = ''
            # Filter arguments to only .nix files and pass to alejandra
            printf '%s\0' "$@" | grep -z '\.nix$' | xargs -0 -r alejandra -c
          '';
        })
      (pkgs.writeShellApplication {
        name = "project-lint-semver";
        meta = {
          description = "ensure the semantic version of a nix flake increases over time";
          runtimeInputs = with pkgs; [
            git
          ];
        };
        text = ''
          SHA="''${1:-}"
          FIRST_LINE=""
          PARSED_SEMVER="0.0.0"

          function parse_semver() {
            if [[ "$FIRST_LINE" =~ ^#[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+) ]]; then
              PARSED_SEMVER="''${BASH_REMATCH[1]}"
            fi
          }

          # Get relative path from git root to current directory
          RELATIVE_PATH=$(git rev-parse --show-prefix)
          FLAKE_PATH="''${RELATIVE_PATH}flake.nix"

          if [ -n "$SHA" ]; then
            # Get first line of flake.nix at specific SHA without changing working directory
            if git cat-file -e "$SHA:$FLAKE_PATH" 2>/dev/null; then
              FIRST_LINE=$(git show "$SHA:$FLAKE_PATH" | head -n1)
            else
              echo "No flake.nix found at SHA $SHA, using $PARSED_SEMVER" >&2
              FIRST_LINE=""
            fi
          else
            FIRST_LINE=$(head -n1 flake.nix 2>/dev/null || echo "")
          fi

          parse_semver

          echo "$PARSED_SEMVER"
        '';
      })
      (pkgs.writeShellApplication
        {
          name = "project-build";
          meta = {
            description = "build the default package in the project's flake.nix";
          };
          runtimeInputs = with pkgs; [
            coreutils
            fd
            nix
          ];
          text = ''
            # Run nix build and capture output
            if [ ! -f "flake.nix" ]; then
              echo "no flake.nix in ''${PWD}. Nothing to build" >&2
              exit 0
            fi
            if ! nix build; then
              echo "error" >&2
              exit 1
            fi

            # nix build will always output result* symlinks e.g. result/, result-dev/, result-docs/ ...
            # print absolute path to each, split paths by null bytes
            fd --max-depth 1 --type l "result*" -0 --absolute-path
          '';
        })
      # run all checks in the current project's flake
      (pkgs.writeShellApplication
        {
          name = "project-test";
          meta = {
            description = "run all checks in a project's flake.nix";
          };
          runtimeInputs = with pkgs; [
            nix
          ];
          text = ''
            if [ ! -f "flake.nix" ]; then
              echo "no flake.nix ''${PWD}, nothing to flake check" >&2
              exit 0
            fi

            echo "🧪 Running nix flake check..." >&2
            nix flake check
          '';
        })
    ];
    shellHook = '''';
  };
in
  devShellConfig
