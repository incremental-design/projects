{pkgs ? import <nixpkgs> {}}: let
  manifests =
    map (
      dirent: {
        name = pkgs.lib.replaceStrings ["_"] ["."] (builtins.head (builtins.match "^parse-manifest-(.*)\.nix$" dirent.name));
        value = import ./${dirent.name} {inherit pkgs;};
      }
    ) (
      import ./match-dirent.nix {
        inherit pkgs;
        from = ./.;
        matchDirentName = name: (builtins.match "^parse-manifest-.*\.nix$" name) != null;
        matchDirentType = type: (builtins.match "regular" type) != null;
      }
    );
  manifestNames = builtins.concatStringsSep ", " (map (m: m.name) manifests);
  manifestsForCmd = cmdName: builtins.filter (manifest: builtins.elem cmdName (map (bins: bins.name) manifest.value)) manifests;
  getCmd = cmdName: manifestValue: "${builtins.head (builtins.filter (shellApplication: shellApplication.name == cmdName) manifestValue)}/bin/${cmdName}";
  wrap = cmdName:
    pkgs.writeShellApplication {
      name = cmdName;
      meta = {
        description = "detect ${manifestNames} and run the corresponding ${cmdName} for each";
      };
      runtimeInputs = with pkgs; [
        fd
        coreutils
      ];
      text = ''
        CHANGED=0
        ALL=0

        did_change(){
          local dir="$1"

          # Return 0 (true) if any changes found, 1 (false) if none
          if git diff --quiet "$dir" && \
             git diff --cached --quiet "$dir" && \
             git diff --quiet HEAD~1 HEAD -- "$dir"; then
            return 1  # No changes
          else
            return 0  # Has changes
          fi
        }

        # scoop the first --changed and --all flags passed into args
        ARGS=()

        for arg in "$@"; do
        if [[ "$arg" = "--changed" && "$CHANGED" = 0 ]]; then
            CHANGED=1
        elif [[ "$arg" = "--all" && "$ALL" = 0 ]]; then
            ALL=1
        else
            ARGS+=("$arg")
        fi
        done

        if (( CHANGED == 1 && ALL == 1 )); then
        echo "cannot submit both --changed and --all, as --changed runs ${cmdName} on only ${manifestNames} that have changed between staging area and the commit directly prior to HEAD in ''${PWD} and its subdirectories, while --all runs ${cmdName} on all ${manifestNames} Ωin ''${PWD} and its subdirectories" >&2
        exit 1
        fi

        if (( CHANGED == 0 && ALL == 0)); then
        ALL=1
        fi

        run_cmd(){
            local cmdPath="$1"
            local manifestName="$2"
            local returnCode=0
            local manifestPath=""
            local d=""

            mapfile -t all_manifests < <(fd -t f -H -F "$manifestName")

            # iterate over manifests from subdirs all the way back up to PWD
            for (( i = "''${#all_manifests[@]}" - 1; i >= 0; i-- )); do
                manifestPath=$(realpath "''${all_manifests[$i]}")
                d=$(dirname "$manifestPath")

                if (( ALL==1 )) || did_change "$d"; then
                    cd "$d"
                    "$cmdPath" "''${ARGS[@]}" || returnCode=1
                fi

                if (( returnCode == 1)); then
                    echo "${cmdName} failed at $manifestPath" >&2
                    return 1
                fi
            done
        }

        WORKDIR="$PWD"
        EXIT_CODE=1

        ${
          builtins.concatStringsSep " && \\\n" ((
              map (manifest: ''run_cmd "${getCmd cmdName manifest.value}" "${manifest.name}" "$@"'') (manifestsForCmd cmdName)
            )
            ++ ["EXIT_CODE=0"])
        }

        cd "$WORKDIR"

        exit "$EXIT_CODE"
      '';
    };
  bins = builtins.concatMap (manifest:
    builtins.filter (derivation:
      derivation.name
      != "project-lint"
      && derivation.name != "project-lint-semver"
      && derivation.name != "project-build"
      && derivation.name != "project-test")
    manifest.value)
  manifests;
  uniqueBins = let
    binNames = map (bin: bin.name) bins;
    uniqueBinNames = pkgs.lib.unique binNames;
  in
    if builtins.length binNames == builtins.length uniqueBinNames
    then bins
    else throw "Duplicate binaries found in ${manifestNames}: ${binNames}";
  project-lint = wrap "project-lint";
  project-lint-semver = wrap "project-lint-semver";
  project-build = wrap "project-build";
  project-test = wrap "project-test";
  stubProjects = import ./stub-project.nix {inherit pkgs;};
  default = pkgs.mkShell {
    packages =
      [
        pkgs.glow
        pkgs.git
        (import ./config-vscode.nix {inherit pkgs;})
        (import ./config-zed.nix {inherit pkgs;})
        (import ./stub-project.nix {inherit pkgs;})
        (import ./install-git-hooks.nix {inherit pkgs;})
        project-lint
        project-lint-semver
        project-build
        project-test
      ]
      ++ uniqueBins ++ stubProjects;
    shellHook = ''
      # vscode config, zed config, git hooks have to be run in monorepo root
      WORKDIR="$PWD"
      cd $(git rev-parse --path-format=relative --show-toplevel)

      project-install-vscode-configuration
      project-install-zed-configuration
      project-install-git-hooks

      cd "$WORKDIR"

      glow <<-'EOF' >&2
        # project-lint
        recurse through the working directory and subdirectories, linting all projects that have a ${builtins.concatStringsSep ", " (map (manifest: manifest.name) (manifestsForCmd "project-lint"))}

        - use flag --changed to skip projects that have not changed in the latest commit

        # project-lint-semver
        recurse through the working directory and subdirectories, validating the semantic version of projects that have a ${builtins.concatStringsSep ", " (map (manifest: manifest.name) (manifestsForCmd "project-lint-semver"))}

        - use flag --changed to skip projects that have not changed in the latest commit

        # project-build
        recurse through the working directory and subdirectories, building projects that have a ${builtins.concatStringsSep ", " (map (manifest: manifest.name) (manifestsForCmd "project-build"))}

        - use flag --changed to skip projects that have not changed in the latest commit

        # project-test
        recurse through the working directory and subdirectories, testing projects that have a ${builtins.concatStringsSep ", " (map (manifest: manifest.name) (manifestsForCmd "project-test"))}

        - use flag --changed to skip projects that have not changed in the latest commit

        # project-install-vscode-configuration
        symlink the .vscode configuration folder into the root of this repository. Automatically run when this shell starts

        # project-install-zed-configuration
        symlink the .zed configuration folder into the root ofthis repository. Automatically run when this shell starts

        ${builtins.concatStringsSep ''

        '' (
          (map (bin:
            ''
              # ${bin.name}
            ''
            + (
              if builtins.hasAttr "meta" bin
              then
                if builtins.hasAttr "description" bin.meta
                then bin.meta.description
                else ''''
              else ''''
            ))
          uniqueBins)
          ++ (map (p: ''
              # ${p.name}
              ${p.meta.description}
            '')
            stubProjects)
        )}
      EOF
    '';
  };
