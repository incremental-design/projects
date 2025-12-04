{
  pkgs ? import <nixpkgs> {},
  devShellConfigs ? (import ./importFromLanguageFolder.nix {inherit pkgs;}).importDevShell,
}: let
  validateConfigAttrs = c:
    if !builtins.hasAttr "name" c
    then throw "invalid config, missing name: ${c}"
    else if !builtins.hasAttr "packages" c
    then throw "invalid config, missing packages: ${c}"
    else if !builtins.hasAttr "shellHook" c
    then throw "invalid config, missing shellHook: ${c}"
    else true;
  validatePackage = p:
    if !builtins.isAttrs p
    then throw "invalid package, not an attrset: ${p}"
    else if !builtins.hasAttr "name" p
    then throw "invalid package, missing name: ${p}"
    else if !builtins.hasAttr "meta" p
    then throw "invalid package ${p.name}, missing meta: ${p}"
    else if !builtins.hasAttr "description" p.meta
    then throw "invalid package ${p.name}, missing description: ${p}"
    else if !builtins.pathExists "${p}/bin"
    then throw "invalid package ${p.name}, missing /bin dir: ${p}"
    else if builtins.readDir "${p}/bin" == {}
    then throw "invalid package ${p.name}, empty /bin dir: ${p}"
    else true;
  validateUniquePackages = packages: let
    packageNames = map (package: package.name) packages;
    grouped = pkgs.lib.groupBy (name: name) packageNames;
    duplicates = builtins.attrNames (pkgs.lib.filterAttrs (name: names: builtins.length names > 1) grouped);
  in
    duplicates == [] || throw "Duplicate package names found: ${toString duplicates}";
  validDevShellConfigs = map (c:
    if
      builtins.isAttrs c
      && validateConfigAttrs c
      && (builtins.all (x: x) (map (package: validatePackage package) c.packages))
      && validateUniquePackages c.packages
    then c
    else builtins.throw "invalid devShellConfig ${c}")
  devShellConfigs;
  wrappedPackages = devShellConfig:
    pkgs.lib.fix (
      self: let
        packages = builtins.listToAttrs (
          builtins.map (package: {
            name = package.name;
            value = package;
          })
          devShellConfig.packages
        );
        name = devShellConfig.name;
        getChanged = pkgs.writeShellApplication {
          name = "getChanged";
          runtimeInputs = [pkgs.git];
          text = ''
            # Get union of files changed in HEAD and uncommitted changes
            # Limited to current working directory

            # Use associative array for deduplication
            declare -A seen_files=()

            # Files changed in HEAD commit
            while IFS= read -r -d "" file; do
              seen_files["$file"]=1
            done < <(git diff --name-only -z HEAD~1 HEAD -- .)

            # Files with uncommitted changes (staged + unstaged)
            while IFS= read -r -d "" file; do
              seen_files["$file"]=1
            done < <(git diff --name-only -z HEAD -- .)

            # Get nested projects (directories with .envrc files)
            declare -A nested_projects
            while IFS= read -r -d "" subdir; do
              nested_projects["$subdir"]=1
            done < <(fd --type f --hidden '.envrc' . --exec printf '%s\0' '{//}')

            # Remove files that are in nested projects
            declare -A filtered_files
            for file in "''${!seen_files[@]}"; do
              file_dir=$(dirname "$file")
              if [[ -z "''${nested_projects["$file_dir"]:-}" ]]; then
                filtered_files["$file"]=1
              fi
            done

            # Output unique filenames with null-byte separation for xargs -0
            printf "%s\0" "''${!filtered_files[@]}"
          '';
        };
        getAll = pkgs.writeShellApplication {
          name = "getAll";
          runtimeInputs = [pkgs.fd];
          text = ''
            # list nested projects
            declare -A nested_projects
            while IFS= read -r -d "" subdir; do
              nested_projects["$subdir"]=1
            done < <(fd --type f --hidden '.envrc' . --exec printf '%s\0' '{//}')

            # Build exclude arguments from nested_projects
            exclude_args=()
            for project in "''${!nested_projects[@]}"; do
              exclude_args+=(--exclude "$project")
            done

            # Associative array to store all files in project
            declare -A files_in_project

            # Get all files excluding nested projects and gitignored files
            while IFS= read -r -d "" file; do
              files_in_project["$file"]=1
            done < <(fd "''${exclude_args[@]}" --type f --hidden --print0 .)

            # Output all collected files with null separator for xargs
            printf "%s\0" "''${!files_in_project[@]}"
          '';
        };
      in
        packages
        // (
          if builtins.hasAttr "project-lint" packages
          then {
            # wraps the project lint script.
            #
            # accepts $1 with "true" or "false", defaults to "false"
            #
            # $1="true":  lint CHANGED files in project. this includes
            #             any uncommitted change
            #
            # $1="false": lint ALL files in project
            #
            # exits 0 if lint succeeds, 1 if it fails
            project-lint = pkgs.writeShellApplication {
              name = "project-lint";
              meta = packages.project-lint.meta;
              runtimeInputs = [pkgs.git pkgs.findutils packages.project-lint getAll getChanged];
              text = ''
                IGNORE_UNCHANGED="''${1:-false}"

                # project lint expects a list of files to lint as arguments
                if [ "$IGNORE_UNCHANGED" = "true" ]; then
                    getChanged | xargs -0 -r project-lint || (echo "failed to lint $(realpath .)" >&2 && exit 1)
                else
                    getAll | xargs -0 -r project-lint || (echo "failed to lint $(realpath .)" >&2 && exit 1)
                fi
              '';
            };
          }
          else throw "devShellConfig ${name} missing project-lint"
        )
        // (
          if builtins.hasAttr "project-build" packages
          then {
            # wraps the project build script.
            #
            # accepts $1 with "true" or "false", defaults to "false"
            #
            # $1="true":  build CHANGED files in project. this includes
            #             any uncommitted change
            #
            # $1="false": build ALL files in project
            #
            # exits 0 if build succeeds, 1 if it fails
            project-build = pkgs.writeShellApplication {
              name = "project-build";
              meta = packages.project-build.meta;
              runtimeInputs = [pkgs.git pkgs.findutils packages.project-build getAll getChanged];
              text = ''
                IGNORE_UNCHANGED="''${1:-false}"

                # project-build expects a list of files to build as arguments
                if [ "$IGNORE_UNCHANGED" = "true" ]; then
                    getChanged | xargs -0 -r project-build || (echo "failed to build $(realpath .)" >&2 && exit 1)
                else
                    getAll | xargs -0 -r project-build || (echo "failed to build $(realpath .)" >&2 && exit 1)
                fi
              '';
            };
          }
          else throw "devShellConfig ${name} missing project-build"
        )
        // (
          if builtins.hasAttr "project-test" packages
          then {
            # wraps the project test script.
            #
            # accepts $1 with "true" or "false", defaults to "false"
            #
            # $1="true":  test CHANGED files in project. this includes
            #             any uncommitted change
            #
            # $1="false": test ALL files in project
            #
            # Does not invoke the project test script if nothing has changed.
            # Prints path to test artifacts, such as coverage reports, to stdout.
            project-test = pkgs.writeShellApplication {
              name = "project-test";
              meta = packages.project-test.meta;
              runtimeInputs = [pkgs.git pkgs.findutils packages.project-test getAll getChanged];
              text = ''
                IGNORE_UNCHANGED="''${1:-false}"

                # project-test expects a list of files to test as arguments
                if [ "$IGNORE_UNCHANGED" = "true" ]; then
                    getChanged | xargs -0 -r project-test || (echo "failed to test $(realpath .)" >&2 && exit 1)
                else
                    getAll | xargs -0 -r project-test || (echo "failed to test $(realpath .)" >&2 && exit 1)
                fi
              '';
            };
          }
          else throw "devShellConfig ${name} missing project-test"
        )
    );
  listBins = package: builtins.map (p: p.name) (builtins.filter (dirent: dirent.value != "directory") (pkgs.lib.attrsToList (builtins.readDir "${package}/bin")));
  hasBins = package: pkgs.lib.pathExists "${package}/bin" && (builtins.length (listBins package) > 0);
  filterPackagesWithBins = packages: builtins.filter (package: hasBins package) packages;
  writeCommandDescription = package:
    (
      if builtins.length (listBins package) == 1
      then ''
        `${package.name}`
      ''
      else ''
        ${builtins.concatStringsSep ", " (builtins.map (bin: "`${bin}`") (listBins package))}
      ''
    )
    + ''
      > ${package.meta.description}

    '';
  writeCommandDescriptions = packages:
    map (package: writeCommandDescription package) (filterPackagesWithBins packages);
  makeDevShell = devShellConfig: pkgs:
    pkgs.mkShell {
      # make the packages available in the dev shell
      packages = with pkgs;
        [coreutils glow]
        ++ builtins.attrValues (
          # read the packages in devShellConfig, get the project-lint, project-build, project-test packages and wrap them before re-emitting them into the list of packages
          wrappedPackages devShellConfig
        );
      shellHook = let
        commandDescriptions = writeCommandDescriptions (builtins.attrValues (wrappedPackages devShellConfig));
      in
        # run any hooks specific to this dev shell
        devShellConfig.shellHook
        # ... and then print the list of available commands with their descriptions
        + ''
          ${pkgs.glow}/bin/glow <<-'EOF' >&2
          ${builtins.concatStringsSep "\n" commandDescriptions}
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
            (import ./configVscode.nix {inherit pkgs;})
            (import ./configZed.nix {inherit pkgs;})
          ]
          ++ (import ./stubProject.nix {inherit pkgs;})
          ++ builtins.map (cmd:
            pkgs.writeShellApplication {
              name = "${cmd}-all";
              meta = {
                description = "${cmd} all projects";
              };
              runtimeInputs = [
                (import
                  ./recurse.nix
                  {
                    inherit pkgs;
                    steps = [cmd];
                  })
              ];
              text = ''
                IGNORE_UNCHANGED="''${1:-"true"}"
                recurse "$IGNORE_UNCHANGED"
              '';
            }) ["project-lint" "project-build" "project-test"];
        commandDescriptions = writeCommandDescriptions p;
      in
        pkgs.mkShell {
          packages = [pkgs.glow pkgs.git] ++ p;
          shellHook = ''
            if [ ! -d .git ]
            then
              echo "no .git/ found, are you in the root of the repository?" >&2
              exit 1
            fi

            project-install-vscode-configuration
            project-install-zed-configuration

            ${pkgs.glow}/bin/glow <<-'EOF' >&2
            ${builtins.concatStringsSep "\n" commandDescriptions}
            EOF
          '';
        };
    };
