{
  pkgs ? import <nixpkgs> {},
  vscodeConfigs ? (import ./importFromLanguageFolder.nix {inherit pkgs;}).importConfigVscode,
}: let
  validVscodeConfigs = builtins.map (vsc:
    if
      (builtins.isAttrs vsc)
      && (builtins.hasAttr "vscodeSettings" vsc)
      && (builtins.hasAttr "vscodeExtensions" vsc)
      && (builtins.hasAttr "vscodeLaunch" vsc)
      && (builtins.hasAttr "vscodeTasks" vsc)
    then vsc
    else builtins.throw "Invalid vscode configuration ${vsc}")
  vscodeConfigs;
  # VSCODE CONFIGURATION FILE GENERATION
  #
  # This script creates VSCode configuration files by merging
  # language-specific configurations from child directories:
  #
  #   Generated Files              Language Sources
  #  ____________________          ____________________
  # /                    |        /                    |
  # | settings.json      |   <--- | nix/configVscode   |
  # | extensions.json    |        | go/configVscode    |
  # | launch.json        |        | ts/configVscode    |
  # | tasks.json         |        | etc...             |
  # |____________________|        |____________________|
  #           |                             |
  #           v                             v
  #   ___________________          .config/ hierarchy:
  #  /                   |
  #  | .vscode/          |         .config/
  #  |  settings.json    |           |-- configVscode.nix  <- merges all
  #  |  extensions.json  |           |-- nix/
  #  |  launch.json      |           |   '-- configVscode.nix
  #  |  tasks.json       |           |-- go/
  #  |___________________|           |   '-- configVscode.nix
  #                                  '-- typescript/
  #                                      '-- configVscode.nix
  #
  # Each generated file contains merged settings from all languages.
  # See VSCode documentation:
  # • settings.json: https://code.visualstudio.com/docs/getstarted/settings
  # • extensions.json: https://code.visualstudio.com/docs/editor/extension-marketplace#_workspace-recommended-extensions
  # • launch.json: https://code.visualstudio.com/docs/editor/debugging#_launch-configurations
  # • tasks.json: https://code.visualstudio.com/docs/editor/tasks
  #
  # For more details on the language subfolder architecture:
  # See: .config/CONTRIBUTE.md
  #
  jsonFormatter = pkgs.formats.json {};
  vscodeSettings = jsonFormatter.generate "settings.json" (
    pkgs.lib.lists.fold (set: acc: pkgs.lib.attrsets.recursiveUpdate acc set) {} (builtins.map (vsc: vsc.vscodeSettings) validVscodeConfigs)
  );
  vscodeExtensions = jsonFormatter.generate "extensions.json" (
    pkgs.lib.lists.fold (set: acc: pkgs.lib.attrsets.recursiveUpdate acc set) {} (builtins.map (vsc: vsc.vscodeExtensions) validVscodeConfigs)
  );
  vscodeLaunch = jsonFormatter.generate "launch.json" (
    pkgs.lib.lists.fold (set: acc: pkgs.lib.attrsets.recursiveUpdate acc set) {} (builtins.map (vsc: vsc.vscodeLaunch) validVscodeConfigs)
  );
  vscodeTasks = jsonFormatter.generate "tasks.json" (
    pkgs.lib.lists.fold (set: acc: pkgs.lib.attrsets.recursiveUpdate acc set) {} (builtins.map (vsc: vsc.vscodeTasks) validVscodeConfigs)
  );
  vscodeConfiguration = pkgs.stdenv.mkDerivation {
    name = "vscodeConfiguration";
    src = null;
    phases = [
      "buildPhase"
    ];
    buildPhase = ''
      mkdir -p $out
      cd $out

      ln -s ${vscodeSettings} settings.json
      ln -s ${vscodeExtensions} extensions.json
      ln -s ${vscodeLaunch} launch.json
      ln -s ${vscodeTasks} tasks.json
    '';
  };
  installVscodeConfiguration = pkgs.writeShellApplication {
    name = "installVscodeConfiguration";
    meta = {
      description = "install .vscode/ configuration folder, if .vscode/ is not already present. Automatically run when this shell is opened.";
    };
    runtimeInputs = [pkgs.coreutils];
    text = ''
      if [ ! -d "./.git" ]; then
          echo "please run this script from the root of the monorepo" >&2 && exit 1
      fi

      VSCODE_DIR=$(readlink -f "./.vscode")

      if [ ! -e "./.vscode" ]; then
          ln -s ${vscodeConfiguration} "./.vscode"
          echo "✅ linked ${vscodeConfiguration} to ./.vscode" >&2
          exit 0
      fi

      if [ "$VSCODE_DIR" = ${vscodeConfiguration} ]; then
          echo "✅ vscode configuration already linked" >&2
          exit 0
      fi

      if [ "$(dirname "$VSCODE_DIR")" = "$(dirname ${vscodeConfiguration})" ]; then
          unlink "./.vscode"
          ln -s ${vscodeConfiguration} "./.vscode"
          echo "✅ vscode configuration updated" >&2
          exit 0
      fi

      LINK_INSTEAD=$(basename ${vscodeConfiguration})

      ln -s ${vscodeConfiguration} "./$LINK_INSTEAD"

      echo "❌ cannot link vscode configuration because ./.vscode directory already exists." >&2
      echo "  Linking ${vscodeConfiguration} to ./$LINK_INSTEAD instead" >&2
      echo "  Please merge this configuration with your ./.vscode folder" >&2
    '';
  };
in
  installVscodeConfiguration
