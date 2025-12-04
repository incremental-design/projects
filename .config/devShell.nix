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
        getChangedAtSha = pkgs.writeShellApplication {
          name = "getChangedAtSha";
          runtimeInputs = [pkgs.git];
          text = ''
            SHA="''${1:-}"

            FILES=""

            if [ -z "$SHA" ]; then
              # Get uncommitted files in current directory
              while IFS= read -r file; do
                if [ -n "$FILES" ]; then
                  FILES="$FILES"$'\n'"$(realpath "$file")"
                else
                  FILES="$(realpath "$file")"
                fi
              done < <(git diff HEAD --name-only --relative -- .)
            else
              # Get committed files in current directory at SHA
              while IFS= read -r file; do
                if [ -n "$FILES" ]; then
                  FILES="$FILES"$'\n'"$(realpath "$file")"
                else
                  FILES="$(realpath "$file")"
                fi
              done < <(git diff-tree -r --name-only --relative "$SHA" -- .)
            fi

            echo "$FILES"
          '';
        };
        getAllAtSha = pkgs.writeShellApplication {
          name = "getAllAtSha";
          runtimeInputs = [pkgs.git pkgs.fd];
          text = ''
            FILES=""

            # Get all files in current directory recursively
            while IFS= read -r file; do
              if [ -n "$FILES" ]; then
                FILES="$FILES"$'\n'"$(realpath "$file")"
              else
                FILES="$(realpath "$file")"
              fi
            done < <(fd . --type f)

            echo "$FILES"
          '';
        };
      in
        packages
        // (
          if builtins.hasAttr "project-lint" packages
          then {
            # wraps project-lint script, which checks for syntax errors
            # in the current project.
            #
            # if a commit hash is passed into this script as $1, it provides
            # the project-lint script with the list of files that changed
            # in the project, at the commit.
            #
            # else, it provides the project-lint script with the list of
            # uncommitted changes to the project.
            #
            # only invokes the project-lint script if the project has
            # uncommitted changes.
            project-lint = pkgs.writeShellApplication {
              name = "project-lint";
              meta = packages.project-lint.meta;
              runtimeInputs = [pkgs.git packages.project-lint getChangedAtSha getAllAtSha];
              text = ''
                IGNORE_UNCHANGED="''${1:-false}"
                SHA="''${2:-}"

                FILES=""
                if [ "$IGNORE_UNCHANGED" = "true" ]; then
                    FILES=$(getChangedAtSha "$SHA")
                else
                    FILES=$(getAllAtSha)
                fi

                if [ -n "$FILES" ]; then
                  project-lint "$FILES" || (echo "failed to lint $(realpath .)" >&2 && exit 1)
                else
                  echo "nothing new to lint: no files changed in $(realpath .)" >&2
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
            # provides the project build script with a list of filest.
            #
            # only invokes the project build script if the project has
            # uncommitted changes.
            #
            # prints paths to built artifacts to stdout.
            project-build = pkgs.writeShellApplication {
              name = "project-build";
              meta = packages.project-build.meta;
              runtimeInputs = [pkgs.git packages.project-build getChangedAtSha getAllAtSha];
              text = ''
                IGNORE_UNCHANGED="''${1:-false}"
                SHA="''${2:-}"

                FILES=""
                if [ "$IGNORE_UNCHANGED" = "true" ]; then
                    FILES=$(getChangedAtSha "$SHA")
                else
                    FILES=$(getAllAtSha)
                fi

                if [ -n "$FILES" ]; then
                  project-build "$FILES" || (echo "failed to build $(realpath .)" >&2 && exit 1)
                else
                  echo "nothing new to build: no files changed in $(realpath .)" >&2
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
            # if a commit hash is passed into this script as $1, it provides
            # the project test script with the list of files that changed
            # in the project, at the commit.
            #
            # else, it provides the project test script with the list of
            # uncommitted changes to the project.
            #
            # does not invoke the project test script if nothing has changed.
            #
            # prints path to test artifacts, such as coverage reports, to stdout.
            project-test = pkgs.writeShellApplication {
              name = "project-test";
              meta = packages.project-test.meta;
              runtimeInputs = [pkgs.git packages.project-test getChangedAtSha getAllAtSha];
              text = ''
                IGNORE_UNCHANGED="''${1:-false}"
                SHA="''${2:-}"

                FILES=""

                if [ "$IGNORE_UNCHANGED" = "true" ]; then
                    FILES=$(getChangedAtSha "$SHA")
                else
                    FILES=$(getAllAtSha)
                fi

                if [ -n "$FILES" ]; then
                  project-test "$FILES" || (echo "failed to test $(realpath .)" >&2 && exit 1)
                else
                  echo "nothing new to test: no files changed in $(realpath .)" >&2
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
                    ignoreUnchanged = false;
                    cleanup = true;
                  })
              ];
              text = ''
                recurse
              '';
            }) ["project-lint" "project-build" "project-test"];
        commandDescriptions = writeCommandDescriptions p;
      in
        pkgs.mkShell {
          packages = [pkgs.glow pkgs.git] ++ p;
          shellHook = ''
            project-install-vscode-configuration
            project-install-zed-configuration
            ${pkgs.glow}/bin/glow <<-'EOF' >&2
            ${builtins.concatStringsSep "\n" commandDescriptions}
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
