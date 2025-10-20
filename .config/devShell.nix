{
  pkgs ? import <nixpkgs> {},
  devShellConfigs ? (import ./importFromLanguageFolder.nix {inherit pkgs;}).importDevShell,
}: let
  validatePackage = attrName: p:
    if !builtins.isAttrs p
    then throw "invalid package, not an attrset: ${p}"
    else if !builtins.hasAttr "name" p
    then throw "invalid package, missing name: ${p}"
    else if p.name != attrName
    then throw "invalid package ${p.name}, should be named ${attrName}: ${p}"
    else if !builtins.hasAttr "meta" p
    then throw "invalid package ${p.name}, missing meta: ${p}"
    else if !builtins.hasAttr "description" p.meta
    then throw "invalid package ${p.name}, missing description: ${p}"
    else if !builtins.pathExists "${p}/bin"
    then throw "invalid package ${p.name}, missing /bin dir: ${p}"
    else if builtins.readDir "${p}/bin" == {}
    then throw "invalid package ${p.name}, empty /bin dir: ${p}"
    else true;
  validDevShellConfigs = map (c:
    if
      builtins.isAttrs c
      && (builtins.all (x: x) (map (attrName: builtins.hasAttr attrName c) ["name" "packages" "shellHook"]))
      && (builtins.all (x: x) (map (p: validatePackage p.name p.value) (pkgs.lib.attrsToList c.packages)))
    then c
    else builtins.throw "invalid devShellConfig ${c}")
  devShellConfigs;
  wrappedPackages = devShellConfig:
    pkgs.lib.fix (
      self:
        devShellConfig.packages
        // (
          if builtins.hasAttr "lint" devShellConfig.packages
          then {
            # wraps project lint script, which checks for syntax errors
            # in the current project.
            #
            # provides the project lint script with the list of
            # uncommitted changes to the project.
            #
            # only invokes the project lint script if the project has
            # uncommitted changes.
            lint = pkgs.writeShellApplication {
              name = "lint";
              meta = devShellConfig.packages.lint.meta;
              runtimeInputs = [pkgs.git devShellConfig.packages.lint];
              text = ''
                items=()
                while IFS= read -r file; do
                  items+=("$(realpath "$file")")
                done < <(git status --porcelain -- . | cut -c4-)
                #                                  ^
                #                 get modified files

                if [[ "''${#items[@]}" -gt 0 ]]; then
                  lint "''${items[@]}" || (echo "failed to lint $(realpath .)" >&2 && exit 1)
                else
                  echo "nothing new to lint: no files changed in $(realpath .)" >&2
                fi
              '';
            };
          }
          else throw "devShellConfig ${devShellConfig.name} missing lint"
        )
        // (
          if builtins.hasAttr "lintSemVer" devShellConfig.packages
          then {
            # wraps project lintSemVer script, which gets the semantic
            # version of the project, at the HEAD commit.
            #
            # for each commit where the project changed, lintSemVer
            # 1. gets the semantic version of the project, according to
            #    its <project>/v<major>.<minor>.<patch> .
            # 2. compares it to the semantic version of the project according
            #    to the project's lintSemVer.
            # 3. errors if the semantic version according to git tags does
            #    not match the semantic version according to project's
            #    lintSemVer script.
            # 4. errors if the semantic version decreases.
            # 5. prints the current semantic version of the project
            #    to stdout.
            lintSemVer = pkgs.writeShellApplication {
              name = "lintSemVer";
              meta = devShellConfig.packages.lintSemVer.meta;
              runtimeInputs = [pkgs.git devShellConfig.packages.lintSemVer];
              text = ''

                PROJECT="$(git rev-parse --show-prefix)"
                PROJECT="''${PROJECT%?}"
                MAJOR=""
                MINOR=""
                PATCH=""

                REPORT=""

                function version(){
                    local major
                    major="$1"

                    local minor
                    minor="$2"

                    local patch
                    patch="$3"

                    local version

                    if [ -z "$major" ]; then
                      version="none"
                    else
                      version="$major.$minor.$patch"
                    fi

                    echo "$version"
                }

                function add_to_report(){
                    local commit
                    commit="$1"

                    local sv
                    sv="$2"

                    local message
                    message="$3"

                REPORT=$(cat <<- EOF
                | $commit | $sv | $message |
                $REPORT
                EOF
                )
                }

                function print_report(){
                REPORT=$(glow <<- EOF >&2
                | commit | version | message |
                |:-------|:--------|:--------|
                $REPORT
                EOF
                )

                echo "$REPORT" >&2
                }

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

                function try_increment_semver(){

                    local sv
                    sv="$1"

                    local major
                    major="$2"

                    local minor
                    minor="$3"

                    local patch
                    patch="$4"

                    local bumpMajor
                    local bumpMinor
                    local bumpPatch

                    IFS='.' read -ra parts <<< "$sv"
                    bumpMajor="''${parts[0]}"
                    bumpMinor="''${parts[1]}"
                    bumpPatch="''${parts[2]}"

                    local fail
                    fail=""

                    if [ -z "$major" ]; then
                      fail=""
                    elif [[ "$bumpMajor" -lt "$major" ]]; then
                      fail="major version $bumpMajor in $bumpMajor.$bumpMinor.$bumpPatch must be greater than or equal to $major.$minor.$patch"
                    elif [[ "$bumpMajor" -gt "$major" ]]; then
                      fail=""
                    elif [[ "$bumpMinor" -lt "$minor" ]]; then
                      fail="minor version $bumpMinor in $bumpMajor.$bumpMinor.$bumpPatch must be greater than or equal to $major.$minor.$patch"
                    elif [[ "$bumpMinor" -gt "$minor" ]]; then
                      fail=0
                    elif [[ "$bumpPatch" -le "$patch" ]]; then
                      fail="patch version $bumpPatch in $bumpMajor.$bumpMinor.$bumpPatch must be greater than or equal to $major.$minor.$patch"
                    fi

                    echo "$bumpMajor.$bumpMinor.$bumpPatch"

                    if [[ -n "$fail" ]]; then
                      echo "$fail" >&2
                      return 1
                    fi

                    return 0
                }

                SEMVER_BUMPED=0
                while read -r SHA; do

                SEMVER_BUMPED=0

                  while read -r TAG; do

                    TAG_SV=""

                      if TAG_SV=$(parse_semver "$TAG" "$PROJECT"); then
                        if TAG_SV=$(try_increment_semver "$TAG_SV" "$MAJOR" "$MINOR" "$PATCH"); then
                          IFS='.' read -ra parts <<< "$TAG_SV"
                          MAJOR="''${parts[0]}"
                          MINOR="''${parts[1]}"
                          PATCH="''${parts[2]}"

                          SEMVER_BUMPED=1
                        else
                          add_to_report "''${SHA:0:8}" "$TAG_SV" "$(git log -1 --pretty=format:'%s' "$SHA" 2>/dev/null)"
                          print_report
                          echo "^^^^"
                          echo "semantic version in project decreased from \"$(version "$MAJOR" "$MINOR" "$PATCH")\" to \"$TAG_SV\""
                          exit 1
                        fi

                      fi

                  done < <(git describe --tags --exact-match "$SHA" 2>/dev/null)

                  PROJECT_SV=""
                  if PROJECT_SV=$(lintSemVer "$SHA"); then
                    if [ "$PROJECT_SV" != "$(version "$MAJOR" "$MINOR" "$PATCH")" ]; then
                      add_to_report "''${SHA:0:8}" "$PROJECT_SV" "$(git log -1 --pretty=format:'%s' "$SHA" 2>/dev/null)"
                      print_report
                      echo "^^^^"
                      echo "semantic version in project manifest is \"$PROJECT_SV\", expected \"$(version "$MAJOR" "$MINOR" "$PATCH")\""
                      exit 1
                    fi
                  else
                    add_to_report "''${SHA:0:8}" "$(version "" "" "")" "$(git log -1 --pretty=format:'%s' "$SHA" 2>/dev/null)"
                    print_report
                    echo "^^^^"
                    echo "failed to retrieve semver from project manifest at commit $SHA" >&2
                    exit 1
                  fi

                if [[ "$SEMVER_BUMPED" -eq 1 ]]; then
                  add_to_report "''${SHA:0:8}" "$(version "$MAJOR" "$MINOR" "$PATCH")" "$(git log -1 --pretty=format:'%s' "$SHA" 2>/dev/null)"
                fi

                done < <(git rev-list --reverse HEAD)
                #                                   ^^^
                #                                   we don't use -- . to filter out
                #                                   changes that don't affect project
                #                                   because it is possible for a semver
                #                                   tag to be applied to a commit that
                #                                   contains no change

                print_report

                echo "current version:" >&2
                version "$MAJOR" "$MINOR" "$PATCH"  # print version to stdout
                                                    # so that we can use it
                                                    # in other scripts

              '';
            };
          }
          else throw "devShellConfig ${devShellConfig.name} missing lintSemVer"
        )
        // (
          if builtins.hasAttr "build" devShellConfig.packages
          then {
            # wraps the project build script.
            #
            # provides the project build script with the list uncommitted
            # changes in the project.
            #
            # only invokes the project build script if the project has
            # uncommitted changes.
            #
            # prints paths to built artifacts to stdout.
            build = pkgs.writeShellApplication {
              name = "build";
              meta = devShellConfig.packages.build.meta;
              runtimeInputs = [pkgs.git devShellConfig.packages.build];
              text = ''
                mapfile -t items < <(git status --porcelain -- . | cut -c4-)
                #                                              ^
                #                          get uncommitted files
                #                              that have changed

                if [[ "''${#items[@]}" -gt 0 ]]; then
                  build "''${items[@]}" || (echo "failed to build $(realpath .)" >&2 && exit 1)
                else
                  echo "nothing new to build: no files changed in $(realpath .)" >&2
                fi
              '';
            };
          }
          else throw "devShellConfig ${devShellConfig.name} missing build"
        )
        // (
          if builtins.hasAttr "runTest" devShellConfig.packages
          then {
            # wraps the project runTest script.
            #
            # provides the project runTest script with the list of
            # files that changed in the project, in the current commit.
            #
            # only invokes the project runTest script if the project.
            # changed in the current commit.
            #
            # prints path to test artifacts, such as coverage reports, to stdout.
            runTest = pkgs.writeShellApplication {
              name = "runTest";
              meta = devShellConfig.packages.runTest.meta;
              runtimeInputs = [pkgs.git devShellConfig.packages.runTest];
              text = ''
                mapfile -t items < <(git status --porcelain -- . | cut -c4-)
                #                                              ^
                #                          get uncommitted files
                #                              that have changed

                if [[ "''${#items[@]}" -gt 0 ]]; then
                  test "''${items[@]}" || (echo "failed to test $(realpath .)" >&2 && exit 1)
                else
                  echo "nothing new to test: no files changed in $(realpath .)" >&2
                fi
              '';
            };
          }
          else throw "devShellConfig ${devShellConfig.name} missing runTest"
        )
        // (
          if (builtins.hasAttr "publishDryRun" devShellConfig.packages) && (builtins.hasAttr "publish" devShellConfig.packages)
          then let
            bumpSemVer = pkgs.writeShellApplication {
              name = "bumpSemVer";
              runtimeInputs = [
                self.lintSemVer
                pkgs.git
              ];
              text = ''
                PROJECT="$1"

                if [ -n "$(git status --porcelain -- .)" ]; then
                  echo "uncommitted changes in $(realpath "$PROJECT") . Please commit, stash or discard all changes before running publishDryRun" >&2
                  exit 1
                fi

                SV=""

                if ! SV=$(lintSemVer); then
                  echo "lintSemVer failed" >&2
                  exit 1
                fi

                if [ -z "$SV" ]; then
                  echo "${self.lintSemVer} generated an invalid semver. semver must be \"none\" or <major>.<minor>.<patch>. This is an error in either the .config/devShell.nix or .config/language-*/devShell.nix" >&2
                fi

                MAJOR="0"
                MINOR="0"
                PATCH="0"

                if [[ "$SV" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                  IFS='.' read -ra parts <<< "$SV"
                  MAJOR="''${parts[0]}"
                  MINOR="''${parts[1]}"
                  PATCH="''${parts[2]}"
                fi
                echo "$SV" >&2

                ((PATCH += 1))

                NEW_VERSION="$MAJOR.$MINOR.$PATCH"


                read -r -p "bump semantic version from $SV to $MAJOR.$MINOR.$PATCH? (y/n): " CONFIRM
                if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" || "$CONFIRM" == "yes" || "$CONFIRM" == "Yes" ]]; then
                  NEW_VERSION="$MAJOR.$MINOR.$PATCH"
                else
                  read -r -p "enter semantic version: " NEW_VERSION
                fi

                if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                  echo "expected <major>.<minor>.<patch> received \"$NEW_VERSION\"" >&2
                  exit 1
                fi

                NEW_MAJOR=""
                NEW_MINOR=""
                NEW_PATCH=""

                IFS='.' read -ra parts <<< "$NEW_VERSION"
                NEW_MAJOR="''${parts[0]}"
                NEW_MINOR="''${parts[1]}"
                NEW_PATCH="''${parts[2]}"

                FAIL=""

                if [[ "$NEW_MAJOR" -lt "$MAJOR" ]]; then
                  FAIL="major version of $NEW_VERSION must be greater than or equal to $MAJOR"
                elif [[ "$NEW_MAJOR" -gt "$MAJOR" ]]; then
                  FAIL=""
                elif [[ "$NEW_MINOR" -lt "$MINOR" ]]; then
                  FAIL="minor version of $NEW_VERSION must be greater than or equal to $MINOR"
                elif [[ "$NEW_MINOR" -gt "$MINOR" ]]; then
                  FAIL=""
                elif [[ "$NEW_PATCH" -lt "$PATCH" ]]; then
                  FAIL="patch version of $NEW_VERSION must be greater than or equal to $PATCH"
                fi

                if [ -n "$FAIL" ]; then
                  echo "$FAIL" >&2
                  exit 1
                fi

                echo "$SV $NEW_MAJOR.$NEW_MINOR.$NEW_PATCH"
              '';
            };
            writeChangelog = pkgs.writeShellApplication {
              name = "writeChangelog";
              runtimeInputs = [
                pkgs.git
              ];
              text = ''
                PROJECT="$1"
                SV="$2"
                CHANGELOG=""

                function add_to_changelog(){
                    local sha
                    sha="$1"

                    COMMIT_MSG=$(git log -1 --pretty=format:'%s' "$sha" 2>/dev/null)
                    CHANGELOG="''${CHANGELOG}''${SHA:0:8} ''${COMMIT_MSG}"$'\n'
                }

                while read -r SHA; do
                  while read -r TAG; do
                    if [[ "$TAG" == "$PROJECT/v$SV" ]]; then
                      break 2
                    fi
                  done < <(git describe --tags --exact-match "$SHA" 2>/dev/null)

                  add_to_changelog "$SHA"

                done < <(git rev-list HEAD -- .)

                CONFIRM_CHANGELOG=""

                if [[ "$CHANGELOG" =~ [^[:space:]] ]]; then
                  echo "Generated changelog:" >&2
                  echo "$CHANGELOG" >&2
                  read -r -p "use generated changelog? (y/n): " CONFIRM_CHANGELOG
                fi

                if [[ "$CONFIRM_CHANGELOG" != "y" && "$CONFIRM_CHANGELOG" != "Y" && "$CONFIRM_CHANGELOG" != "yes" && "$CONFIRM_CHANGELOG" != "Yes" ]]; then
                  read -r -p "enter changelog: " CHANGELOG
                fi

                echo "$CHANGELOG"
              '';
            };
          in {
            # wraps the project publishDryRun script.
            #
            # errors if HEAD contains uncommitted changes.
            #
            # invokes the project lintSemVer script.
            #
            # only invokes the project publishDryRun script if the
            # project lintSemVer script exits 0.
            #
            # prompts the user to bump the semantic version of the
            # project, and provide a changelog.
            #
            # defaults to incrementing the patch version of the
            # project and printing a table of all commit hashes and
            # messages between the last semver bump and the current
            # commit as the changelog.
            #
            # provides the current and bumped semantic version, and
            # changelog message to the project publishDryRun script.
            #
            # after the project publish script runs, prints what
            # would happen if the publish script was run to stderr.
            #
            # prints nothing to stdout.
            publishDryRun = pkgs.writeShellApplication {
              name = "publishDryRun";
              meta = devShellConfig.packages.publishDryRun.meta;
              runtimeInputs = [
                pkgs.git
                bumpSemVer
                writeChangelog
                devShellConfig.packages.publishDryRun
              ];
              text = ''
                PROJECT="$(git rev-parse --show-prefix)"
                PROJECT="''${PROJECT%?}"

                read -r SV NEW_SV <<< "$(bumpSemVer "$PROJECT")"
                CHANGELOG="$(writeChangelog "$PROJECT" "$SV")"

                publishDryRun "$SV" "$NEW_SV" "$CHANGELOG"

                glow <<-EOF >&2
                Publish would create the following commit, and tag it as \`$PROJECT/v$NEW_SV\`:

                Commit message
                > chore: bump "$PROJECT" to "$NEW_SV"
                >
                > $CHANGELOG
                EOF
              '';
            };
            # wraps the project publish script.
            #
            # errors if HEAD contains uncommitted changes.
            #
            # invokes the project lintSemVer script.
            #
            # only invokes the project publish script if the project
            # lintSemVer script exits 0.
            #
            # prompts the user to bump the semantic version of the
            # project, and provide a changelog.
            #
            # defaults to incrementing the patch version of the
            # project and printing a table of all commit hashes and
            # messages between the last semver bump and the current
            # commit as the changelog.
            #
            # provides the current and bumped semantic version, and
            # changelog message to the project publish script.
            #
            # after the project publish script runs, commits changes
            # to the project with the following commit message:
            #
            # ```
            #   chore: bump <project>/.v<major>.<minor>.<patch>
            #
            #   changelog
            # ```
            #
            # prints the new semantic version to stdout.
            publish = pkgs.writeShellApplication {
              name = "publish";
              meta = devShellConfig.packages.publish.meta;
              runtimeInputs = [
                bumpSemVer
                writeChangelog
                pkgs.git
                pkgs.gnupg
                devShellConfig.packages.publish
              ];
              text = ''
                PROJECT="$(git rev-parse --show-prefix)"
                PROJECT="''${PROJECT%?}"

                read -r SV NEW_SV <<< "$(bumpSemVer "$PROJECT")"
                CHANGELOG="$(writeChangelog "$PROJECT" "$SV")"

                publish "$SV" "$NEW_SV" "$CHANGELOG"

                git add -A
                git commit -m "chore: bump \"$PROJECT\" to \"$NEW_SV\"" -m "$CHANGELOG"
                # Create signed tag (GPG required)
                git tag -s "$PROJECT/v$NEW_SV" -m "chore: bump \"$PROJECT\" to \"$NEW_SV\"" -m "$CHANGELOG"

                glow <<-EOF >&2
                created the following commit, and tagged it as \`$PROJECT/v$NEW_SV\`:

                Commit message
                > chore: bump "$PROJECT" to "$NEW_SV"
                >
                > $CHANGELOG
                EOF
              '';
            };
          }
          else throw "devShellConfig ${devShellConfig.name} missing publishDryRun and publish"
        )
    );
  commands = pkgList:
    builtins.concatLists (
      map (
        p:
          map (dirent: {
            name = dirent.name;
            description = p.meta.description;
          }) (builtins.filter (dirent: dirent.value != "directory") (pkgs.lib.attrsToList (builtins.readDir "${p}/bin")))
      )
      pkgList
    );
  makeDevShell = devShellConfig: pkgs:
    pkgs.mkShell {
      packages = with pkgs;
        [
          coreutils
          glow
        ]
        ++ builtins.attrValues (wrappedPackages devShellConfig);
      shellHook =
        devShellConfig.shellHook
        + ''
          glow <<-'EOF' >&2
          | command | description |
          |:--------|:------------|
          ${builtins.concatStringsSep "\n" (builtins.map (command: "| ${command.name} | ${command.description} |") (commands (builtins.attrValues (wrappedPackages devShellConfig))))}
          EOF
        '';
    };
  devShells =
    (builtins.listToAttrs (
      map (config: {
        name = config.name;
        value = makeDevShell config pkgs;
      })
      validDevShellConfigs
    ))
    // {
      default = let
        p =
          [
            (import
              ./configVscode.nix
              {inherit pkgs;})
            (import
              ./configZed.nix
              {inherit pkgs;})
            (import
              ./installGitHooks.nix
              {inherit pkgs;})
          ]
          ++ (import ./stubProject.nix {inherit pkgs;});
      in
        pkgs.mkShell {
          packages = [pkgs.glow] ++ p;
          shellHook = ''
            installVscodeConfiguration
            installZedConfiguration
            installGitHooks

            glow <<-'EOF' >&2
            | command | description |
            |:--------|:------------|
            ${builtins.concatStringsSep "\n" (builtins.map (command: "| ${command.name} | ${command.description} |") (commands p))}
            EOF
          '';
        };
    };
in
  #
  # LANGUAGE-SPECIFIC DEVELOPMENT SHELLS
  #
  # This flake builds specialized development shells using nix expressions in .config/language-*/ folders:
  #
  # projects/
  #   |-- flake.nix                  <- imports devShell.nix files
  #   :
  #   |
  #   '-- .config/
  #       |-- nix/
  #       |   |
  #       |   '-- devShell.nix
  #       |
  #       |-- go/
  #       |   |
  #       |   '-- devShell.nix
  #       |
  #       '-- typescript/
  #           |
  #           '-- devShell.nix
  #
  #
  # Each project references one of these
  # dev shells in its .envrc
  #
  # projects/
  #   |-- flake.nix
  #   |
  #   |-- go-starter/
  #   |   |
  #   |   '-- .envrc                 <- uses devShells.go
  #   |
  #   |-- typescript-starter/
  #   |   |
  #   |   '-- .envrc                 <- uses devShells.typescript
  #   |
  #   '-- .config/
  #       |
  #       |-- nix/
  #       |   |
  #       |   '-- devShell.nix
  #       |
  #       |-- go/
  #       |   |
  #       |   '-- devShell.nix
  #       |
  #       '-- typescript/
  #           |
  #           '-- devShell.nix
  #
  # For more details: .config/CONTRIBUTE.md
  # See also: CONTRIBUTE.md#develop
  #
  devShells
