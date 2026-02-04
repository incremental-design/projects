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
  project-install-vscode-configuration = pkgs.writeShellApplication {
    name = "project-install-vscode-configuration";
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
  project-install-vscode-configuration
# HOW TO SET UP A LANGUAGE-SPECIFIC VSCODE CONFIGURATION
#
# Each language-specific folder contains a configVscode.nix. This
# nix file must contain the following nix expression:
#
# { pkgs ? import <nixpkgs> {} }: {
#   vscodeSettings = {
#     "some.setting" = true;              # settings merged into settings.json
#     "editor.formatOnSave" = true;       # use exact VSCode setting keys
#     "some.path" = "${pkgs.tool}/bin/t"; # nix store paths are supported
#   };
#   vscodeExtensions = {
#     "recommendations" = [
#       "publisher.extension-id"          # extensions merged into extensions.json
#     ];
#   };
#   vscodeLaunch = {
#     "configurations" = [                # launch configs merged into launch.json
#       {
#         "type" = "node";
#         "request" = "launch";
#         "name" = "Debug Program";
#         "program" = "\${workspaceFolder}/src/main.js";
#       }
#     ];
#   };
#   vscodeTasks = {
#     "tasks" = [                         # tasks merged into tasks.json
#       {
#         "label" = "build";
#         "type" = "shell";
#         "command" = "project-build";
#       }
#     ];
#   };
# }
#
# this configVscode.nix merges the contents of all language-specific configVscode.nix:
#
#      ________________________               ________________________
#     / .vscode/               |             / language-*             |
#    /  settings.json          |            /  configVscode.nix       |
#    | ----------------------- |            | ----------------------- |
#    | {                       |            | vscodeSettings = {      |
#    |   "nix.enable": true,<---- merged ------  "nix.enable" = true; |
#    |   "go.enable": true <---- from all ----   ...                  |
#    |   ...                   |   langs    | };                      |
#    | }                       |            |                         |
#    |_________________________|            | vscodeExtensions = {    |
#                                           |   "recommendations" = [ |
#      ________________________             |     "ext.id"            |
#     / .vscode/               |            |   ];          |         |
#    /  extensions.json        |            | };            |         |
#    | ----------------------- |            |               |         |
#    | {                       |            | vscodeLaunch = { ... }; |
#    |   "recommendations": [  |            |               |         |
#    |     "ext.id" <--------- | -- merged -----------------'         |
#    |   ]                     |            | vscodeTasks = { ... };  |
#    | }                       |            |_________________________|
#    |_________________________|
#
# The merge strategy uses Nix's // operator with recursiveUpdate,
# so later language configs can override earlier ones if keys conflict.
# Each attrset corresponds to a VSCode configuration file:
#
#   vscodeSettings   --> .vscode/settings.json
#   vscodeExtensions --> .vscode/extensions.json
#   vscodeLaunch     --> .vscode/launch.json
#   vscodeTasks      --> .vscode/tasks.json
#
# See VSCode documentation:
# • settings.json: https://code.visualstudio.com/docs/getstarted/settings
# • extensions.json: https://code.visualstudio.com/docs/editor/extension-marketplace#_workspace-recommended-extensions
# • launch.json: https://code.visualstudio.com/docs/editor/debugging#_launch-configurations
# • tasks.json: https://code.visualstudio.com/docs/editor/tasks

