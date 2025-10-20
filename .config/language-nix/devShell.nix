{pkgs ? import <nixpkgs> {}}: let
  devShellConfig = {
    packages = {
      "nix-2.28.4" = pkgs.nix;
      # receives a newline-separated list of files to lint
      lint = pkgs.writeShellApplication {
        name = "lint";
        meta = {
          description = "lint .nix files";
        };
        runtimeInputs = with pkgs; [
          alejandra
        ];
        text = ''

          LINES="''${1:-}"

          if [ -z "$LINES" ]; then
          cat << EOF >&2
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
          alejandra -c "''${nixfiles[@]}" >&2
        '';
      };
      # receives a commit hash, prints semantic version of the project
      # at the hash to stdout.
      #
      # In most languages, the semantic version is stored in
      # a project manifest (e.g. package.json, pyproject.toml, cargo.toml)
      # but in nix, the semantic version is stored in the most recent
      # project tag
      lintSemVer = pkgs.writeShellApplication {
        name = "lintSemVer";
        meta = {
          description = "lint the semantic version of a .nix project";
        };
        runtimeInputs = [pkgs.git];
        text = ''
          COMMIT="$1"

          # nix has no concept of a manifest with a version. It uses git tags instead

          PROJECT="$(git rev-parse --show-prefix)"
          PROJECT="''${PROJECT%?}"
          MAJOR=""
          MINOR=""
          PATCH=""

          # we purposefully duplicate the code from devShell.nix into here so that if
          # one accidentally diverges from the other, then the lintSemVer command will
          # fail
          function parse_semver(){
              local tag
              tag="$1"

              local project
              project="$2"

              if tag=$(echo "$tag" | grep -E "^$project/v[0-9]+\.[0-9]+\.[0-9]+$" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+$"); then

                echo "$tag"
                return 0
              fi
              return 1
          }

          while read -r SHA; do

            while read -r TAG; do

              if sv=$(parse_semver "$TAG" "$PROJECT"); then
                IFS='.' read -ra parts <<< "$sv"
                MAJOR="''${parts[0]}"
                MINOR="''${parts[1]}"
                PATCH="''${parts[2]}"
              fi

            done < <(git describe --tags --exact-match "$SHA" 2>/dev/null)

            if [ -n "$MAJOR" ]; then
              echo "$MAJOR.$MINOR.$PATCH"
              exit 0
            fi

          done < <(git rev-list "$COMMIT" 2>/dev/null)

          echo "none"
        '';
      };
      # receives a newline-separated list of files in the project and builds them
      #
      # prints each built artifact to stdout
      build = pkgs.writeShellApplication {
        name = "build";
        meta = {
          description = "build .nix files";
        };
        runtimeInputs = with pkgs; [
          nix
        ];
        text = ''

          LINES="''${1:-}"

          if [ -z "$LINES" ]; then
          cat << EOF >&2
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
            echo "🔨 building $nixfile" >&2
            nix build -f "$nixfile" --no-link --print-out-paths
          done
        '';
      };
      # receives a list of files in the project and tests them
      #
      # prints each test artifact, such as a coverage report, to stdout
      runTest = pkgs.writeShellApplication {
        name = "runTest";
        meta = {
          description = "test .nix files - this is a no-op, since we haven't set up any test framework for nix";
        };
        runtimeInputs = with pkgs; [
          nix
        ];
        text = ''

          LINES="''${1:-}"

          if [ -z "$LINES" ]; then
          cat << EOF >&2
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
            echo "🧪 test $nixfile" >&2
          done
          exit 0
        '';
      };
      # receives the previous semantic version, current semantic version and changelog as follows:
      #
      # 1   |    current semantic version
      # 2   |    new semantic version
      # 3   |    changelog
      # ... |    changelog continued...
      #
      # dry-runs the publish steps for each flake in a project
      #
      # exits 0 if semantic version of the project manifest matches the current semantic version, else exits 1
      publishDryRun = pkgs.writeShellApplication {
        name = "publishDryRun";
        meta = {
          description = "dry-run publish nix packages. this is a no-op because we have not set up publishing";
        };
        text = ''

          LINES="''${1:-}"

          if [ -z "$LINES" ]; then
          cat << EOF >&2
          received no $1, expected a multi-line argument as follows:

          1   |    current semantic version
          2   |    new semantic version
          3   |    changelog
          ... |    changelog continued...

          EOF
          exit 1
          fi

          mapfile -t lines
          CURRENT_SEMANTIC_VERSION="''${lines[0]}"
          NEW_SEMANTIC_VERSION="''${lines[1]}"
          CHANGELOG=$(printf "%s\n" "''${lines[@]:2}")

          echo "📦 dry-running publish" >&2

          echo "$CURRENT_SEMANTIC_VERSION" >&2
          echo "$NEW_SEMANTIC_VERSION" >&2
          echo "$CHANGELOG" >&2

        '';
      };
      # receives the previous semantic version, current semantic version and changelog as follows:
      #
      # 1   |    current semantic version
      # 2   |    new semantic version
      # 3   |    changelog
      # ... |    changelog continued...
      #
      # exits 0 if semantic version of the project manifest matches the current semantic version, else exits 1
      publish = pkgs.writeShellApplication {
        name = "publish";
        meta = {
          description = "publish nix packages. this is a no-op because we have not set up publishing";
        };
        text = ''

          LINES="''${1:-}"

          if [ -z "$LINES" ]; then
          cat << EOF >&2
          received no $1, expected a multi-line argument as follows:

          1   |    current semantic version
          2   |    new semantic version
          3   |    changelog
          ... |    changelog continued...

          EOF
          exit 1
          fi

          mapfile -t lines
          CURRENT_SEMANTIC_VERSION="''${lines[0]}"
          NEW_SEMANTIC_VERSION="''${lines[1]}"
          CHANGELOG=$(printf "%s\n" "''${lines[@]:2}")

          echo "📦 publishing" >&2

          echo "$CURRENT_SEMANTIC_VERSION" >&2
          echo "$NEW_SEMANTIC_VERSION" >&2
          echo "$CHANGELOG" >&2

        '';
      };
    };
    shellHook = '''';
  };
in
  devShellConfig