in {inherit project-lint project-lint-semver project-build project-test default;}
#
# The DEVELOPMENT SHELL
#
# when you `nix develop`, or install `nix-direnv` and `cd` into this repo, this dev shell activates
#
# This dev shell not only installs all of the development tools, it also manages the tool versions
# for you. You don't need node version manager, asdf, python virtual environments, etc. Just `cd`
# into the folder of your choice, and develop.
#
#
# HOW THE DEVELOPMENT SHELL WORKS
#
# The development shell patches the $PATH with scripts that intercept calls to dev tools. e.g.
#
#
#        `go run main.go`       _______
#       '-,--------------'     / parse-manifest-go_mod.nix
#         |                    |       |
#         '----- points to ---->       +-----------,
#                              |_______|           |
#                                  ^            passes go
#                                  |            version,
#                               reads go        command to
#                               version            |
#              .---._____        from           ___|___
#              | workdir |         |           / tool.nix
#              |         |      ___|___        |       |
#              '____,____'     / go.mod|       |       |
#                   |          |       |       |___,___|
#                   '---------->       |           |
#                              |_______|           |
#                                               selects
#                                             matching go
#                                            version from
#                                                  |
#                              .---._____          |
#                              | .config |         |
#                              |         |      ___|___
#                              '____,____'     /  _______
#                                   |          | /  _______
#                                   '----------> | /  tool-go_v<MAJOR.MINOR.PATCH>.nix
#                                              | | |       |
#                                                | |       |
#                                                  |___,___|
#                                                      |
#                                                      |
#                                             runs original command
#
# The development shell detects manifest files in the working directory, and uses them
# to determine which _version_ of a dev tool to run. Then, it loads the correct version
# of the dev tool.
#
# The development shell also provides the following helper commands:
#   - `project-lint`
#   - `project-lint-semver`
#   - `project-build`
#   - `project-test`
#
# Each of these commands is recursive: when you run them, the dev shell will traverse
# the working directory, and all subdirectories, running these commands against all
# manifest files that it finds.
#
# e.g.
#
#   if you run `project-lint` in projects/project-B
#
#   projects/
#     |
#     |-- project-A/
#     |    |
#     |    '-- package.json
#     |                                                 _______
#     '-- project-B/                                   / dev-shell.nix
#          |                                           |       |
#          |-- flake.nix <----------,---- detects -----+       |
#          |                        |                  |___,___|
#          |-- go.mod    <----------|                      |
#          |                        |            invokes `project-lint` in
#          '-- project-C/           |                      |
#               |                   |                      |
#               '-- cargo.toml <----'                      |
#                                                          |
#                                                          |      _______
#                                                          |     / parse-manifest-flake_nix.nix
#                                                          |     |       |
#                                                          |-----+       |
#                                                          |     |___,___|
#                                                          |         |
#                                                          |         '---- runs `project-lint`
#                                                          |                       |
#                                                          |                       '-- runs nix-specific format
#                                                          |                           and lint commands
#                                                          |
#                                                          |
#                                                          |      _______
#                                                          |     / parse-manifest-go_mod.nix
#                                                          |     |       |
#                                                          |-----+       |
#                                                          |     |___,___|
#                                                          |         |
#                                                          |         '---- runs `project-lint`
#                                                          |                       |
#                                                          |                       '-- runs go-specific format
#                                                          |                           and lint commands
#                                                          |
#                                                          |      _______
#                                                          |     / parse-manifest-cargo_toml.nix
#                                                          |     |       |
#                                                          '-----+       |
#                                                                |___,___|
#                                                                    |
#                                                                    '---- runs `project-lint`
#                                                                                  |
#                                                                                  '-- runs rust-specific format
#                                                                                      and lint commands
#
# WHY IS THE DEVELOPMENT SHELL SET UP THIS WAY?
#
# The development shell provides ONE $PATH and development environment for
# all projects. This makes it trivial to nest projects in one another, and
# to share project folders between multiple manifests.
#
#
# HOW DO I ADD SUPPORT FOR ANOTHER MANIFEST FILE?
#
# create a parse-manifest-<basename>_<ext>.nix
#   e.g. pyproject.toml -> parse-manifest-pyproject_toml.nix,
#
# The file must contain the following:
#
# ```
# {
#   pkgs ? import <nixpkgs> {},
#   tool ? import ./tool.nix {inherit pkgs;},                     # optionally import the tool script, which selects the correct tool version for a flake.nix
#   ...
# }: let
#   paths = [                                                     # list of scripts and binaries to load into PATH. these must all take the form  of (pkgs.writeShellApplication {...})
#     (pkgs.writeShellApplication                                 # The parentheses () around pkgs.writeShellApplication is REALLY important. It tells nix to turn the pkgs.writeShellApplication into a derivation before adding it to list of paths
#       {
#         name = "project-lint";                                  # OPTIONAL command to run when project-lint is called in directories containing this manifest
#         meta = {
#           description = "...";                                  # description of what lint commands will be run when project-lint is called on directories containing this manifest file
#         };
#         runtimeInputs = [...];                                  # bins needed to run lint commands
#         text = ''
#           ...                                                   # the lint commands
#         '';
#       }
#     )
#     (pkgs.writeShellApplication
#       {
#         name = "project-lint-semver";                           # OPTIONAL command to run when project-lint-semver is called in directories containing this manifest
#         meta = {
#           description = "...";                                  # description of what lint-semver commands will be run when project-lint-semver is called on directories containing this manifest file
#         };
#         runtimeInputs = [...];                                  # bins needed to run lint-semver commands
#         text = ''
#           ...                                                   # the lint-semver commands
#         '';
#       }
#     )
#     (pkgs.writeShellApplication
#       {
#         name = "project-build";                                 # OPTIONAL command to run when project-build is called in directories containing this manifest
#         meta = {
#           description = "...";                                  # description of what build commands will be run when project-build is called on directories containing this manifest file
#         };
#         runtimeInputs = [...];                                  # bins needed to run build commands
#         text = ''
#           ...                                                   # the build commands
#         '';
#       }
#     )
#     (pkgs.writeShellApplication
#       {
#         name = "project-test";                                  # OPTIONAL command to run when project-test is called in directories containing this manifest
#         meta = {
#           description = "...";                                  # description of what build commands will be run when project-test is called on directories containing this manifest file
#         };
#         runtimeInputs = [...];                                  # bins needed to run test commands
#         text = ''
#           ...                                                   # the test commands
#         '';
#       }
#     )
#     (pkgs.writeShellApplication
#       {
#         name = "...";                                           # name of bin used in other tools. e.g. `python`, `cargo` etc.
#         meta = {
#           description = "...";                                  # description of the bin
#         };
#         runtimeInputs = [...];                                  # bin that is being aliased
#         text = ''
#           ...                                                   # commands used to READ the project manifest, detect if a specific version of the command is required, and then select that
#         '';                                                     # version, using the tool.nix script
#       }
#     )
#   ]
# in
#   paths
# ```
#
# see parse-manifest-flake_nix.nix for an example

