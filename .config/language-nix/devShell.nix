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

            LINES=""
            while IFS= read -r dirent; do
              if [ -f "$dirent" ]; then
                LINES="''${LINES:+$LINES$'\n'}$dirent"
              fi
            done < <(ls)

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
      # receives a commit hash, prints semantic version of the project
      # at the hash to stdout.
      #
      # In most languages, the semantic version is stored in
      # a project manifest (e.g. package.json, pyproject.toml, cargo.toml)
      # but in nix, the semantic version is stored in the most recent
      # project tag
      (pkgs.writeShellApplication
        {
          name = "project-lint-semver";
          meta = {
            description = "lint the semantic version of a .nix project";
          };
          runtimeInputs = [pkgs.git];
          text = ''
            COMMIT=$(git rev-parse HEAD)

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
        })
      # build the default package in the current project's flake
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
      (pkgs.writeShellApplication
        {
          name = "project-publish-dry-run";
          meta = {
            description = "dry-run publish nix packages";
          };
          text = ''

            LINES="''${1:-}"

            if [ -z "$LINES" ]; then
            cat << 'EOF' >&2
            received no $1, expected a multi-line argument as follows:

            1   |    current semantic version
            2   |    new semantic version
            3   |    changelog
            ... |    changelog continued...

            EOF
            exit 1
            fi

            echo "📦 dry-running publish" >&2
          '';
        })
      # receives the previous semantic version, current semantic version and changelog as follows:
      #
      # 1   |    current semantic version
      # 2   |    new semantic version
      # 3   |    changelog
      # ... |    changelog continued...
      #
      # exits 0 if semantic version of the project manifest matches the current semantic version, else exits 1
      (pkgs.writeShellApplication
        {
          name = "project-publish";
          meta = {
            description = "publish nix packages";
          };
          text = ''

            LINES="''${1:-}"

            if [ -z "$LINES" ]; then
            cat << 'EOF' >&2
            received no $1, expected a multi-line argument as follows:

            1   |    current semantic version
            2   |    new semantic version
            3   |    changelog
            ... |    changelog continued...

            EOF
            exit 1
            fi

            mapfile -t lines <<< "$LINES"
            CURRENT_SEMANTIC_VERSION=''${lines[0]}
            NEW_SEMANTIC_VERSION=''${lines[1]}

            # a flake.nix has no concept of a semantic version. So,
            # we just prepend the semantic version as a comment

            update_flake_version() {
                local semantic_version="$1"

                # Check if flake.nix exists
                if [ ! -f "flake.nix" ]; then
                echo "Error: flake.nix not found in current directory" >&2
                exit 1
                fi

                # Step 1: Make tempfile
                local temp_file=""
                temp_file=$(mktemp) || {
                echo "Error: Could not create temporary file" >&2
                exit 1
                }

                # Step 2: Cat entire flake.nix into tempfile
                cat flake.nix > "$temp_file"

                # Step 3: Read FIRST line from tempfile, then delete it
                local second_line=""
                second_line=$(head -n 1 "$temp_file")
                tail -n +2 "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"

                # Step 4: Set first_line variable
                local project_name=''${PWD##*/}
                local first_line="# ''${project_name}/v''${semantic_version}"

                # Step 5: Check if second_line matches version pattern, if not prepend it
                if [[ ! "$second_line" =~ ^#[[:space:]]*[[:alnum:]_-]+/v[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
                # Prepend second_line to tempfile
                echo "$second_line" > "$temp_file.tmp"
                cat "$temp_file" >> "$temp_file.tmp"
                mv "$temp_file.tmp" "$temp_file"
                fi

                # Step 6: Prepend first_line to tempfile
                echo "$first_line" > "$temp_file.tmp"
                cat "$temp_file" >> "$temp_file.tmp"
                mv "$temp_file.tmp" "$temp_file"

                # Step 7: Move tempfile back to flake.nix
                mv "$temp_file" flake.nix || {
                echo "Error: Could not update flake.nix" >&2
                exit 1
                }
            }
            update_flake_version "$NEW_SEMANTIC_VERSION"

            glow <<-EOF >&2
            # updated flake from $CURRENT_SEMANTIC_VERSION to $NEW_SEMANTIC_VERSION

            \`\`\`nix
            $(head -n 15 flake.nix)
            ...
            \`\`\`
            EOF
          '';
        })
    ];
    shellHook = '''';
  };
in
  devShellConfig
