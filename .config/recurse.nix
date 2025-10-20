# recurse through the monorepo, linting, testing, building, and publishing every folder with an .envrc file in it
#
# this calls the lint, test, build and publish commands provided by a folder's respective .envrc
#
# ignore the root of the monorepo, when running this command, because root flake.nix also calls this command
{
  pkgs ? import <nixpkgs> {},
  steps ? ["lint" "lintSemVer" "build" "runTest" "publishDryRun" "publish"],
  ignoreUnchanged ? true,
  cleanup ? false,
}: let
  # remove any invalid steps, and preserve the order of steps
  validSteps = builtins.filter (step:
    builtins.elem step [
      "lint"
      "lintSemVer"
      "build"
      "runTest"
      "publishDryRun"
      "publish"
    ])
  steps;
  msg =
    if builtins.length validSteps > 0
    then
      builtins.concatStringsSep ", " (builtins.map (step:
        if step == "publishDryRun"
        then "dry-running publish"
        else if step == "runTest"
        then "testing"
        else if step == "lintSemVer"
        then "linting semantic version"
        else step + "ing")
      validSteps)
    else "";
  recurse = pkgs.writeShellApplication {
    name = "recurse";
    runtimeInputs = with pkgs; [
      fd
      coreutils
      git
      direnv
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

      parent() {
          dirname "$(realpath "$*")"
      }

      find_envrc() {
        local chk_dir
        chk_dir="$(parent "$*")"

         if [ "$chk_dir" = "$CWD" ]; then
          echo "$chk_dir"
         elif [ -e "$chk_dir/.envrc" ]; then
         return
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

        ${builtins.concatStringsSep "\n" (["SHA=$(git rev-parse HEAD)"] ++ (builtins.map (s: "direnv exec ./ " + s + " \"$SHA\"") validSteps))}

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
      }

      DIRS=""

      if [ "$IGNORE_UNCHANGED" = "true" ]; then

        CURDIR=""

        for changed in $(git show --name-only --format=""); do
          D=$(find_envrc "$changed")
          if [ -z "$D" ]; then
              echo "no .envrc found for $changed" >&2
          elif [ "$D" != "$CURDIR" ]; then
            CURDIR="$D"
            DIRS="$DIRS\n$CURDIR"
          fi
        done

        cat <<-EOF >&2
          ${msg} projects that have changed in the current commit:

          $(echo -e "$DIRS")

      EOF

      else
        for dir in $(dirname "$(fd -H --absolute-path ".envrc")"); do
          if [ "$dir" != "$CWD" ]; then
            DIRS="$DIRS\n$dir"
          fi
        done

        cat <<-EOF >&2
          ${msg} all projects:

          $DIRS

      EOF
      fi



    '';
  };
in
  recurse
