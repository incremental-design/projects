{pkgs ? import <nixpkgs> {}}: let
  tools = builtins.mapAttrs (name: value:
    builtins.sort (
      left: right:
        if left.major < right.major
        then true
        else if left.major > right.major
        then false
        else if left.minor < right.minor
        then true
        else if left.minor > right.minor
        then false
        else if left.patch < right.patch
        then true
        else if left.patch > right.patch
        then false
        else builtins.throw "two versions of ${name} are both ${left.major}.${left.minor}.${left.patch}: \"${left.path}\" \"${right.path}\""
    )
    value) (pkgs.lib.foldl' (
      acc: curr: let
        toolVersion = with curr; {inherit path major minor patch;};
      in
        if builtins.hasAttr curr.tool acc
        then acc // {${curr.tool} = acc.${curr.tool} ++ [toolVersion];}
        else acc // {${curr.tool} = [toolVersion];}
    ) {} (
      map (
        dirent: {
          path = import ./${dirent.name} {inherit pkgs;};
          tool = builtins.head (builtins.match "tool-(.*)_v[0-9]+\.[0-9]+\.[0-9]+\.nix$" dirent.name); # e.g. tool-nix_v2.33.1.nix -> nix
          major = builtins.head (builtins.match "^tool-.*_v([0-9]+)\.[0-9]+\.[0-9]+\.nix$" dirent.name); # e.g. tool-nix_v2.33.1.nix -> 2
          minor = builtins.head (builtins.match "^tool-.*_v[0-9]+\.([0-9]+)\.[0-9]+\.nix$" dirent.name); # e.g. tool-nix_v2.33.1.nix -> 33
          patch = builtins.head (builtins.match "^tool-.*_v[0-9]+\.[0-9]+\.([0-9]+)\.nix$" dirent.name); # e.g. tool-nix_v2.33.1.nix -> 1
        }
      )
      (import ./match-dirent.nix {
        inherit pkgs;
        from = ./.;
        matchDirentName = name: (builtins.match "^tool-.*_v[0-9]+\.[0-9]+\.[0-9]+\.nix$" name) != null;
        matchDirentType = type: (builtins.match "^regular$" type) != null;
      })
    ));
  getSemverFromTool = toolVersion: "${toolVersion.major}.${toolVersion.minor}.${toolVersion.patch}";
  getToolForSemver = pkgs.writeShellApplication {
    name = "tool";
    runtimeInputs = builtins.concatMap (toolVersions: map (toolVersion: toolVersion.path) toolVersions) (builtins.attrValues tools);
    text = ''
      TOOL_NAME="$1"
      TOOL_VERSION="''${2:-LATEST}"

      if [ -z "$TOOL_NAME" ]; then
              echo "no tool name provided" >&2
              exit 1
      fi

      # handle cases where semver is double-quoted
      if [[ "$TOOL_VERSION" =~ ^\".+\"$ ]]; then
        TOOL_VERSION="''${TOOL_VERSION:1:-1}"
      fi

      # handle cases where semver is single quoted
      if [[ "$TOOL_VERSION" =~ ^\'.+\'$ ]]; then
        TOOL_VERSION="''${TOOL_VERSION:1:-1}"
      fi

      # we don't bother handling cases that are quoted multiple times e.g. "'"'2.1.1'"'" because those cases
      # should be fixed at the source

      if ! [[ "$TOOL_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ || "$TOOL_VERSION" == "LATEST" ]]; then
          echo "expected tool version <MAJOR>.<MINOR>.<PATCH>, received \"$TOOL_VERSION\"" >&2
          exit 1
      fi

      ERR_MSG="tools must be one of ${builtins.concatStringsSep ", " (builtins.attrNames tools)}, received \"$TOOL_NAME\""
      TOOL_PATH=""

      ${
        builtins.concatStringsSep "\n" (
          map (
            toolName: ''
              if [[ "$TOOL_NAME" == ${toolName} ]]; then
                if [[ "$TOOL_VERSION" == "LATEST" ]]; then
                  ERR_MSG=""
                  echo "no tool version specified for \"''${TOOL_NAME}\", using latest version, which is ${getSemverFromTool (pkgs.lib.last tools.${toolName})}"
                  TOOL_PATH="${(pkgs.lib.last tools.${toolName}).path}/bin/${toolName}"
                ${
                builtins.concatStringsSep "\n" (
                  map (
                    toolVersion: ''
                      elif [[ "$TOOL_VERSION" == ${getSemverFromTool toolVersion} ]]; then
                          ERR_MSG=""
                          TOOL_PATH="${toolVersion.path}/bin/${toolName}"
                    ''
                  )
                  tools.${toolName}
                )
              }
                else
                    ERR_MSG="No matching tool version found for ${toolName}. Expected one of ${builtins.concatStringsSep ", " (map (toolVersion: getSemverFromTool toolVersion) tools.${toolName})}, received \"$TOOL_VERSION\""
                fi
              fi
            ''
          )
          (builtins.attrNames tools)
        )
      }

      if [ -n "$ERR_MSG" ]; then
          echo "$ERR_MSG" >&2
          exit 1
      fi

      "$TOOL_PATH" "''${@:3}"
    '';
  };
in
  getToolForSemver
#
# tool <name> <MAJOR.MINOR.PATCH> <args> retrieves the tool at the specified version, and runs it with <args>
#   e.g.  tool nix 2.33.1 build --> retrieve nix 2.33.1 or compatible version --> run nix build
#
# HOW DOES THIS EXPRESSION WORK?
#
# the tool.nix script scans ./ and looks for tool-<name>_v<MAJOR.MINOR.PATCH>.nix files. Each of these files
# loads the version <MAJOR.MINOR.PATCH> of tool with <name>, or errors if no matching version can be found.
#
# the tool command is effectively a tool version manager, like asdf (https://asdf-vm.com/)
#
#      _________                                                             _______
#     / tool.nix                                                            /  _______
#     |         |                                                           | /  _______
#     |         +------------------------------- loads ---------------------> | / parse-manifest-<basename>_<ext>.nix
#     |         |                                                           | | |       |
#     |____^____|                                                             | |       |
#          |                                                                    |_______|
#          |
#        loads   ________
#          |    / tool-nix_v2.33.1.nix
#          |    |        |
#          +-----        +---- finds nix 2.33.1 or compatible version
#          |    |        |
#          |    |________|
#          |
#          |     ________
#          |    / tool-go_v1.26.0.nix
#          |    |        |
#          +-----        +---- finds go 1.26.0 or compatible version
#          |    |        |
#          |    |________|
#          |
#          :
#
# parse-manifest-<basename>_<ext>.nix scripts load the tool.nix script. Then, they alias the devtools they
# provide, i.e.
#    _______
#   / parse-manifest-<basename>_<ext>.nix
#   |       |
#   |       |
#   |___,___|
#       |
#       '--- <name-of-tool> <args>
#               |
#               '--- detects <MAJOR.MINOR.PATCH> of tool, required by manifest
#                      |
#                      '--- calls tool <name-of-tool> <MAJOR.MINOR.PATCH> <args>
#                              |
#                           ___|___
#                          / tool.nix
#                          |       |
#                          |       |
#                          |___,___|
#                              |
#                              '--- retrieves <MAJOR.MINOR.PATCH> of <tool-name>
#                                     |
#                                     '-- runs <tool-name> <args>
#
# it is the responsibility of the parse-manifest-<basename>_<ext>.nix script to alias tool and determine
# the tool version. it is the responsibility of tool.nix to retrieve the tool binary for that version.

