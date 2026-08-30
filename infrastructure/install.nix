{
  writeShellApplication,
  coreutils,
  gnused,
  glow,
  ...
}:
writeShellApplication {
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
  runtimeInputs = [
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
    SSH_PUBLIC_KEY=""
    SSH_PRIVATE_KEY=""
    GIT_USERNAME=""
    GIT_EMAIL=""
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
        elif [ "$SUBCOMMAND" = "home" ] && [ -z "$FLAG" ] && [ "$1" = "--ssh_public_key" ]; then
            FLAG="--ssh_public_key"
            shift
        elif [ "$SUBCOMMAND" = "home" ] && [ -z "$FLAG" ] && [[ "$1" = --ssh_public_key=* ]]; then
            SSH_PUBLIC_KEY="''${1#--ssh_public_key=}"
            shift
        elif [ "$SUBCOMMAND" = "home" ] && [ "$FLAG" = "--ssh_public_key" ]; then
            FLAG=""
            SSH_PUBLIC_KEY="$1"
            shift
        elif [ "$SUBCOMMAND" = "home" ] && [ -z "$FLAG" ] && [ "$1" = "--ssh_private_key" ]; then
            FLAG="--ssh_private_key"
            shift
        elif [ "$SUBCOMMAND" = "home" ] && [ -z "$FLAG" ] && [[ "$1" = --ssh_private_key=* ]]; then
            SSH_PRIVATE_KEY="''${1#--ssh_private_key=}"
            shift
        elif [ "$SUBCOMMAND" = "home" ] && [ "$FLAG" = "--ssh_private_key" ]; then
            FLAG=""
            SSH_PRIVATE_KEY="$1"
            shift
        elif [ "$SUBCOMMAND" = "home" ] && [ -z "$FLAG" ] && [ "$1" = "--git_username" ]; then
            FLAG="--git_username"
            shift
        elif [ "$SUBCOMMAND" = "home" ] && [ -z "$FLAG" ] && [[ "$1" = --git_username=* ]]; then
            GIT_USERNAME="''${1#--git_username=}"
            shift
        elif [ "$SUBCOMMAND" = "home" ] && [ "$FLAG" = "--git_username" ]; then
            FLAG=""
            GIT_USERNAME="$1"
            shift
        elif [ "$SUBCOMMAND" = "home" ] && [ -z "$FLAG" ] && [ "$1" = "--git_email" ]; then
            FLAG="--git_email"
            shift
        elif [ "$SUBCOMMAND" = "home" ] && [ -z "$FLAG" ] && [[ "$1" = --git_email=* ]]; then
            GIT_EMAIL="''${1#--git_email=}"
            shift
        elif [ "$SUBCOMMAND" = "home" ] && [ "$FLAG" = "--git_email" ]; then
            FLAG=""
            GIT_EMAIL="$1"
            shift
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

    SYSTEM_HOSTNAME_RE='^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*\.?$'
    SSH_PUBLIC_KEY_RE='^(?:~(?:/(?:[^/]+(?:/[^/]+)*)?)|/(?:[^/]+(?:/[^/]+)*)?|(?:[^/]+(?:/[^/]+)*))/?$'
    SSH_PRIVATE_KEY_RE='^(?:~(?:/(?:[^/]+(?:/[^/]+)*)?)|/(?:[^/]+(?:/[^/]+)*)?|(?:[^/]+(?:/[^/]+)*))/?$'
    GIT_USERNAME_RE='^[a-z0-9](?:[a-z0-9-]{0,37}[a-z0-9])?$'
    GIT_EMAIL_RE='^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

    if [ "$SUBCOMMAND" = "system" ] && [ -t 0 ] && (( HELPMSG == 0 )); then

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

    elif [ "$SUBCOMMAND" = "home" ] && [ -t 0 ] && (( HELPMSG == 0 )); then

        while ! [[ "$SSH_PUBLIC_KEY" =~ $SSH_PUBLIC_KEY_RE ]]; do
            echo "\"$SSH_PUBLIC_KEY\" is not a valid absolute or relative path to an ssh public key: Enter path:" >&2
            IFS= read -r SSH_PUBLIC_KEY
        done

        while ! [[ "$SSH_PRIVATE_KEY" =~ $SSH_PRIVATE_KEY_RE ]]; do
            echo "\"$SSH_PRIVATE_KEY\" is not a valid absolute or relative path to an ssh private key: Enter path:" >&2
            IFS= read -r SSH_PRIVATE_KEY
        done

        while ! [[ "$GIT_USERNAME" =~ $GIT_USERNAME_RE ]]; do
            echo "\"$GIT_USERNAME\" is not a valid git username (max 39 characters): Enter username:" >&2
            IFS= read -r GIT_USERNAME
        done

        while ! [[ "$GIT_EMAIL" =~ $GIT_EMAIL_RE ]]; do
            echo "\"$GIT_EMAIL\" is not a valid email: Enter email:" >&2
            IFS= read -r GIT_EMAIL
        done

    elif [ "$SUBCOMMAND" = "home" ] && (( HELPMSG == 0 )); then

        if ! [[ "$SSH_PUBLIC_KEY" =~ $SSH_PUBLIC_KEY_RE ]]; then
            echo "\"$SSH_PUBLIC_KEY\"" is not a valid absolute or relative path to an ssh public key >&2
            HELPMSG=2
            EXIT_CODE=1
        fi

        if ! [[ "$SSH_PRIVATE_KEY" =~ $SSH_PRIVATE_KEY_RE ]]; then
            echo "\"$SSH_PRIVATE_KEY\"" is not a valid absolute or relative path to an ssh private key >&2
            HELPMSG=2
            EXIT_CODE=1
        fi

        if ! [[ "$GIT_USERNAME" =~ $GIT_USERNAME_RE ]]; then
            echo "\"$GIT_USERNAME\"" is not a valid github username >&2
            HELPMSG=2
            EXIT_CODE=1
        fi

        if ! [[ "$GIT_EMAIL" =~ $GIT_EMAIL_RE ]]; then
            echo "\"$GIT_EMAIL\"" is not a valid email address >&2
            HELPMSG=2
            EXIT_CODE=1
        fi

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

    | arg | value | example |
    |:----|:------|:--------|
    |`<ssh_private_key>` | Path to private key | "~/.ssh/id_ed25519" |
    |`<ssh_public_key>` | Path to public key | "~/.ssh/id_ed25519.pub" |
    |`<git_username>` | username for signing git commits | "firstname_lastname" |
    |`<git_email>` | email for signing git commits | "firstname_lastname@email.com" |

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

        MACOS_SYSTEM_ARCH="aarch64-darwin"

        if ! [ "$(uname -m)" = "arm64" ]; then
            MACOS_SYSTEM_ARCH="x86_64-darwin"
        fi

        function backup_flake(){
            if [ -f "./flake.nix" ] && ! mv "./flake.nix" "./flake.nix.old"; then
                echo "could not back up ''${PWD}/flake.nix to ''${PWD}/flake.nix.old" >&2
                return 1
            fi
        }

        function backup_flake_lock(){
            if [ -f "./flake.lock" ] && ! mv "./flake.lock" "./flake.lock.old"; then
                echo "could not back up ''${PWD}/flake.lock to ''${PWD}/flake.lock.old" >&2
                return 1
            fi
        }

        function restore_flake_lock(){
            if ! mv "''${PWD}/flake.lock.old" "''${PWD}/flake.lock"; then
                echo "could not restore ''${PWD}/flake.nix.old to ''${PWD}/flake.nix" >&2
                return 1
            fi
        }

        function restore_flake(){
            if ! mv "''${PWD}/flake.nix.old" "''${PWD}/flake.nix"; then
                echo "could not restore ''${PWD}/flake.nix.old to ''${PWD}/flake.nix" >&2
                return 1
            fi
        }

        if [ "$SUBCOMMAND" = "system" ] && [ "$(uname)" = "Darwin" ]; then

            if ! backup_flake; then
                exit 1
            fi

            if ! backup_flake_lock; then
                restore_flake
                exit 1
            fi

            function init_darwin_system_flake(){
                nix --extra-experimental-features "nix-command flakes" flake init -t "github:incremental-design/projects?dir=infrastructure#macos" || return 1;
                sed -i "s|system = \"aarch64-darwin\";|system = \"''${MACOS_SYSTEM_ARCH}\";|g" "''${PWD}/flake.nix" || return 1;
                sed -i "s|# networking.hostName|networking.hostName = \"''${SYSTEM_HOSTNAME}\";|g" "''${PWD}/flake.nix" || return 1;
            }

            if ! init_darwin_system_flake; then
                echo "could not init \"https://github.com/incremental-design/projects/blob/main/infrastructure/macos/system/template/flake.nix\" into ''${PWD}/flake.nix" >&2

                restore_flake && restore_flake_lock

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

                restore_flake && restore_flake_lock

                exit 1
            fi

        elif [ "$SUBCOMMAND" = "system" ]; then
            echo "NixOS system install not implemented" >&2
            exit 1
        elif [ "$SUBCOMMAND" = "uninstall-system" ] && [ "$(uname)" = "Darwin" ]; then

            if ! nix run nix-darwin/nix-darwin-26.05#darwin-uninstaller; then
                echo "faild to \`nix run nix-darwin/nix-darwin-26.05#darwin-uninstaller\`" >&2
            fi
        elif [ "$SUBCOMMAND" = "uninstall-system" ]; then
            echo "NixOS system uninstall not implemented" >&2
            exit 1
        elif [ "$SUBCOMMAND" = "home" ] && [ "$(uname)" = "Darwin" ]; then

            if ! backup_flake; then
                exit 1
            fi

            if ! backup_flake_lock; then
                restore_flake
                exit 1
            fi

            function init_darwin_home_flake(){
                local user
                user="$(whoami)"
                nix --extra-experimental-features "nix-command flakes" flake init -t "github:incremental-design/projects?dir=infrastructure#macos_home" || return 1
                sed -i "s|username = \"default\";|username = \"''${user}\";|g" "''${PWD}/flake.nix" || return 1
                sed -i "s|homeDirectory = \"/Users/Default\";|homeDirectory = \"''${HOME}\";|g" "''${PWD}/flake.nix" || return 1
                sed -i "s|ssh_public_key = \"\";|ssh_public_key = \"''${SSH_PUBLIC_KEY}\";|g" "''${PWD}/flake.nix" || return 1
                sed -i "s|ssh_private_key = \"\";|ssh_private_key = \"''${SSH_PRIVATE_KEY}\";|g" "''${PWD}/flake.nix" || return 1
                sed -i "s|git_username = \"\";|git_username = \"''${GIT_USERNAME}\";|g" "''${PWD}/flake.nix" || return 1
                sed -i "s|git_email = \"\";|git_email = \"''${GIT_EMAIL}\";|g" "''${PWD}/flake.nix" || return 1
            }

            if ! init_darwin_home_flake; then
              echo "could not init \"https://github.com/incremental-design/projects/blob/main/infrastructure/macos/home/template/flake.nix\" into ''${PWD}/flake.nix" >&2
              restore_flake && restore_flake_lock
              exit 1
            fi

            if ! nix run --extra-experimental-features "nix-command flakes" home-manager/release-26.05 -- --flake . switch -b backup; then
                echo "could not \"nix run home-manager/release-26.05 -- --flake . switch -b backup\"" >&2
                restore_flake && restore_flake_lock
                exit 1
            fi

        elif [ "$SUBCOMMAND" = "home" ]; then
            echo "NixOS home manager not implemented" >&2
            exit 1
        elif [ "$SUBCOMMAND" = "uninstall-home" ] && [ "$(uname)" = "Darwin" ]; then
            echo "not implemented" >&2
            exit 1
        elif [ "$SUBCOMMAND" = "uninstall-home" ]; then
            echo "nixOS uninstall home not implemented" >&2
        fi
    )

  '';
}
