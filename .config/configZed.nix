{
  pkgs ? import <nixpkgs> {},
  zedConfigs ? (import ./importFromLanguageFolder.nix {inherit pkgs;}).importConfigZed,
}: let
  validZedConfigs = builtins.map (zc:
    if (builtins.isAttrs zc) && (builtins.hasAttr "zedSettings" zc) && (builtins.hasAttr "zedDebug" zc)
    then zc
    else builtins.throw "invalid zedConfig ${builtins.toJSON zc}")
  zedConfigs;
  jsonFormatter = pkgs.formats.json {};
  zedSettings = jsonFormatter.generate "settings.json" (
    pkgs.lib.lists.fold (set: acc: pkgs.lib.attrsets.recursiveUpdate acc set) {}
    (
      (builtins.map (zc: zc.zedSettings) validZedConfigs)
      ++ [
        {
          # SHELL HOOK MODE (`"load_direnv": "shell_hook"`):
          #
          # Zed scoops the env vars from the $PATH of the builtin terminal
          # direnv automatically loads env vars into the builtin terminal
          # therefore, Zed receives the env vars from direnv
          #
          # ```
          #  ____________              _____________              ____________
          # | .envrc     |            | shell with  |            | Zed Editor |
          # | file in    |            | direnv hook |            |            |
          # | project    +----------->| activated   +----------->|            |
          # | directory  |   reads    |             |  inherits  |            |
          # |____________|            |_____________|    env     |____________|
          #                                  |                        ^
          #                                  |                        |
          #                          modifies shell env         uses env vars to:
          #                                  |                        |
          #                                  v                        |
          #  ____________              _____________              ____+_______
          # | $PATH      |            | environment |            | Language   |
          # | $RUST_SRC  |<-----------+ variables   |            | Servers &  |
          # | $GOPATH    |   exports  | set by      |            | Extensions |
          # | etc...     |            | direnv      |            |____________|
          # |____________|            |_____________|
          # ```
          #
          # When Zed uses the "shell_hook" mode:
          # 1. Zed launches a shell process in your project directory
          # 2. The direnv hook in that shell activates and processes your .envrc
          # 3. Direnv modifies the shell's environment variables
          # 4. Zed inherits these variables from the shell
          # 5. Language servers and extensions use these variables for configuration
          #
          # This approach ensures that Zed sees the same environment that your
          # terminal would see when working in that directory.
          #
          "load_direnv" = "shell_hook";
        }
      ]
    )
  );
  zedDebug = jsonFormatter.generate "debug.json" (builtins.filter (item: item != {}) (builtins.map (zc: zc.zedDebug) validZedConfigs));
  zedConfiguration = pkgs.stdenv.mkDerivation {
    name = "zedConfiguration";
    src = null;
    phases = [
      "buildPhase"
    ];
    buildPhase = ''
      mkdir -p $out
      cd $out

      ln -s ${zedSettings} settings.json
      ln -s ${zedDebug} debug.json
    '';
  };
  project-install-zed-configuration = pkgs.writeShellApplication {
    name = "project-install-zed-configuration";
    meta = {
      description = "install .zed/ configuration folder, if .zed/ is not already present. Automatically run when this shell is opened";
    };
    runtimeInputs = [pkgs.coreutils];
    text = ''
      if [ ! -d "./.git" ]; then
        echo "please run this script from the root of the monorepo" >&2 && exit 1
      fi

      ZED_DIR=$(readlink -f "./.zed")

      if [ ! -e "./.zed" ]; then
        ln -s ${zedConfiguration} "./.zed"
        echo "✅ linked ${zedConfiguration} to ./.zed" >&2
        exit 0
      fi

      if [ "$ZED_DIR" = ${zedConfiguration} ]; then
        echo "✅ zed configuration already linked" >&2
        exit 0
      fi

      if [ "$(dirname "$ZED_DIR")" = "$(dirname ${zedConfiguration})" ]; then
        unlink "./.zed"
        ln -s ${zedConfiguration} "./.zed"
        echo "✅ zed configuration updated" >&2
        exit 0
      fi

      LINK_INSTEAD=$(basename ${zedConfiguration})

      ln -s ${zedConfiguration} "./$LINK_INSTEAD"

      echo "❌ cannot link zed configuration because ./.zed directory already exists." >&2
      echo "  Linking ${zedConfiguration} to ./$LINK_INSTEAD instead" >&2
      echo "  Please merge this configuration with your ./.zed folder" >&2
    '';
  };
in
  project-install-zed-configuration
# HOW TO SET UP A LANGUAGE-SPECIFIC ZED CONFIGURATION
#
# Each language-specific folder contains a configZed.nix. This
# nix file must contain the following nix expression:
#
# { pkgs ? import <nixpkgs> {} }: {
#   zedSettings = {
#     "auto_install_extensions" = {        # auto-install language extensions
#       "LanguageName" = true;
#     };
#     "languages" = {
#       "LanguageName" = {
#         "language_servers" = [           # configure language servers
#           "server-name"
#         ];
#         "formatter" = {                  # configure formatter
#           "external" = {
#             "command" = "${pkgs.tool}/bin/fmt";
#             "arguments" = ["--flag"];
#           };
#         };
#       };
#     };
#     "lsp" = {
#       "server-name" = {                  # LSP binary configuration
#         "binary" = {
#           "path" = "${pkgs.lsp}/bin/lsp";
#         };
#       };
#     };
#   };
#   zedDebug = {                           # debug adapter configurations
#     "adapter" = "adapter-name";          # merged into debug.json
#     "program" = "${workspaceFolder}/bin";
#   };                                     # use {} if no debugger for language
# }
#
# this configZed.nix merges the contents of all language-specific configZed.nix:
#
#      ________________________               ________________________
#     / .zed/                  |             / language-*             |
#    /  settings.json          |            /  configZed.nix          |
#    | ----------------------- |            | ----------------------- |
#    | {                       |            | zedSettings = {         |
#    |   "languages": {   <------ merged ------  "languages" = {      |
#    |     "Nix": {...},  <---- from all ----      "Nix" = {...};     |
#    |     "Go": {...}         |   langs    |    };                   |
#    |   }                     |            | };                      |
#    | }                       |            |                         |
#    |_________________________|            | zedDebug = {            |
#                                           |   ...         |         |
#      ________________________             | };            |         |
#     / .zed/                  |            |               |         |
#    /  debug.json             |            |_______________|_________|
#    | ----------------------- |                            |
#    | [                       |                            |
#    |   {...} <-------------- | -------- merged -----------'
#    | ]                       |
#    |_________________________|
#
# The merge strategy uses Nix's // operator with recursiveUpdate,
# so later language configs can override earlier ones if keys conflict.
# Each attrset corresponds to a Zed configuration file:
#
#   zedSettings --> .zed/settings.json
#   zedDebug    --> .zed/debug.json
#

