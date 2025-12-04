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
    pkgs.lib.fix (let
      packages = builtins.listToAttrs (
        builtins.map (package: {
          name = package.name;
          value = package;
        })
        devShellConfig.packages
      );
      name = devShellConfig.name;
    in (self:
      packages
      // (
        if builtins.hasAttr "project-lint" packages
        then {
          project-lint = pkgs.writeShellApplication {
            name = "project-lint";
            meta = packages.project-lint.meta;
            text = ''
              ${packages.project-lint}/bin/project-lint
            '';
          };
        }
        else throw "devShellConfig ${name} missing project-lint"
      )
      // (
        if builtins.hasAttr "project-lint-semver" packages
        then {
          project-lint-semver = pkgs.writeShellApplication {
            name = "project-lint-semver";
            meta = packages.project-lint-semver.meta;
            text = ''
              ${packages.project-lint-semver}/bin/project-lint-semver
            '';
          };
        }
        else throw "devShellConfig ${name} missing project-lint-semver"
      )
      // (
        if builtins.hasAttr "project-build" packages
        then {
          project-build = pkgs.writeShellApplication {
            name = "project-build";
            meta = packages.project-build.meta;
            text = ''
              ${packages.project-build}/bin/project-build
            '';
          };
        }
        else throw "devShellConfig ${name} missing project-build"
      )
      // (
        if builtins.hasAttr "project-test" packages
        then {
          project-test = pkgs.writeShellApplication {
            name = "project-test";
            meta = packages.project-test.meta;
            # todo pass a list of files that changed in current commit
            text = ''
              ${packages.project-test}/bin/project-test
            '';
          };
        }
        else throw "devShellConfig ${name} missing project-test"
      )
      // (
        if builtins.hasAttr "project-publish-dry-run" packages
        then {
          project-publish-dry-run = pkgs.writeShellApplication {
            name = "project-publish-dry-run";
            meta = packages.project-publish-dry-run.meta;
            # todo pass a list of files that changed in current commit
            text = ''
              ${packages.project-publish-dry-run}/bin/project-publish-dry-run
            '';
          };
        }
        else throw "devShellConfig ${name} missing project-publish-dry-run"
      )
      // (
        if builtins.hasAttr "project-publish" packages
        then {
          project-publish = pkgs.writeShellApplication {
            name = "project-publish";
            meta = packages.project-publish.meta;
            # todo pass a list of files that changed in current commit
            text = ''
              ${packages.project-publish}/bin/project-publish
            '';
          };
        }
        else throw "devShellConfig ${name} missing project-publish"
      )));

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
          # read the packages in devShellConfig, get the lint, lintSemVer, build, runTest, publishDryRun and publish packages and wrap them before re-emitting them into the list of packages
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
        p = [];
        commandDescriptions = writeCommandDescriptions p;
      in
        pkgs.mkShell {
          packages = [pkgs.glow pkgs.git] ++ p;
          shellHook = ''
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
