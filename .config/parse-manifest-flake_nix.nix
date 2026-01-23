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
        runtimeInputs = with pkgs; [alejandra];
        text = ''
          alejandra "''${PWD}/*" "$@" || exit 1
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
          # project-lint-semver [<from-hash> <to-hash>]
          #
          # run this command without any arguments to lint semver from HEAD to BASE
          # run this command with two commit hashes, <from-hash> and <to-hash> to compare semvers
          # at the two hashes

          if [ -n "$(git status --short)" ]; then
              echo "working directory contains uncommitted changes, cannot project-lint-semver. stash or discard changes and then try again" >&2
              exit 1
          fi

          FROM_HASH=""
          TO_HASH=""

          for arg in "$@"; do
              if [[ "$arg" == "--all" || "$arg" == "--changed" ]]; then
                  continue
              fi

              if [ -z "$FROM_HASH" ]; then
                  FROM_HASH="$arg"
              elif [ -z "$TO_HASH" ]; then
                  TO_HASH="$arg"
              else
                  echo "too many arguments" >&2
                  exit 1
              fi
          done

          if [ -n "$FROM_HASH" ] && [ -z "$TO_HASH" ]; then
              echo "you must provide two hashes to compare semantic versions at each" >&2
              exit 1
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

          # given two lists of packages from get_package_versions, $1 and $2, iterate through each list, verifying that matching packages semvers decrease from $1 to $2, and accumulating
          # unmatched packages into a returned list
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

          function fileExistsAtHash(){
              local hash="$1"
              if ! git cat-file -e "''${hash}:flake.nix" 2>/dev/null; then
                  return 1
              fi
          }

          # handle case where we lint semver from HEAD all the way to BASE
          if [ -z "$FROM_HASH" ] && [ -z "$TO_HASH" ]; then

              CURR_BRANCH=$(git rev-parse --abbrev-ref HEAD)

              readarray -t commits < <(git log --pretty=format:"%H" -- "''${PWD}/flake.nix")

              LEN="''${#commits[@]}"

              if (( LEN == 1 )); then
                  echo "''${PWD}/flake.nix has never changed since it was introduced in ''${commits[0]}" >&2
                  exit 0
              elif (( LEN == 0 )) then
                  echo "''${PWD} has never had a flake.nix" >&2
                  exit 0
              fi

              ACC_PKGS=""
              CURR_PKGS=""

              for ((i=0; i<LEN-1; i++))
              do
                  git -c advice.detachedHead=false checkout "''${commits[i]}" 2>/dev/null

                  CURR_PKGS=$(get_package_versions)

                  if [ -z "$ACC_PKGS" ]; then
                      ACC_PKGS="$CURR_PKGS"
                  else
                      if ! ACC_PKGS=$(lint_package_semvers "$ACC_PKGS" "$CURR_PKGS" 2>/dev/null); then
                        echo "project-lint-semver failed for ''${PWD}/flake.nix because package semantic versions decreased after ''${commits[i]}." >&2
                        git -c advice.detachedHead=false checkout "$CURR_BRANCH" 2>/dev/null
                        exit 1
                      fi
                  fi
              done
              git -c advice.detachedHead=false checkout "$CURR_BRANCH" 2>/dev/null
              exit 0
          fi

          # handle case where we compare flake.nix package semvers at two hashes
          if ! fileExistsAtHash "$FROM_HASH"; then
            echo "''${PWD}/flake.nix does not exist at ''${FROM_HASH}" >&2;
              exit 1
          fi

          if ! fileExistsAtHash "$TO_HASH"; then
            echo "''${PWD}/flake.nix does not exist at ''${TO_HASH}" >&2;
              exit 1
          fi

          TO_PACKAGES=""
          FROM_PACKAGES=""

          if ! git -c advice.detachedHead=false checkout "$TO_HASH" 2>/dev/null; then
              echo "Failed to checkout ''${TO_HASH}" >&2;
              exit 1
          fi

          TO_PACKAGES=$(get_package_versions 2>/dev/null)

          if ! git -c advice.detachedHead=false checkout "$FROM_HASH" 2>/dev/null; then
              echo "Failed to checkout ''${FROM_HASH}" >&2;
              exit 1
          fi

          FROM_PACKAGES=$(get_package_versions 2>/dev/null)

          if [ -z "$TO_PACKAGES" ] && [ -z "$FROM_PACKAGES" ]; then
            echo "''${PWD}/flake.nix does not contain any packages at ''${TO_HASH} or ''${FROM_HASH}. Nothing to compare." >&2;
              exit 0
          fi

          if [ -z "$TO_PACKAGES" ]; then
            echo "''${PWD}/flake.nix does not contain any packages at ''${TO_HASH}. Cannot compare to ''${FROM_HASH}" >&2;
              exit 0
          fi

          if [ -z "$FROM_PACKAGES" ]; then
            echo "''${PWD}/flake.nix does not contain any packages at ''${FROM_HASH}. Cannot compare to ''${TO_HASH}" >&2;
              exit 0
          fi

          if ! lint_package_semvers "$TO_PACKAGES" "$FROM_PACKAGES"; then
              echo "lint_package_semvers failed from ''${FROM_HASH} to ''${TO_HASH}" >&2
              exit 1
          fi
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
