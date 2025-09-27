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
    pkgs.lib.fix (self:
      devShellConfig.packages
      // (
        if builtins.hasAttr "lint" devShellConfig.packages
        then {
          lint = pkgs.writeShellApplication {
            name = "lint";
            meta = devShellConfig.packages.lint.meta;
            # todo pass a list of files that changed in current commit
            text = ''
              ${devShellConfig.packages.lint}/bin/lint
            '';
          };
        }
        else throw "devShellConfig ${devShellConfig.name} missing lint"
      )
      // (
        if builtins.hasAttr "lintSemVer" devShellConfig.packages
        then {
          lintSemVer = pkgs.writeShellApplication {
            name = "lintSemVer";
            meta = devShellConfig.packages.lintSemVer.meta;
            # todo pass a list of files that changed in current commit
            text = ''
              ${devShellConfig.packages.lintSemVer}/bin/lintSemVer
            '';
          };
        }
        else throw "devShellConfig ${devShellConfig.name} missing lintSemVer"
      )
      // (
        if builtins.hasAttr "build" devShellConfig.packages
        then {
          build = pkgs.writeShellApplication {
            name = "build";
            meta = devShellConfig.packages.build.meta;
            # todo pass a list of files that changed in current commit
            text = ''
              ${devShellConfig.packages.build}/bin/build
            '';
          };
        }
        else throw "devShellConfig ${devShellConfig.name} missing build"
      )
      // (
        if builtins.hasAttr "runTest" devShellConfig.packages
        then {
          runTest = pkgs.writeShellApplication {
            name = "runTest";
            meta = devShellConfig.packages.runTest.meta;
            # todo pass a list of files that changed in current commit
            text = ''
              ${devShellConfig.packages.runTest}/bin/runTest
            '';
          };
        }
        else throw "devShellConfig ${devShellConfig.name} missing runTest"
      )
      // (
        if builtins.hasAttr "publishDryRun" devShellConfig.packages
        then {
          publishDryRun = pkgs.writeShellApplication {
            name = "publishDryRun";
            meta = devShellConfig.packages.publishDryRun.meta;
            # todo pass a list of files that changed in current commit
            text = ''
              ${devShellConfig.packages.publishDryRun}/bin/publishDryRun
            '';
          };
        }
        else throw "devShellConfig ${devShellConfig.name} missing publishDryRun"
      )
      // (
        if builtins.hasAttr "publish" devShellConfig.packages
        then {
          publish = pkgs.writeShellApplication {
            name = "publish";
            meta = devShellConfig.packages.publish.meta;
            # todo pass a list of files that changed in current commit
            text = ''
              ${devShellConfig.packages.publish}/bin/publish
            '';
          };
        }
        else throw "devShellConfig ${devShellConfig.name} missing publish"
      ));
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
      packages = with pkgs; [coreutils glow] ++ builtins.attrValues (wrappedPackages devShellConfig);
      shellHook =
        devShellConfig.shellHook
        + ''
          ${pkgs.glow}/bin/glow <<-'EOF' >&2
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
        p = [];
      in
        pkgs.mkShell {
          packages = [pkgs.glow] ++ p;
          shellHook = ''
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
