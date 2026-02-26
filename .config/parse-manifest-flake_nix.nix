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
            alejandra "''${PWD}/*" "''${ARGS[@]}" || exit 1
          fi
        '';
      })
    (pkgs.writeShellApplication
      {
        name = "project-lint-semver";
        meta = {
          description = "lint the semantic versions of all packages in a nix flake, if they exist";
        };
        runtimeInputs = with pkgs; [git jq];
        text = ''
          # usage
          # project-lint-semver [ --all | --changed ] [<from-hash> <to-hash>]
          #
          # run this command without any arguments to lint semver from HEAD to BASE
          # run this command with two commit hashes, <from-hash> and <to-hash> to compare semvers
          # between the two hashes
          #
          # nix flakes are different from most other manifest files. Most manifest files contain ONE
          # semantic version, but nix flakes can contain zero or more.
          #
          # A nix flake contains packages, each of which might have a semantic version
          #
          # e.g.
          #      _______
          #     / flake.nix
          #     |       |
          #     |       |
          #     |___,___|
          #         |
          #         |- inputs
          #         |   |
          #         |   |- flake-schemas
          #         |   |   |
          #         |   |   '- url
          #         |   |
          #         |   '- nixpkgs
          #         |       |
          #         |       '- url
          #         |
          #         '- outputs
          #             |
          #             |- schemas
          #             |
          #             |- nixVersion
          #             |
          #             |- packages
          #             :   |
          #                 |- package-A
          #                 |   |
          #                 |   '- version
          #                 |
          #                 |- package-B
          #                 |
          #                 '- package-C
          #                     |
          #                     '- version
          #
          # The packages within a flake can vary from one commit to another. This script
          # checks ALL commits within a range of commits, and gets the set of packages that
          # existed for part or all of that range. Then, it verifies that the semantic version
          # of each package that existed did not decrease in subsequent commits within that
          # range.
          #
          #     COMMIT
          #                                                                                   | 0.0.9 < 0.1
          #   * 83ebda...       "2.1.1"          "1.0.1"                           "0.0.9"    < a package version cannot decrease in a
          #   |                    :                :                                 :       | subsequent commit
          #   |                    :                :                                 :
          #   |                    :                :            package-C            :
          #   |                    :                :             deleted             :
          #   |                    :                :                :                :
          #   * 45bd33...       "2.1.1"          "1.0.1"           "0.1"            "0.1"
          #   |                    :                :                :                :
          #   |                    :            package-B            :                :
          #   |                    :             created             :                :
          #   |                    :                                 :                :
          #   |                    :                                 :                :        | <unversioned> is filled in as 0.0.0
          #   * aa3ee3...       "2.1.0"                           "0.0.1"       <unversioned>  < a package cannot be versioned in one commit
          #   |                    :                                 :                :        | and then unversioned in a subsequent commit
          #   |                    :                             package-C            :
          #   |                    :            package-B         created             :
          #   |                    :             deleted                              :
          #   |                    :                :                                 :
          #   * bbee23...       "2.1.0"           "0.1"                             "0.1"
          #   |                    :                :                                 :
          #   |                    :                :                                 :
          #   |                    :                :                                 :
          #   |                    :                :                                 :
          #   |                    :                :                                 :
          #   * eabc21...       "2.0.1"       <unversioned>                     <unversioned>
          #   |                    :                :                                 :
          #   |                package-A        package-B                         package-D
          #   |                 created          created                           created
          #   :                               ------^------
          #   :                               a package can be
          #                                   created and then
          #                                   deleted in a
          #                                   subsequent commit
          #                                   and then even
          #                                   created again.
          #                                   Its semantic version
          #                                   is valid as long
          #                                   as it does not
          #                                   decrease in
          #                                   subsequent
          #                                   commits


          if [ -n "$(git status --short)" ]; then
              echo "working directory contains uncommitted changes, cannot project-lint-semver. stash or discard changes and then try again" >&2
              exit 1
          fi

          FROM_HASH=""
          TO_HASH=""

          for arg in "$@"; do
              if [[ "$arg" == "--all" && -z "$FROM_HASH" ]]; then
                  continue
              elif [[ "$arg" == "--all" ]]; then
                  echo "if --all is passed, it must appear before $FROM_HASH in args list" >&2
                  exit 1
              elif [[ "$arg" == "--changed" && -z "$FROM_HASH" ]]; then
                  continue
              elif [[ "$arg" == "--changed" ]]; then
                  echo "if --changed is passed, it must appear before $FROM_HASH in args list" >&2
                  exit 1
              elif [ -z "$FROM_HASH" ]; then
                  FROM_HASH="$arg"
              elif [ -z "$TO_HASH" ]; then
                  TO_HASH="$arg"
              else
                  echo "too many arguments" >&2
                  exit 1
              fi
          done

          if [[ -n "$FROM_HASH"  &&  -z "$TO_HASH" ]]; then
              echo "you must provide two hashes to lint semantic versions between them" >&2
              exit 1
          fi

          FIRST_COMMIT="$(git rev-list --max-parents=0 HEAD)"

          if [ -z "$FROM_HASH" ] && [ -z "$TO_HASH" ]; then
            FROM_HASH="$FIRST_COMMIT" # very first commit of all time
            TO_HASH=$(git rev-parse HEAD) # latest commit on current branch
          elif [[ "$FROM_HASH" != "$FIRST_COMMIT" ]]; then
              FROM_HASH="''${FROM_HASH}^"   # FROM_HASH parent, so that FROM_HASH is included in comparison
          fi

          function get_package_versions(){
              nix eval .#packages --apply 'p: let
              isPackage = i: builtins.hasAttr "type" i && i.type == "derivation";
              attrsToList = a: builtins.attrValues (builtins.mapAttrs (name: value: {inherit name value;}) a);
              version = i: if builtins.hasAttr "version" i then i.version else "";
              unwrapPackage = distribution: package: [{name=package.name; version=version package; distribution=distribution;}];
              unwrapDistribution = distributionName: distributionPackages: builtins.concatMap (package: unwrapPackage distributionName package) (builtins.attrValues distributionPackages);
              packageVersions = builtins.concatMap (p: if isPackage p.value then unwrapPackage "" p.value else unwrapDistribution p.name p.value) (attrsToList p);
              formattedPackageVersions = builtins.toJSON packageVersions;
              in formattedPackageVersions' 2>/dev/null || return 0
          }

          # given two lists of packages from get_package_versions, $1 and $2, iterate through each list,
          # verifying that matching packages semvers decrease from $1 to $2. Then, return the full outer
          # join with right-side-preference
          function lint_package_semvers(){

              if [ -z "$2" ]; then
                  echo "$1"
                  return 0
              fi

              if nix eval --expr "
              let
              curr = builtins.fromJSON ''${1};
              prev = builtins.fromJSON ''${2};
              match = currEl: prev: builtins.filter(prevEl: prevEl.name == currEl.name && prevEl.distribution == currEl.distribution) prev;
              matchSingle = matched: if builtins.length matched > 1 then builtins.throw \"duplicate packages found: \''${builtins.toString matched}\" else if builtins.length matched == 1 then builtins.head matched else null;
              parseMajorMinorPatch = s: builtins.match \"([0-9]+)\\.([0-9]+)\\.([0-9]+)\" s;
              parseMajorMinor = s: builtins.match \"([0-9]+)\\.([0-9]+)\" s;
              parseMajor = s: builtins.match \"([0-9]+)\" s;
              parseSemver = s: if s == \"\" then [ \"0\" \"0\" \"0\" ] else if parseMajorMinorPatch s != null then parseMajorMinorPatch s else if parseMajorMinor s != null then (parseMajorMinor s) ++ [\"0\"] else if parseMajor s != null then (parseMajor s) ++ [ \"0\" \"0\" ] else builtins.throw \"\''${s} is not a valid semantic version\";
              getSemverComponent = l: i: builtins.fromJSON (builtins.elemAt l i);
              compareSemvers = left: right: builtins.foldl' (acc: curr: if acc != 0 then acc else curr) 0 (map (i: if (getSemverComponent left i) > (getSemverComponent right i) then 1 else if (getSemverComponent left i) < (getSemverComponent right i) then -1 else 0) (builtins.genList(i: i) 3));
              replacePackage = curr: prev: if prev == null then curr else if compareSemvers (parseSemver curr.version) (parseSemver prev.version) < 0 then builtins.throw \"\''${curr.name} semver decreased from \''${prev.version} to \''${curr.version}\" else prev;
              mergeCurrPrev = curr: prev: (map(p: replacePackage p (matchSingle(match p prev))) curr) ++ (builtins.filter(p: builtins.length(builtins.filter(c: c.name == p.name) curr) == 0) prev);
              in
              builtins.toJSON (mergeCurrPrev curr prev)
              "; then
                  return 0
              fi
              return 1
          }

          function render_packages_jsonl(){
              echo "$3" | jq -r . | jq -c --arg pwd "$2" --arg hash "$1" '.[] | {path: "\($pwd)#packages.\(.distribution).\(.name)", version: .version, hash: $hash}'
          }

          COMMITS_WITH_CHANGE=()
          readarray -t COMMITS_WITH_CHANGE < <(git log "$FROM_HASH..$TO_HASH" --pretty=format:"%H" -- "''${PWD}/flake.nix") # only commits in which ./flake.nix changed
          COMMITS_WITH_CHANGE_LEN="''${#COMMITS_WITH_CHANGE[@]}"

          ALL_COMMITS=()
          readarray -t ALL_COMMITS < <(git log "$FROM_HASH..$TO_HASH" --pretty=format:"%H") # all commits
          ALL_COMMITS_LEN="''${#ALL_COMMITS[@]}"

          CURR_BRANCH=$(git rev-parse --abbrev-ref HEAD)

          CHANGED_INDEX=0
          ALL_INDEX=0

          ACC_PKGS="$(get_package_versions)"
          CURR_PKGS="$ACC_PKGS"
          RELPATH="$(git rev-parse --show-prefix)"


          for (( ALL_INDEX = 0; ALL_INDEX < ALL_COMMITS_LEN; ALL_INDEX++)); do

          if (( CHANGED_INDEX == COMMITS_WITH_CHANGE_LEN )); then
              break
              # the FIRST commit at which the flake.nix changed is always the commit at which it was created
          fi

            if [[ "''${ALL_COMMITS[$ALL_INDEX]}" == "''${COMMITS_WITH_CHANGE[$CHANGED_INDEX]}" ]]; then
                echo "|       " >&2
                echo "|       ''${COMMITS_WITH_CHANGE[$CHANGED_INDEX]} - ''${PWD}/flake.nix changed " >&2
                echo "|       linting package semantic versions" >&2
                echo "'       " >&2

                CHANGED_INDEX=$((CHANGED_INDEX + 1))

                git -c advice.detachedHead=false checkout "''${ALL_COMMITS[$ALL_INDEX]}" 2>/dev/null
                CURR_PKGS="$(get_package_versions)"

                if ! ACC_PKGS="$(lint_package_semvers "$ACC_PKGS" "$CURR_PKGS")"; then
                  echo "package semvers decreased from ''${ALL_COMMITS[$ALL_INDEX]} to ''${ALL_COMMITS[0]}" >&2
                  git -c advice.detachedHead=false checkout "$CURR_BRANCH" 2>/dev/null
                  exit 1
                fi
            else
                echo "|       " >&2
                echo "|       ''${ALL_COMMITS[$ALL_INDEX]} - ''${PWD}/flake.nix did not change" >&2
                echo "'       " >&2
            fi

            render_packages_jsonl "''${ALL_COMMITS[$ALL_INDEX]}" "$RELPATH" "$CURR_PKGS"
          done

          for ((; ALL_INDEX < ALL_COMMITS_LEN; ALL_INDEX++)); do
              echo "|       " >&2
              echo "|       ''${ALL_COMMITS[$ALL_INDEX]} - ''${PWD}/flake.nix did not exist, skipping" >&2
              echo "'       " >&2
          done
          git -c advice.detachedHead=false checkout "$CURR_BRANCH" 2>/dev/null
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
