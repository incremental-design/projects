# recurse through the monorepo, linting, testing, building, and publishing every folder with an .envrc file in it
#
# this calls the lint, test, build and publish commands provided by a folder's respective .envrc
#
# ignore the root of the monorepo, when running this command, because root flake.nix also calls this command
{
  pkgs ? import <nixpkgs> {},
  steps ? ["project-lint" "project-lint-semver" "project-build" "project-test" "project-publish-dry-run" "project-publish"],
  ignoreUnchanged ? true,
  cleanup ? false,
}: let
  # remove any invalid steps, and preserve the order of steps
  validSteps = builtins.filter (step:
    builtins.elem step [
      "project-lint"
      "project-lint-semver"
      "project-build"
      "project-test"
      "project-publish-dry-run"
      # we don't recursively publish because we generate a commit for each project publish. therefore we would generate n commits for n projects
    ])
  steps;
  msg =
    if builtins.length validSteps > 0
    then
      builtins.concatStringsSep ", " (builtins.map (step:
        if step == "project-publish-dry-run"
        then "dry-running publish of"
        else if step == "project-test"
        then "testing"
        else if step == "project-lint-semver"
        then "linting semantic version of"
        else if step == "project-lint"
        then "linting"
        else "building")
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

      CWD=$(pwd)

      IGNORE_UNCHANGED=${
        if ignoreUnchanged
        then "true"
        else "false"
      }

      SHA="$(git rev-parse HEAD)"

      parent() {
          dirname "$(realpath "$*")"
      }

      find_envrc() {
        local chk_dir
        chk_dir="$(parent "$*")"

        if [ "$chk_dir" = "$CWD" ]; then
          return 1
        elif [ -e "$chk_dir/.envrc" ]; then
          echo "$chk_dir"
          return 0
        else
          find_envrc "$chk_dir"
        fi
      }

      check() {
        local dir="$*"
        echo "${msg} $dir"

        cd "$dir"
        ls -al ./

        direnv allow

        local rc=1
        ${builtins.concatStringsSep " && " (builtins.map (s: "direnv exec ./ " + s + " \"$IGNORE_UNCHANGED\" \"$SHA\"") validSteps)} && rc=0

        ${
        if cleanup
        then ''
          if [ -L result ]; then
              unlink result
            fi

            if [ -d .direnv ]; then
              rm -rf .direnv
            fi
        ''
        else ''''
      }

        cd "$CWD"
        return $rc
      }

      DIRS=""

      if [ "$IGNORE_UNCHANGED" = "true" ]; then

        CURDIR=""

        for changed in $(git diff-tree -r --name-only "$SHA"); do
          if D=$(find_envrc "$changed"); then
            # assume that git sorts dirs so that we can avoid comparing $D to all other in $DIRS
            if [ "$D" != "$CURDIR" ]; then
              CURDIR="$D"
              DIRS="$DIRS\n$CURDIR"
            fi
          fi
        done

      glow <<-EOF >&2
      ${msg} projects that have changed in the current commit:

      $(echo -e "$DIRS")

      EOF

      else
        while read -r envrc_path; do
          dir=$(dirname "$envrc_path")
          if [ "$dir" != "$CWD" ]; then
            DIRS="$DIRS\n$dir"
          fi
        done < <(fd -H --absolute-path ".envrc")

      glow <<-EOF >&2
      ${msg} all projects:

      $(echo -e "$DIRS")

      EOF
      fi

      # Process each directory
      echo -e "$DIRS" | while IFS= read -r dir; do
        if [ -n "$dir" ]; then
          if ! check "$dir"; then
            echo "$dir failed" >&2
            exit 1
          fi
        fi
      done

    '';
  };
in
  recurse
