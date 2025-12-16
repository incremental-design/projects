# recurse through the monorepo, linting, testing, building, and publishing every folder with an .envrc file in it
#
# this calls the lint, test, build and publish commands provided by a folder's respective .envrc
#
# ignore the root of the monorepo, when running this command, because root flake.nix also calls this command
#
# pass "false" as $1 to recurse through ALL projects, regardless of whether they have changed
#
# pass any additional arguments as $2... and they will be directly passed to steps as $1...
#
# if this script is built without any steps, it just prints the directories on which it would have run the steps
# to stdout
{
  pkgs ? import <nixpkgs> {},
  steps ? ["project-lint" "project-lint-semver" "project-build" "project-test"],
}: let
  # remove any invalid steps, and preserve the order of steps
  validSteps = builtins.filter (step:
    builtins.elem step [
      "project-lint"
      "project-build"
      "project-test"
      "project-lint-semver"
    ])
  steps;
  msg =
    if builtins.length validSteps > 0
    then
      builtins.concatStringsSep ", " (builtins.map (
          step:
            if step == "project-test"
            then "testing"
            else if step == "project-lint"
            then "linting"
            else if step == "project-lint-semver"
            then "linting semantic version of"
            else "building"
        )
        validSteps)
    else "";
  recurse = pkgs.writeShellApplication {
    name = "recurse";
    runtimeInputs = with pkgs; [
      fd
      coreutils
      git
      direnv
      glow
    ];
    text = ''
      if [ ! -d .git ]; then
        echo "please run this script from the root of the monorepo" >&2 && exit 1
      fi

      IGNORE_UNCHANGED=''${1:-"true"}

      CWD=$(pwd)

      function check() {
        local dir="$*"
        cd "$dir"

        direnv allow
        echo "${msg} $dir" >&2

        # force rebuild of env flake
        if [ -d ".direnv" ]; then
          rm -rf ".direnv"
        fi

        local failAt=""

        ${
        builtins.concatStringsSep "" (
          builtins.map (
            step: ''
              if [ -z "$failAt" ] && ! direnv exec ./ ${step} "''${@:2}" > /dev/null; then
                failAt="${step}"
              fi
            ''
          )
          validSteps
        )
      }

        # clear any .direnv so that other processes
        # have a clean working dir
        if [ -d ".direnv" ]; then
          rm -rf ".direnv"
        fi

        cd "$CWD"

        if [ -n "$failAt" ]; then
        echo "error: ''${failAt} failed in ''${dir}"
        return 1
        fi
      }

      DIRS=()

      PROJECTS="projects that have changed"

      if [ "$IGNORE_UNCHANGED" = "true" ]; then
        # Get all directories with .envrc files and check each for changes
        while IFS= read -r -d "" envrc_dir; do
          # Check if anything changed in this directory between HEAD~1 and HEAD
          if git diff --quiet HEAD~1 HEAD -- "$envrc_dir" && git diff --quiet HEAD -- "$envrc_dir"; then
            # No changes in this directory
            continue
          else
            # Directory has changes, add to array
            envrc_dir="$(realpath "$envrc_dir")"
            if [ "$envrc_dir" != "$CWD" ]; then
              DIRS+=("$envrc_dir")
            fi
          fi
        done < <(fd --type f --hidden '.envrc' . --exec printf '%s\0' '{//}')

      else
        while IFS= read -r -d "" envrc_dir; do
            envrc_dir="$(realpath "$envrc_dir")"
          if [ "$envrc_dir" != "$CWD" ]; then
            DIRS+=("$envrc_dir")
          fi
        done < <(fd --type f --hidden '.envrc' . --exec printf '%s\0' '{//}')
        PROJECTS="all projects"
      fi


      glow <<-EOF >&2
      ${msg} $PROJECTS:

      $(printf "%s\n" "''${DIRS[@]}")

      EOF

      # Process each directory
      ${
        if builtins.length validSteps > 0
        then ''
          for dir in "''${DIRS[@]}"; do
            if [ -n "$dir" ]; then
              if ! ERR_MSG=$(check "$dir"); then
                echo "$ERR_MSG" >&2
                exit 1
              fi
            fi
          done
        ''
        else ''
          printf "%s\0" "''${DIRS[@]}"
        ''
      }

    '';
  };
in
  recurse
