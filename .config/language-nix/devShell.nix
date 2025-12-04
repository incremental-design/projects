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
