{pkgs ? import <nixpkgs> {}}: let
  devShellConfig = {
    name = "nix";
    packages = {
      # receives a list of files with uncommitted changes
      # in the current project and lints each of them
      lint = pkgs.writeShellApplication {
        name = "lint";
        meta = {
          description = "lint .nix files";
        };
        runtimeInputs = with pkgs; [
          alejandra
        ];
        text = ''
          for nixfile in "$@"; do
            echo "🔍 linting $nixfile" >&2
          done
          alejandra -c "$@" >&2
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
      # receives a list of files with uncommitted changes in the current
      # project and builds each of them
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
          for nixfile in "$@"; do
            echo "🔨 building $nixfile" >&2
            nix build -f "$nixfile" --no-link --print-out-paths
          done
        '';
      };
      # receives a list of files with uncommitted changes
      # in the current project and tests each of them
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
          for nixfile in "$@"; do
            echo "🧪 test $nixfile" >&2
          done
          exit 0
        '';
      };
      publishDryRun = pkgs.writeShellApplication {
        name = "publishDryRun";
        meta = {
          description = "dry-run publish nix packages. this is a no-op because we have not set up publishing";
        };
        text = ''
          for nixfile in *.nix; do
            echo "📦 dry-running publish $nixfile" >&2
          done
        '';
      };
      publish = pkgs.writeShellApplication {
        name = "publish";
        meta = {
          description = "publish nix packages. this is a no-op because we have not set up publishing";
        };
        text = ''
          for nixfile in *.nix; do
            echo "📦 publishing $nixfile" >&2
          done
        '';
      };
    };
    shellHook = '''';
  };
in
  devShellConfig
