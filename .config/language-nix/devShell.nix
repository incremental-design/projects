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
          ];
          text = ''

            LINES="''${1:-}"

            if [ -z "$LINES" ]; then
            cat << 'EOF' >&2
            received no $1, expected a multi-line argument as follows:

            file1.nix                     <- first line
            file2.nix                     <- second line
            file3.nix                     <- remaining lines
            ...
            ...

            EOF
            exit 1
            fi

            mapfile -t lines <<< "$LINES"

            # Filter to only .nix files
            nixfiles=()
            for line in "''${lines[@]}"; do
              if [[ "$line" == *.nix ]]; then
                nixfiles+=("$line")
              fi
            done

            for nixfile in "''${nixfiles[@]}"; do
              echo "🔍 linting $nixfile" >&2
            done
            if [ ''${#nixfiles[@]} -gt 0 ]; then
              alejandra -c "''${nixfiles[@]}" >&2
            fi
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
            nix
          ];
          text = ''
            if [ ! -f "flake.nix" ]; then
              echo "flake.nix not found in current directory, no default package to build" >&2
              exit 0
            fi

            echo "🔨 Building default package..." >&2
            nix build
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
              echo "no flake.nix current directory, nothing to flake check" >&2
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
