{pkgs, ...}:
pkgs.writeShellApplication {
  name = "install";
  meta = {
    description = ''
      setup a MacOS or NixOS system


      on MacOS:
         ___________
        /           |
       /   incremental-design/projects?dir=infrastructure#install -- system
       |            |
       |            |                 /
       |            |                  |- Applications/ <---------------------------------,
       |            |                  |                                                  |
       |_____,______|                  |- Library/      <---------------------------------|
             |                         |                                                  |
             |                         |- System/                                         |
             |                         |                                                  |
             |                         |- Users/                                          |
             |                         |                                                  |
             |                         |- Volumes/                                        |
             |                         |                                                  |
             |                         |- bin/                                            |
             |                         |                                                  |
             |                         |- cores/                                          |
             |                         |                                                  |
             |                         |- dev/                                            |
             |                         |                                                  |
             |                         |- etc/          <---------------------------------|
             |                         |                                                  |
             |                         |- home/                                           |
             |                         |                                                  |
             |                         |- nix/                                            |
             |                         |                                                  |
             |                         |- opt/                                            |
             |                         |                                                  |
             |                         |- private/                                        |
             |                         |                                                  |
             |                         |- sbin/                                           |
             |                         |                                                  |
             |                         |- tmp/                                            |
             |                         |                                                  |
             |                         |- usr/                                            |
             |                         |                                                  |
             |                         |- run/         <----------------------------------|
             |                         |                                                  |
             |                         |- var/                                            |
             |                               |                                            |
             |                               :                                            |
             |                               :                                            |
             |                               |- personalized_factory/                     |
             |                               |                                            |
             |                               |- protected/                                |
             |                               |                                            |
             |                               |- root/                                     |
             |                                   |                                        |
             |                                   |                                        |
             '------------(1)--------------->    '- flake.nix -----------------(2)--------'


      1. initializes a flake.nix with overrides from CLI input into /var/root
      2. runs darwin-rebuild switch to build and apply patches to MacOS system folders
      on MacOS:
         ___________
        /           |
       /   incremental-design/projects?dir=infrastructure#install -- user
       |            |
       |            |                 /
       |            |                  |- Applications/
       |            |                  |
       |_____,______|                  |- Library/
             |                         |
             |                         |- System/
             |                         |
             |                         |- Users/
             |                         |    |
             |                         |    |- <username>/
             |                         |    :    |
             |                         |         |
             '------------(1)--------------->    '- flake.nix
                                       :
                                       :



      1. initializes a flake.nix with overrides from CLI input into /Users/<username>
      2. runs home-manager/release-26.05 -- init --switch to build and apply home directory configuration

      on NixOS

      nothing yet - not implemented
    '';
  };
  runtimeInputs = with pkgs; [
    coreutils
    gnused
    glow
  ];

  text = ''
    set -e

    SUBCOMMAND=
    HELPMSG=0
    EXIT_CODE=0
    SYSTEM_HOSTNAME=""
    FLAG=""

    if (( $# == 0 )); then
        HELPMSG=3
    fi

    while (( $# > 0 )); do
        if [ -z "$SUBCOMMAND" ] && [ "''${1,,}" = "system" ] || [ "''${1,,}" = "home" ] || [ "''${1,,}" = "uninstall-system" ] || [ "''${1,,}" = "uninstall-home" ]; then
            SUBCOMMAND="$1"
            shift
        elif [ -z "$SUBCOMMAND" ] && [ "''${1,,}" = "help" ]; then
            HELPMSG=3
            break;
        elif [ "$SUBCOMMAND" = "system" ] && [ -z "$FLAG" ] && [ "$1" = "help" ]; then
            HELPMSG=1
            break
        elif [ "$SUBCOMMAND" = "system" ] && [ -z "$FLAG" ] && [ "$1" = "--hostname" ]; then
            FLAG="--hostname"
            shift
        elif [ "$SUBCOMMAND" = "system" ] && [ -z "$FLAG" ] && [[ "$1" = --hostname=* ]]; then
            SYSTEM_HOSTNAME="''${1#--hostname=}"
            shift
        elif [ "$SUBCOMMAND" = "system" ] && [ "$FLAG" = "--hostname" ]; then
            FLAG=""
            SYSTEM_HOSTNAME="$1"
            shift
        elif [ "$SUBCOMMAND" = "home" ] && [ -z "$FLAG" ] && [ "$1" = "help" ]; then
            HELPMSG=2
            break
        elif [ "$SUBCOMMAND" = "uninstall-system" ] && [ -z $FLAG ] && [ "$1" = "help" ]; then
            HELPMSG=4
            break
        elif [ "$SUBCOMMAND" = "uninstall-home" ] && [ -z $FLAG ] && [ "$1" = "help" ]; then
            HELPMSG=5
            break
        else
            echo "unrecognized argument ''${1}" >&2
            HELPMSG=3
            EXIT_CODE=1
            break
        fi
    done

    if [ "$SUBCOMMAND" = "system" ] && [ -t 0 ] && (( HELPMSG == 0 )); then

    SYSTEM_HOSTNAME_RE='^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*\.?$'

        while ! [[ "$SYSTEM_HOSTNAME" =~ $SYSTEM_HOSTNAME_RE ]] ||
        [ "''${#SYSTEM_HOSTNAME}" -gt 255 ]; do
            echo "\"$SYSTEM_HOSTNAME\" is not a valid RFC 1123 hostname: Enter hostname:" >&2
            IFS= read -r SYSTEM_HOSTNAME
        done

    elif [ "$SUBCOMMAND" = "system" ] && (( HELPMSG == 0 )); then

        if ! [[ "$SYSTEM_HOSTNAME" =~ $SYSTEM_HOSTNAME_RE ]] ||
            [ "''${#SYSTEM_HOSTNAME}" -gt 255 ]; then
            echo "\"$SYSTEM_HOSTNAME\" is not a valid RFC 1123 hostname" >&2
            HELPMSG=1
            EXIT_CODE=1
        fi

    # elif [ "$SUBCOMMAND" = "user" ] && [ -t 0 ] && (( HELPMSG == 0 )); then
    # elif [ "$SUBCOMMAND" = "user" ] && (( HELPMSG == 0 )); then
    fi

    if (( HELPMSG == 1 )) || (( HELPMSG == 3 )); then
    glow >&2 <<'EOF'
    # INSTALL NixOS or nix-darwin on MacOS

    ```
    sudo -H nix run \
    "github:incremental-design/projects?dir=infrastructure#install" \
    --extra-experimental-features \
    "nix-command flakes" \
    -- system \
    --hostname <hostname>
    ```

    | arg | value | example |
    |:----|:------|:--------|
    |`<hostname>` | hostname of the system | "my-computer" |

    EOF
    fi

    if (( HELPMSG == 2)) || (( HELPMSG == 3 )); then
    glow >&2 <<'EOF'
    # INSTALL Home Manager for currently logged in user

    ```
    nix run \
    "github:incremental-design/projects?dir=infrastructure#install" \
    --extra-experimental-features \
    "nix-command flakes" \
    -- home
    ```

    EOF
    fi

    if (( HELPMSG == 4 )) || (( HELPMSG == 3 )); then
    glow >&2 <<'EOF'
    # UNINSTALL NixOS or nix-darwin on MacOS

    ```
    sudo -H nix run \
    "github:incremental-design/projects?dir=infrastructure#install" \
    --extra-experimental-features \
    "nix-command flakes" \
    -- uninstall-system
    ```

    EOF
    fi

    if (( HELPMSG == 5)) || (( HELPMSG == 3 )); then
    glow >&2 <<'EOF'
    # UNINSTALL Home Manager for currently logged in user

    ```
    nix run \
    "github:incremental-design/projects?dir=infrastructure#install" \
    --extra-experimental-features \
    "nix-command flakes" \
    -- uninstall-home
    ```

    EOF
    fi

    if [ "$SUBCOMMAND" = "system" ] && [ "$EUID" -ne 0 ]; then
        echo "run install system with sudo -H" >&2
        EXIT_CODE=1
        exit "$EXIT_CODE"
    fi

    if [ "$SUBCOMMAND" = "uninstall-system" ] && [ "$EUID" -ne 0 ]; then
        echo "run uninstall-system with sudo -H" >&2
        EXIT_CODE=1
        exit "$EXIT_CODE"
    fi

    if (( EXIT_CODE != 0 )) || (( HELPMSG != 0 )); then
        exit "$EXIT_CODE"
    fi

    (
        cd "$HOME"

        if [ "$SUBCOMMAND" = "system" ]; then

            if [ -f "./flake.nix" ] && ! mv "./flake.nix" "./flake.nix.old"; then
                echo "could not back up ''${PWD}/flake.nix to ''${PWD}/flake.nix.old" >&2
                exit 1
            fi

            MACOS_SYSTEM_ARCH="aarch64-darwin"

            if ! [ "$(uname -m)" = "arm64" ]; then
                MACOS_SYSTEM_ARCH="x86_64-darwin"
            fi

            if ! nix flake init -t "github:incremental-design/projects?dir=infrastructure#macos" && \
                sed -i "s|macos_system_arch = \"aarch64-darwin\";|''${MACOS_SYSTEM_ARCH}|g" "/var/root/flake.nix" && \
                sed -i "s|# networking.hostName|networking.hostName = \"''${SYSTEM_HOSTNAME}\";|g" "/var/root/flake.nix";
            then
                echo "could not init \"https://github.com/incremental-design/projects/blob/main/infrastructure/macos/system/template/flake.nix\" into ''${PWD}/flake.nix" >&2

                if ! mv "''${PWD}/flake.nix.old" "''${PWD}/flake.nix"; then
                echo "could not restore ''${PWD}/flake.nix.old to ''${PWD}/flake.nix" >&2
                fi

                exit 1
            fi

            if ! nix run \
                --extra-experimental-features "nix-command flakes" \
                nix-darwin/nix-darwin-26.05#darwin-rebuild \
                -- \
                switch \
                --flake .#default \
                --show-trace
            then
                echo "failed to \`nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch\`" >&2

                if ! mv "''${PWD}/flake.nix.old" "''${PWD}/flake.nix"; then
                echo "could not restore ''${PWD}/flake.nix.old to ''${PWD}/flake.nix" >&2
                fi

                exit 1
            fi

        elif [ "$SUBCOMMAND" = "uninstall-system" ]; then

            if ! nix run nix-darwin/nix-darwin-26.05#darwin-uninstaller; then
                echo "faild to \`nix run nix-darwin/nix-darwin-26.05#darwin-uninstaller\`" >&2
            fi

        elif [ "$SUBCOMMAND" = "home" ]; then
            echo "not implemented" >&2
            exit 1
        elif [ "$SUBCOMMAND" = "uninstall-home" ]; then
            echo "not implemented" >&2
            exit 1
        fi
    )

  '';
}