in {inherit validDevShellConfigs makeDevShell devShells;}
#
# LANGUAGE-SPECIFIC DEVELOPMENT SHELLS
#
# This nix expression builds specialized development shells, one for
# each language-* folder
#
# each project in this monorepo uses exactly ONE dev shell
# i.e.
#
#   nix project ......... nix dev shell
#
#   go project  ......... go dev shell
#
#   typescript            typescript
#   project     ......... dev shell
#
# each dev shell sets up the dev tools you need to
# work in its respective language
#
# projects/
#   |-- flake.nix <---.
#   :                 |
#   |              imports
#   '-- .config/      |
#       |             |
#       |- devShell.nix <-- imports --,
#       |                             |
#       |- importFromLanguageFolder.nix <----------,
#       :                                          |
#       :                                       imports
#       :                                          |
#       |                               -,         |
#       |-- language-nix/                |         |
#       |   |                            |         |
#       |   :                            |         |
#       |   |                            |         |
#       |   '-- devShell.nix             |         |
#       |                                |         |
#       |-- language-go/                 |         |
#       |   |                            +---------'
#       |   :                            |
#       |   |                            |
#       |   '-- devShell.nix             |
#       |                                |
#       '-- language-typescript/         |
#           |                            |
#           '-- devShell.nix             |
#                                       -'
#
# all languages are added to the root flake.nix's development
# shells.
#
# To use a development shell, you can run nix develop ./#<language>
# e.g. `nix develop ./#nix` to load the `language-nix` dev shell or
# `nix develop ./#go` to load the `language-go` dev shell
#
# When you stub a project, using one of the project-stub-*
# commands, the new project includes an .envrc file that
# loads the project's language's dev shell
# i.e.
#
#                            ,---._____
# stub-project-nix   ---->   | project |           _________
#                            |         +------->  / .envrc  |
#                            '_________'          |         |
#                                                 | use     |
#                                                 | ../#nix |
#                                                 |_________|
#
#                            ,---._____
# stub-project-go   ---->    | project |           _________
#                            |         +------->  / .envrc  |
#                            '_________'          |         |
#                                                 | use     |
#                                                 | ../#go  |
#                                                 |_________|
#
#                            ,---._____
# stub-project-     ---->    | project |           _________
# typescript                 |         +------->  / .envrc  |
#                            '_________'          |         |
#                                                 | use     |
#                                                 | ../#typescript
#                                                 |_________|
#
# WHY DEV SHELLS
#
# Project tooling is the catch-22 of learning a new language. You
# need a DEEP understanding of a language in order to set up its
# tooling correctly, but you CAN'T gain a deep understanding of the
# language without first trying it out! Nix dev shells install
# project tooling for you, so you can get straight to learning.
# Every time you use a nix dev shell, you skip over the 3+ weeks
# of work you would have needed to spend to get to "hello world"
#
# Dev shells scale across the projects in the monorepo. All projects
# of a language use the SAME EXACT VERSION and CONFIGURATION of
# the project tools. This eliminates version-mismatch bugs from
# the codebase.
#
# HOW TO SET UP A LANGUAGE-SPECIFIC DEV SHELL
#
# Each language-specific folder contains a devShell.nix. This
# nix file must contain
# the following nix expression
#
# { pkgs ? import <nixpkgs> {}}: let
# devShellConfig = {
#   packages = [
#     (pkgs.writeShellApplication {
#       name = "project-lint";
#       meta = {
#         description = "..."               # description of what gets linted
#       };
#       runtimeInputs = with pkgs; [
#         ...                               # packages used to lint project files
#       ];
#       text = ''
#         for file in "$@"; do              # $@ is the list of files that have
#                                           # changed since previous commit
#         ...                               # command used to lint project files
#         done
#       '';
#     })
#
#     (pkgs.writeShellApplication {
#       name = "project-build";
#       meta = {
#         description = "..."               # description of what gets built
#       };
#       runtimeInputs = with pkgs; [
#         for file in "$@"; do              # $@ is list of files that have changed
#                                           # since previous commit
#         ...                               # packages used to build project files
#         done
#       ];
#       text = ''
#
#         ...                               # command used to build project files
#                                           # command used to print project files
#                                           # to stdout, separated by null bytes
#       '';
#     })
#
#     (pkgs.writeShellApplication {
#       name = "project-test";
#       meta = {
#         description = "..."               # description of what gets tested
#       };
#       runtimeInputs = with pkgs; [
#         ...                               # packages used to test project files
#       ];
#       text = ''
#         ...                               # command used to test project files
#       '';
#     })
#
#     (pkgs.writeShellApplication {
#       name = "project-*";                 # any other project-specific script
#       meta = {                            #
#         description = "..."               # MAKE SURE YOU PREPEND "project-"
#       };                                  # TO THE NAME OF ANY BUILD SCRIPT
#       runtimeInputs = with pkgs; [        # this makes it easy to tab-complete
#         ...                               # all project-* specific commands
#       ];
#       text = ''
#         ...
#       '';
#     })
#     ...                                   # any other packages that need to be
#                                           # available in the dev environment
#   ];
#   shellHook = ''                          # any commands you want to run on
#     ...                                   # entry into the project environment
#   '';                                     # (e.g. dependency installation
#                                           # or cleanup commands)
# }
# in
#   devShellConfig
#
# this devShell.nix composes the contents of the language-specific devShell.nix:
#       ________________________               ________________________
#      / devShell.nix           |             / language-*             |
#     /                         |            /  devShell.nix           |
#     | ----------------------- |            | ----------------------- |
#     | packages                |            | packages                |
#     |   project-lint <------ wrapped by ------ project-lint          |
#     |                         |            |                         |
#     |   project-build  <---- wrapped by ------ project-build         |
#     |                         |            |                         |
#     |   project-test  <----- wrapped by ------ project-test          |
#     |                         |            |                         |
#     |   ... <---- directly imported into ----- ...                   |
#     |                         |            |                         |
#     | shellHook  <----- runs before -------- shellHook               |
#     |_________________________|            |_________________________|
#
#
# Every dev shell provides the following commands:
#
# project-lint
# project-build
# project-test
#
# While the command names do not vary across dev shells, their implementations do.
# These commands provide git hooks and CI a common interface for running project-specific tools.

